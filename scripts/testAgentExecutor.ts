import { agentBootstrap } from "../runtime/bootstrap/agentBootstrap";
import "../runtime/executor/dataParserAgent";
import "../runtime/executor/fraudDetectionAgent";
import "../runtime/executor/predictionAgent";
import "../runtime/revenue/pricingAgent";
import { AgentExecutor } from "../runtime/executor/engine/agentExecutor";
import { AgentScheduler } from "../runtime/executor/engine/agentScheduler";
import { AgentRetryManager } from "../runtime/executor/engine/agentRetryManager";
import { AgentSelfHeal } from "../runtime/executor/engine/agentSelfHeal";

const RECURRING_TEST_DURATION_MS = 120;

async function main() {
  const selfHeal = new AgentSelfHeal({ debug: true });
  const executor = new AgentExecutor({ debug: true, selfHeal });
  const scheduler = new AgentScheduler(executor, { debug: true });
  const retryManager = new AgentRetryManager(executor, { debug: true });

  console.log("Registered agents:", agentBootstrap.list().map((a) => a.name));

  const parsed = await executor.run("DataParserAgent", { id: "100", status: "ok", amount: 42 });
  console.log("DataParserAgent output:", parsed);

  const prediction = await executor.run("PredictionAgent", { amount: 120, velocity: 8, locationRisk: 30 });
  console.log("PredictionAgent output:", prediction);

  const pipelineResult = await executor.executePipeline(
    ["DataParserAgent", "FraudDetectionAgent", "PredictionAgent", "PricingAgent"],
    { id: "tx-500", amount: 1200, velocity: 12, location: "remote" },
  );
  console.log("Pipeline output:", pipelineResult);

  const cognitive = executor.getRuntimeContext();
  cognitive.graph.addNode({ id: "customer:1", type: "entity", attributes: { segment: "gold" } });
  cognitive.graph.addNode({ id: "account:1", type: "account", attributes: { balance: 1200 } });
  cognitive.graph.addEdge({ from: "customer:1", to: "account:1", relation: "owns" });
  cognitive.memoryStore.saveMemory("FraudDetectionAgent", {
    timestamp: Date.now(),
    data: { lastCheck: "account:1" },
    relatedNodeIds: ["account:1"],
  });
  const knowledge = cognitive.graph.query({ neighborOf: "customer:1" });
  const path = cognitive.reasoning.findPath("customer:1", "account:1");
  console.log("Cognitive graph neighbors:", knowledge.neighbors);
  console.log("Cognitive path:", path);

  try {
    // Intentionally pass an invalid input to demonstrate retry and self-heal behavior.
    await retryManager.retry("FraudDetectionAgent", undefined, 2);
  } catch (err) {
    console.log("Retry exhausted as expected:", (err as Error).message);
  }

  const scheduledId = scheduler.schedule("DataParserAgent", { scheduled: true }, 50);
  console.log("Scheduled job id:", scheduledId);

  const intervalId = scheduler.scheduleRecurring("DataParserAgent", 50, { heartbeat: true });
  await new Promise((resolve) => setTimeout(resolve, RECURRING_TEST_DURATION_MS));
  scheduler.cancelScheduled(intervalId);

  console.log("Executor metrics:", executor.getMetrics());
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
