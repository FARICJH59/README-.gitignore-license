import { agentBootstrap } from "../bootstrap/agentBootstrap";
import { enforceLayerPlacement } from "../governance/layerValidator";
import { AgentDescriptor } from "../types";

const executorAgents: AgentDescriptor[] = [];

export function registerExecutorAgent(agent: AgentDescriptor) {
  enforceLayerPlacement(agent);
  executorAgents.push(agent);
  agentBootstrap.registerAgent(agent);
  return agent;
}

export function listExecutorAgents() {
  return [...executorAgents];
}
