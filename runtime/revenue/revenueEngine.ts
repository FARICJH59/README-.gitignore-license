import { AgentDescriptor } from "../types";

export class RevenueEngine {
  private revenueAgents: AgentDescriptor[] = [];

  register(agent: AgentDescriptor) {
    if (agent.layer !== "revenue") {
      throw new Error(`RevenueEngine only registers revenue agents, received ${agent.layer}`);
    }
    this.revenueAgents.push(agent);
    return agent;
  }

  list() {
    return [...this.revenueAgents];
  }
}

export const revenueEngine = new RevenueEngine();
