import { AuditLogger } from "../../../runtime/governance/auditLogger";
import { MetricsRecorder } from "../../../runtime/telemetry/metricsRecorder";
import { Edge, GraphQuery, GraphQueryResult, Node } from "./graphTypes";

export class KnowledgeGraph {
  private nodes = new Map<string, Node>();
  private edges: Edge[] = [];
  private metrics: MetricsRecorder;
  private audit: AuditLogger;

  constructor(options?: { metrics?: MetricsRecorder; audit?: AuditLogger }) {
    this.metrics = options?.metrics ?? new MetricsRecorder();
    this.audit = options?.audit ?? new AuditLogger();
  }

  addNode(node: Node) {
    const existing = this.nodes.get(node.id);
    const merged: Node = existing
      ? {
          ...existing,
          attributes: { ...(existing.attributes ?? {}), ...(node.attributes ?? {}) },
        }
      : { ...node, attributes: { ...(node.attributes ?? {}) } };
    this.nodes.set(node.id, merged);
    this.metrics.recordExecution(1);
    this.audit.record("CognitiveGraph", "addNode", "write", { id: node.id, type: node.type });
    return merged;
  }

  addEdge(edge: Edge) {
    this.edges.push(edge);
    this.metrics.recordExecution(1);
    this.audit.record("CognitiveGraph", "addEdge", "write", {
      relation: edge.relation,
      from: edge.from,
      to: edge.to,
    });
    return edge;
  }

  getEdges() {
    return [...this.edges];
  }

  getNode(id: string) {
    return this.nodes.get(id);
  }

  getNeighbors(nodeId: string) {
    const neighborIds = this.edges
      .filter((edge) => edge.from === nodeId || edge.to === nodeId)
      .map((edge) => (edge.from === nodeId ? edge.to : edge.from));
    const uniqueIds = [...new Set(neighborIds)];
    const neighbors = uniqueIds
      .map((id) => this.nodes.get(id))
      .filter((node): node is Node => Boolean(node));
    this.audit.record("CognitiveGraph", "getNeighbors", "read", { nodeId, count: neighbors.length });
    return neighbors;
  }

  query(query: GraphQuery): GraphQueryResult {
    const nodes = [...this.nodes.values()].filter((node) => {
      if (query.nodeType && node.type !== query.nodeType) return false;
      if (query.attributes) {
        const entries = Object.entries(query.attributes);
        const matchesAll = entries.every(([key, value]) => node.attributes?.[key] === value);
        if (!matchesAll) return false;
      }
      if (query.predicate && !query.predicate(node)) return false;
      return true;
    });

    const edges = this.edges.filter((edge) => {
      if (query.relation && edge.relation !== query.relation) return false;
      if (query.from && edge.from !== query.from) return false;
      if (query.to && edge.to !== query.to) return false;
      if (nodes.length) {
        return nodes.some((node) => node.id === edge.from || node.id === edge.to);
      }
      return true;
    });

    this.audit.record("CognitiveGraph", "query", "read", {
      nodeType: query.nodeType,
      relation: query.relation,
      matchedNodes: nodes.length,
      matchedEdges: edges.length,
    });
    this.metrics.recordExecution(1);
    return { nodes, edges };
  }
}
