import { AgentDescriptor, LayerName } from "../types";

export function enforceLayerPlacement(agent: AgentDescriptor) {
  const expectedFragment = `runtime/${agent.layer}/`;
  const normalizedPath = agent.path.replace(/\\/g, "/");
  if (!normalizedPath.includes(expectedFragment)) {
    throw new Error(`Agent ${agent.name} must reside under ${expectedFragment} but path is ${agent.path}`);
  }
}

export function validateLayerName(layer: string): layer is LayerName {
  return ["bootstrap", "executor", "mesh", "evolution", "marketplace", "revenue", "governance", "project-generator"].includes(
    layer,
  );
}
