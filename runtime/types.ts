export type LayerName = "bootstrap" | "executor" | "mesh" | "evolution" | "marketplace" | "revenue" | "governance";

export type Capability = "analyzeTransactions" | "flagSuspicious" | "parseData";

export type Permission = "read" | "write" | "alert";
export const ALL_LAYERS: LayerName[] = ["bootstrap", "executor", "mesh", "evolution", "marketplace", "revenue", "governance"];
export const BOOTSTRAP_LAYER_WHITELIST: LayerName[] = ["bootstrap", "executor", "mesh", "evolution"];

export interface AgentDescriptor {
  name: string;
  layer: LayerName;
  capabilities: Capability[];
  permissions: Permission[];
  path: string;
  tags?: string[];
}

export interface MetricSnapshot {
  analyzed: number;
  flagged: number;
  alerts: number;
  lastUpdated: number;
}
