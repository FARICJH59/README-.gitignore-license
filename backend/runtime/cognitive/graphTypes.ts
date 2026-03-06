export type NodeAttributes = Record<string, unknown>;

export interface Node {
  id: string;
  type: string;
  attributes?: NodeAttributes;
}

export interface Edge {
  from: string;
  to: string;
  relation: string;
  metadata?: Record<string, unknown>;
}

export type GraphQuery = {
  nodeId?: string;
  nodeType?: string;
  relation?: string;
  attributes?: Partial<NodeAttributes>;
  neighborOf?: string;
  direction?: "incoming" | "outgoing" | "any";
};

export interface AgentMemoryEntry {
  timestamp?: number;
  data: unknown;
  tags?: string[];
  relatedNodeIds?: string[];
  summary?: string;
}
