import { Agent } from "../../shims/agents";
import { agentBootstrap } from "../../bootstrap/agentBootstrap";
import { AuditLogger } from "../../governance/auditLogger";
import { MetricsRecorder } from "../../telemetry/metricsRecorder";
import { AgentDescriptor, Capability, Permission } from "../../types";
import { AgentSelfHeal } from "./agentSelfHeal";

type AgentInstance = Agent & { capabilities?: Capability[]; permissions?: Permission[] };

const isDebugEnabled = () =>
  (typeof process !== "undefined" && process.env?.DEBUG_BOOTSTRAP === "true") ||
  (globalThis as { DEBUG_BOOTSTRAP?: boolean }).DEBUG_BOOTSTRAP === true;

export class AgentExecutor {
  private audit: AuditLogger;
  private metrics: MetricsRecorder;
  private selfHeal?: AgentSelfHeal;
  private debug: boolean;
  private agentCache = new Map<string, AgentInstance>();

  constructor(options?: {
    auditLogger?: AuditLogger;
    metricsRecorder?: MetricsRecorder;
    selfHeal?: AgentSelfHeal;
    debug?: boolean;
  }) {
    this.audit = options?.auditLogger ?? new AuditLogger();
    this.metrics = options?.metricsRecorder ?? new MetricsRecorder();
    this.selfHeal = options?.selfHeal;
    this.debug = options?.debug ?? isDebugEnabled();
  }

  private logDebug(message: string, extra?: Record<string, unknown>) {
    if (this.debug) console.debug(`[AgentExecutor] ${message}`, extra ?? {});
  }

  private pickPermission(agent: AgentInstance): Permission {
    return (agent.permissions?.[0] ?? "read") as Permission;
  }

  private ensurePermission(agent: AgentInstance, permission: Permission) {
    const granted = agent.permissions ?? [];
    if (granted.length && !granted.includes(permission)) {
      throw new Error(`Permission ${permission} not granted for agent`);
    }
  }

  private resolveDescriptor(agentName: string): AgentDescriptor {
    const descriptor = agentBootstrap.list().find((entry) => entry.name === agentName);
    if (!descriptor) {
      throw new Error(`Agent ${agentName} is not registered in AgentBootstrap`);
    }
    return descriptor;
  }

  private toModulePath(descriptor: AgentDescriptor) {
    const normalized = descriptor.path.replace(/^runtime\//, "");
    return `../../${normalized.replace(/\.ts$/, "")}`;
  }

  private async instantiateAgent(descriptor: AgentDescriptor): Promise<AgentInstance> {
    const modulePath = this.toModulePath(descriptor);
    let mod: Record<string, unknown>;
    try {
      mod = await import(modulePath);
    } catch (error) {
      mod = await import(`${modulePath}.ts`);
    }
    const AgentCtor = mod[descriptor.name] as new () => AgentInstance;
    if (!AgentCtor) {
      throw new Error(`Agent class ${descriptor.name} not found at ${descriptor.path}`);
    }
    const instance = new AgentCtor();
    this.agentCache.set(descriptor.name, instance);
    return instance;
  }

  private async getAgent(agentName: string): Promise<{ instance: AgentInstance; descriptor: AgentDescriptor }> {
    const descriptor = this.resolveDescriptor(agentName);
    const cached = this.agentCache.get(agentName);
    if (cached) return { instance: cached, descriptor };
    const instance = await this.instantiateAgent(descriptor);
    return { instance, descriptor };
  }

  private resolveMethod(agent: AgentInstance): string {
    const capabilities = agent.capabilities ?? [];
    const preferred = capabilities.find((cap) => typeof (agent as Record<string, unknown>)[cap as string] === "function");
    if (preferred) return preferred;
    if (typeof (agent as Record<string, unknown>).execute === "function") return "execute";
    if (typeof (agent as Record<string, unknown>).run === "function") return "run";
    throw new Error("No executable method found on agent");
  }

  async run(agentName: string, input: unknown) {
    const { instance, descriptor } = await this.getAgent(agentName);
    const permission = this.pickPermission(instance);
    this.ensurePermission(instance, permission);
    const methodName = this.resolveMethod(instance);

    try {
      const result = await (instance as Record<string, any>)[methodName](input);
      this.metrics.recordExecution(1);
      this.audit.record(agentName, methodName, permission, { layer: descriptor.layer });
      this.logDebug(`Executed ${agentName}.${methodName}`);
      return result;
    } catch (error) {
      this.metrics.recordError(1);
      this.audit.record(agentName, `${methodName}:error`, permission, {
        layer: descriptor.layer,
        error: (error as Error).message,
      });
      if (this.selfHeal) {
        await this.selfHeal.handleFailure(agentName, () => this.restartAgent(agentName), error as Error);
      }
      throw error;
    }
  }

  async stream(agentName: string, input: unknown) {
    const result = await this.run(agentName, input);
    if (result && typeof (result as AsyncIterable<unknown>)[Symbol.asyncIterator] === "function") {
      return result as AsyncIterable<unknown>;
    }
    const self = this;
    async function* generator() {
      self.logDebug(`Streaming single result for ${agentName}`);
      yield result;
    }
    return generator();
  }

  async executePipeline(agentList: string[], input: unknown) {
    let current = input;
    for (const name of agentList) {
      const prepared = this.transformInputForAgent(name, current);
      current = await this.run(name, prepared);
    }
    this.audit.record("AgentPipeline", "execute", "read", { steps: agentList.length });
    this.logDebug(`Pipeline executed`, { steps: agentList });
    return current;
  }

  private transformInputForAgent(agentName: string, value: unknown) {
    const descriptor = this.resolveDescriptor(agentName);
    if (descriptor.name === "FraudDetectionAgent") {
      const maybeParsed = value as { parsed?: { key: string; value: unknown }[] };
      if (maybeParsed?.parsed && Array.isArray(maybeParsed.parsed)) {
        const reconstructed = Object.fromEntries(maybeParsed.parsed.map(({ key, value: v }) => [key, v]));
        return Array.isArray(reconstructed) ? reconstructed : [reconstructed];
      }
    }
    return value;
  }

  async restartAgent(agentName: string) {
    this.agentCache.delete(agentName);
    const descriptor = this.resolveDescriptor(agentName);
    const instance = await this.instantiateAgent(descriptor);
    this.audit.record(agentName, "restart", this.pickPermission(instance), { layer: descriptor.layer });
    this.logDebug(`Restarted agent ${agentName}`);
    return instance;
  }

  getMetrics() {
    return this.metrics.getSnapshot();
  }
}
