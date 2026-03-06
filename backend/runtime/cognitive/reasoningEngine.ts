import { AuditLogger } from "../../../runtime/governance/auditLogger";
import { MetricsRecorder } from "../../../runtime/telemetry/metricsRecorder";
import { Edge, Node } from "./graphTypes";
import { KnowledgeGraph } from "./knowledgeGraph";
import { MemoryStore } from "./memoryStore";

type Path = string[];

export class ReasoningEngine {
  private audit: AuditLogger;
  private metrics: MetricsRecorder;

  constructor(
    private graph: KnowledgeGraph,
    private memory: MemoryStore,
    options?: { audit?: AuditLogger; metrics?: MetricsRecorder },
  ) {
    this.audit = options?.audit ?? new AuditLogger();
    this.metrics = options?.metrics ?? new MetricsRecorder();
  }

  findRelationships(nodeId: string): { node: Node | undefined; neighbors: Node[]; edges: Edge[] } {
    const node = this.graph.getNode(nodeId);
    const edges = this.graph.getEdges().filter((edge) => edge.from === nodeId || edge.to === nodeId);
    const neighbors = this.graph.getNeighbors(nodeId);
    this.audit.record("ReasoningEngine", "findRelationships", "read", { nodeId, neighbors: neighbors.length });
    this.metrics.recordExecution(1);
    return { node, neighbors, edges };
  }

  inferAssociations(seedId: string, relation = "related") {
    const seedEdges = this.graph.getEdges().filter((edge) => edge.from === seedId && edge.relation === relation);
    const inferred: Edge[] = [];
    for (const edge of seedEdges) {
      const neighbors = this.graph.getEdges().filter((e) => e.from === edge.to && e.relation === relation);
      for (const candidate of neighbors) {
        const exists = this.graph
          .getEdges()
          .some((existing) => existing.from === seedId && existing.to === candidate.to && existing.relation === "inferred");
        if (!exists) {
          const newEdge: Edge = { from: seedId, to: candidate.to, relation: "inferred" };
          inferred.push(this.graph.addEdge(newEdge));
        }
      }
    }
    this.audit.record("ReasoningEngine", "inferAssociations", "write", { seedId, inferred: inferred.length });
    this.metrics.recordExecution(inferred.length || 1);
    return inferred;
  }

  findPath(startId: string, targetId: string, maxDepth = 5): Path | null {
    if (startId === targetId) return [startId];
    const visited = new Set<string>([startId]);
    const queue: { node: string; path: Path }[] = [{ node: startId, path: [startId] }];
    while (queue.length) {
      const current = queue.shift();
      if (!current) break;
      const neighbors = this.graph.getNeighbors(current.node);
      for (const neighbor of neighbors) {
        if (!neighbor) continue;
        if (visited.has(neighbor.id)) continue;
        const nextPath = [...current.path, neighbor.id];
        if (neighbor.id === targetId) {
          this.audit.record("ReasoningEngine", "findPath", "read", { startId, targetId, hops: nextPath.length - 1 });
          this.metrics.recordExecution(1);
          return nextPath;
        }
        if (nextPath.length <= maxDepth + 1) {
          visited.add(neighbor.id);
          queue.push({ node: neighbor.id, path: nextPath });
        }
      }
    }
    this.audit.record("ReasoningEngine", "findPath", "read", { startId, targetId, hops: null });
    this.metrics.recordError(1);
    return null;
  }

  remember(agentId: string, data: unknown, relatedNode?: string) {
    const entryId =
      typeof crypto !== "undefined" && "randomUUID" in crypto ? crypto.randomUUID() : `mem-${Date.now()}-${Math.random()}`;
    const entry = {
      id: entryId,
      agentId,
      nodeId: relatedNode,
      data,
      timestamp: Date.now(),
    };
    this.memory.saveMemory(agentId, entry);
    this.audit.record("ReasoningEngine", "remember", "write", { agentId, relatedNode });
    this.metrics.recordExecution(1);
    return entry;
  }
}
