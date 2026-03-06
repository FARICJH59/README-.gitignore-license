export type Node = {
  id: string;
  type: string;
  attributes?: Record<string, unknown>;
};

export type Edge = {
  from: string;
  to: string;
  relation: string;
  attributes?: Record<string, unknown>;
};

export type GraphQuery = {
  nodeType?: string;
  relation?: string;
  from?: string;
  to?: string;
  attributes?: Partial<Record<string, unknown>>;
  predicate?: (node: Node) => boolean;
};

export type AgentMemoryEntry = {
  id: string;
  agentId: string;
  nodeId?: string;
  data: unknown;
  tags?: string[];
  timestamp: number;
  metadata?: Record<string, unknown>;
};

export type GraphQueryResult = {
  nodes: Node[];
  edges: Edge[];
};
