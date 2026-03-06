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
    const connections = neighbors.map((neighbor) => ({
      neighbor,
      edges: this.graph.query({ nodeId: nodeId, neighborOf: neighbor.id }).edges,
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
    this.metrics.recordExecution(additions.length || 1);
    return additions;
  }

  findPath(startId: string, targetId: string, maxDepth = 5) {
    if (startId === targetId) return [startId];
    const visited = new Set<string>([startId]);
    const queue: { nodeId: string; path: string[] }[] = [{ nodeId: startId, path: [startId] }];

    while (queue.length) {
      const { nodeId, path } = queue.shift()!;
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
    this.metrics.recordError(1);
    return [];
  }
}
