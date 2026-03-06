import "../project-generator/intentAgent";
import "../project-generator/architectAgent";
import "../project-generator/stackAgent";
import "../project-generator/backendBuilderAgent";
import "../project-generator/frontendBuilderAgent";
import "../project-generator/mlBuilderAgent";
import "../project-generator/devOpsBuilderAgent";

import { AgentExecutor } from "../executor/engine/agentExecutor";
import { AgentRetryManager } from "../executor/engine/agentRetryManager";
import { AgentScheduler } from "../executor/engine/agentScheduler";
import { AgentSelfHeal } from "../executor/engine/agentSelfHeal";
import { AuditLogger } from "../governance/auditLogger";
import { MetricsRecorder } from "../telemetry/metricsRecorder";
import { loadTemplate } from "../project-generator/templateLoader";
import { ArchitecturePlan, BuilderOutput, ProjectIntent, StackSelection } from "../project-generator/types";

export type ProjectPipelineResult = {
  intent: ProjectIntent;
  architecture: ArchitecturePlan;
  stack: StackSelection;
  backend: BuilderOutput;
  frontend: BuilderOutput;
  ml: BuilderOutput;
  devops: BuilderOutput;
  templateName: string;
  buildTimeMs: number;
};

const POST_BUILD_HEARTBEAT_MS = 10; // lightweight post-build health ping

export class ProjectPipeline {
  private audit: AuditLogger;
  private metrics: MetricsRecorder;
  private retry: AgentRetryManager;
  private scheduler: AgentScheduler;

  constructor(private executor?: AgentExecutor, options?: { auditLogger?: AuditLogger; metricsRecorder?: MetricsRecorder }) {
    const audit = options?.auditLogger ?? new AuditLogger();
    const metrics = options?.metricsRecorder ?? new MetricsRecorder();
    const selfHeal = new AgentSelfHeal({ auditLogger: audit, metricsRecorder: metrics });
    this.executor = executor ?? new AgentExecutor({ auditLogger: audit, metricsRecorder: metrics, selfHeal });
    this.audit = audit;
    this.metrics = metrics;
    this.retry = new AgentRetryManager(this.executor, { auditLogger: audit, metricsRecorder: metrics });
    this.scheduler = new AgentScheduler(this.executor, { auditLogger: audit });
  }

  async run(templateName: string, request: string): Promise<ProjectPipelineResult> {
    const start = Date.now();
    const template = loadTemplate(templateName);

    const intent = (await this.executor!.run("IntentAgent", request)) as ProjectIntent;
    intent.template = template;

    const architecture = (await this.executor!.run("ArchitectAgent", intent)) as ArchitecturePlan;

    const stack = (await this.executor!.run("StackAgent", {
      intent,
      architecture,
      template,
    })) as StackSelection;

    const backend = (await this.retry.retry("BackendBuilderAgent", stack, 1)) as BuilderOutput;
    const frontend = (await this.executor!.run("FrontendBuilderAgent", stack)) as BuilderOutput;
    const ml = (await this.executor!.run("MLBuilderAgent", stack)) as BuilderOutput;
    const devops = (await this.executor!.run("DevOpsBuilderAgent", stack)) as BuilderOutput;

    const buildTimeMs = Date.now() - start;
    this.metrics.recordExecution(1);
    this.audit.record("ProjectPipeline", "build", "write", {
      template: template.name,
      buildTimeMs,
      services: architecture.services.length,
    });

    // Schedule a post-build heartbeat
    this.scheduler.schedule("FrontendBuilderAgent", stack, POST_BUILD_HEARTBEAT_MS);

    return { intent, architecture, stack, backend, frontend, ml, devops, templateName: template.name, buildTimeMs };
  }
}
