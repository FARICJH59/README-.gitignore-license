import { AuditLogger } from "../../../runtime/governance/auditLogger";
import { MetricsRecorder } from "../../../runtime/telemetry/metricsRecorder";
import { Edge, Node } from "./graphTypes";
import { KnowledgeGraph } from "./knowledgeGraph";

type InferenceRule = {
  description: string;
  applies: (node: Node) => boolean;
  infer: (node: Node, graph: KnowledgeGraph) => Edge | Edge[] | null | undefined;
};

const REASONER_AGENT = "CognitiveReasoningEngine";

export class ReasoningEngine {
  private audit: AuditLogger;
  private metrics: MetricsRecorder;

  constructor(private graph: KnowledgeGraph, options?: { auditLogger?: AuditLogger; metricsRecorder?: MetricsRecorder }) {
    this.audit = options?.auditLogger ?? new AuditLogger();
    this.metrics = options?.metricsRecorder ?? new MetricsRecorder();
  }

  findRelationships(nodeId: string) {
    const neighbors = this.graph.getNeighbors(nodeId);
    const relatedEdges = this.graph.query({ nodeId }).edges;
    const edgeLookup = relatedEdges.reduce<Map<string, Edge[]>>((acc, edge) => {
      let partner: string | undefined;
      if (edge.from === nodeId) {
        partner = edge.to;
      } else if (edge.to === nodeId) {
        partner = edge.from;
      }
      if (!partner) return acc;
      const list = acc.get(partner) ?? [];
      acc.set(partner, [...list, edge]);
      return acc;
    }, new Map());
    const connections = neighbors.map((neighbor) => ({
      neighbor,
      edges: edgeLookup.get(neighbor.id) ?? [],
    }));
    this.audit.record(REASONER_AGENT, "findRelationships", "read", { nodeId, neighborCount: neighbors.length });
    this.metrics.recordExecution(1);
    return connections;
  }

  applyRules(rules: InferenceRule[]) {
    const additions: Edge[] = [];
    for (const node of this.graph.getSnapshot().nodes) {
      for (const rule of rules) {
        if (!rule.applies(node)) continue;
        const inferred = rule.infer(node, this.graph);
        if (!inferred) continue;
        const inferredEdges = Array.isArray(inferred) ? inferred : [inferred];
        inferredEdges.forEach((edge) => {
          this.graph.addEdge(edge);
          additions.push(edge);
          this.audit.record(REASONER_AGENT, "infer", "write", {
            description: rule.description,
            from: edge.from,
            to: edge.to,
            relation: edge.relation,
          });
        });
      }
    }
    this.metrics.recordExecution(additions.length);
    if (additions.length === 0) {
      this.audit.record(REASONER_AGENT, "infer:no-additions", "read", { evaluatedRules: rules.length });
    }
    return additions;
  }

  /**
   * Breadth-first search between two nodes.
   * @param startId Starting node identifier.
   * @param targetId Destination node identifier.
   * @param maxDepth Optional search depth limit (default: 5). The search will not explore beyond this depth, so longer paths are intentionally ignored.
   * @returns Ordered node ids representing the path, or an empty array when no allowable path is found.
   */
  findPath(startId: string, targetId: string, maxDepth = 5) {
    if (startId === targetId) return [startId];
    const visited = new Set<string>([startId]);
    const queue: { nodeId: string; path: string[] }[] = [{ nodeId: startId, path: [startId] }];

    for (let cursor = 0; cursor < queue.length; cursor += 1) {
      const { nodeId, path } = queue[cursor];
      if (path.length > maxDepth) continue;
      const neighbors = this.graph.getNeighbors(nodeId);
      for (const neighbor of neighbors) {
        if (visited.has(neighbor.id)) continue;
        const nextPath = [...path, neighbor.id];
        if (neighbor.id === targetId) {
          this.audit.record(REASONER_AGENT, "findPath", "read", { startId, targetId, length: nextPath.length });
          this.metrics.recordExecution(nextPath.length);
          return nextPath;
        }
        visited.add(neighbor.id);
        queue.push({ nodeId: neighbor.id, path: nextPath });
      }
    }
    this.audit.record(REASONER_AGENT, "findPath:not-found", "read", { startId, targetId });
    this.metrics.recordExecution(1);
    return [];
  }
}
