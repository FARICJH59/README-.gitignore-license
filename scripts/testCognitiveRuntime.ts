import { AgentExecutor } from "../runtime/executor/engine/agentExecutor";
import { KnowledgeGraph } from "../backend/runtime/cognitive/knowledgeGraph";
import { MemoryStore } from "../backend/runtime/cognitive/memoryStore";
import { ReasoningEngine } from "../backend/runtime/cognitive/reasoningEngine";

async function main() {
  const executor = new AgentExecutor({ debug: true });
  // Direct graph usage through the shared runtime context
  const context = executor.getRuntimeContext();
  context.graph.addNode({ id: "user-1", type: "user", attributes: { role: "admin" } });
  context.graph.addNode({ id: "order-1", type: "order", attributes: { amount: 120 } });
  context.graph.addEdge({ from: "user-1", to: "order-1", relation: "created" });

  const queryResult = context.graph.query({ nodeType: "user" });
  console.log("Matched nodes:", queryResult.nodes.length);

  const neighbors = context.graph.getNeighbors("user-1");
  console.log("Neighbor count:", neighbors.length);

  const path = context.reasoning.findPath("user-1", "order-1");
  console.log("Path found:", path);

  const inferred = context.reasoning.inferAssociations("user-1", "created");
  console.log("Inferred edges:", inferred.length);

  const memoryEntry = context.reasoning.remember("diagnostic-agent", { note: "test-memory" }, "user-1");
  console.log("Memory entry recorded:", memoryEntry.id);

  // Ensure cognitive modules can also be used independently if needed.
  const standaloneGraph = new KnowledgeGraph();
  const standaloneMemory = new MemoryStore();
  const standaloneReasoning = new ReasoningEngine(standaloneGraph, standaloneMemory);
  standaloneGraph.addNode({ id: "x", type: "concept" });
  standaloneGraph.addNode({ id: "y", type: "concept" });
  standaloneGraph.addEdge({ from: "x", to: "y", relation: "relates" });
  console.log("Standalone path:", standaloneReasoning.findPath("x", "y"));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
