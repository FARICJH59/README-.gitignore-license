import { AgentDescriptor, BOOTSTRAP_LAYER_WHITELIST, LayerName } from "../types";

export class AgentBootstrap {
  private registry: Map<LayerName, AgentDescriptor[]> = new Map();

  constructor(private readonly allowed: LayerName[] = BOOTSTRAP_LAYER_WHITELIST) {}

  registerAgent(agent: AgentDescriptor) {
    if (!this.allowed.includes(agent.layer)) {
      throw new Error(`Layer ${agent.layer} is not permitted in AgentBootstrap`);
    }
    const current = this.registry.get(agent.layer) ?? [];
    this.registry.set(agent.layer, [...current, agent]);
    return agent;
  }

  list(layer?: LayerName) {
    if (layer) return this.registry.get(layer) ?? [];
    return Array.from(this.registry.values()).flat();
  }
}

export const agentBootstrap = new AgentBootstrap();
