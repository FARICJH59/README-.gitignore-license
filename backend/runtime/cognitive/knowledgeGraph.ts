import { AuditLogger } from "../../../runtime/governance/auditLogger";
import { MetricsRecorder } from "../../../runtime/telemetry/metricsRecorder";
import { Permission } from "../../../runtime/types";
import { Edge, GraphQuery, Node } from "./graphTypes";

type QueryResult = {
  nodes: Node[];
  edges: Edge[];
  neighbors: Node[];
};

const GRAPH_AGENT = "CognitiveGraph";

export class KnowledgeGraph {
  private nodes = new Map<string, Node>();
  private edges: Edge[] = [];
  private audit: AuditLogger;
  private metrics: MetricsRecorder;

  constructor(options?: { auditLogger?: AuditLogger; metricsRecorder?: MetricsRecorder }) {
    this.audit = options?.auditLogger ?? new AuditLogger();
    this.metrics = options?.metricsRecorder ?? new MetricsRecorder();
  }

  private recordAudit(action: string, permission: Permission, details?: Record<string, unknown>) {
    this.audit.record(GRAPH_AGENT, action, permission, details);
  }

  addNode(node: Node) {
    if (!node.id || !node.type) {
      this.metrics.recordError(1);
      this.recordAudit("addNode:error", "write", { reason: "missing-required-fields", node });
      throw new Error("Node must include an id and type");
    }
    const existing = this.nodes.get(node.id);
    const merged: Node = existing
      ? { ...existing, attributes: { ...(existing.attributes ?? {}), ...(node.attributes ?? {}) } }
      : { ...node, attributes: { ...(node.attributes ?? {}) } };
    this.nodes.set(node.id, merged);
    this.metrics.recordExecution(1);
    this.recordAudit("addNode", "write", { nodeId: node.id, type: node.type });
    return merged;
  }

  addEdge(edge: Edge) {
    if (!edge.from || !edge.to || !edge.relation) {
      this.metrics.recordError(1);
      this.recordAudit("addEdge:error", "write", { reason: "missing-required-fields", edge });
      throw new Error("Edge must include from, to, and relation");
    }
    this.edges.push({ ...edge, metadata: { ...(edge.metadata ?? {}) } });
    this.metrics.recordExecution(1);
    this.recordAudit("addEdge", "write", { from: edge.from, to: edge.to, relation: edge.relation });
    return edge;
  }

  getNode(id: string) {
    return this.nodes.get(id);
  }

  getNeighbors(nodeId: string) {
    const neighborIds = new Set<string>();
    this.edges.forEach((edge) => {
      if (edge.from === nodeId) neighborIds.add(edge.to);
      if (edge.to === nodeId) neighborIds.add(edge.from);
    });
    const neighbors = Array.from(neighborIds)
      .map((id) => this.nodes.get(id))
      .filter((node): node is Node => !!node);
    this.metrics.recordExecution(1);
    this.recordAudit("getNeighbors", "read", { nodeId, count: neighbors.length });
    return neighbors;
  }

  query(query: GraphQuery): QueryResult {
    this.metrics.recordExecution(1);

    const matchesAttributes = (node: Node) => {
      if (!query.attributes) return true;
      const attrs = node.attributes ?? {};
      return Object.entries(query.attributes).every(([key, value]) => attrs[key] === value);
    };

    const nodes = Array.from(this.nodes.values()).filter((node) => {
      if (query.nodeId && node.id !== query.nodeId) return false;
      if (query.nodeType && node.type !== query.nodeType) return false;
      return matchesAttributes(node);
    });

    const edges = this.edges.filter((edge) => {
      if (query.relation && edge.relation !== query.relation) return false;
      if (query.neighborOf) {
        const target = query.neighborOf;
        const direction = query.direction ?? "any";
        const matchesIncoming = edge.to === target;
        const matchesOutgoing = edge.from === target;
        const matchesAny = matchesIncoming || matchesOutgoing;

        if (direction === "incoming" && !matchesIncoming) return false;
        if (direction === "outgoing" && !matchesOutgoing) return false;
        if (direction === "any" && !matchesAny) return false;
      }
      if (query.nodeId) {
        return edge.from === query.nodeId || edge.to === query.nodeId;
      }
      return true;
    });

    const neighbors = query.neighborOf ? this.getNeighbors(query.neighborOf) : [];

    this.recordAudit("query", "read", {
      nodeMatches: nodes.length,
      edgeMatches: edges.length,
      hasNeighborFilter: !!query.neighborOf,
    });

    return { nodes, edges, neighbors };
  }

  getSnapshot() {
    return {
      nodes: Array.from(this.nodes.values()),
      edges: [...this.edges],
      metrics: this.metrics.getSnapshot(),
      auditCount: this.audit.getCount(),
    };
  }
}
