import { agentBootstrap } from "../runtime/bootstrap/agentBootstrap";
import "../runtime/executor/dataParserAgent";
import "../runtime/executor/fraudDetectionAgent";
import "../runtime/revenue/pricingAgent";
import { AgentExecutor } from "../runtime/executor/engine/agentExecutor";
import { AgentScheduler } from "../runtime/executor/engine/agentScheduler";
import { AgentRetryManager } from "../runtime/executor/engine/agentRetryManager";
import { AgentSelfHeal } from "../runtime/executor/engine/agentSelfHeal";

async function main() {
  const selfHeal = new AgentSelfHeal({ debug: true });
  const executor = new AgentExecutor({ debug: true, selfHeal });
  const scheduler = new AgentScheduler(executor, { debug: true });
  const retryManager = new AgentRetryManager(executor, { debug: true });

  console.log("Registered agents:", agentBootstrap.list().map((a) => a.name));

  const parsed = await executor.run("DataParserAgent", { id: "100", status: "ok", amount: 42 });
  console.log("DataParserAgent output:", parsed);

  const pipelineResult = await executor.executePipeline(
    ["DataParserAgent", "FraudDetectionAgent", "PricingAgent"],
    { id: "tx-500", amount: 1200, velocity: 12, location: "remote" },
  );
  console.log("Pipeline output:", pipelineResult);

  try {
    // Intentionally pass an invalid input to demonstrate retry and self-heal behavior.
    await retryManager.retry("FraudDetectionAgent", undefined, 2);
  } catch (err) {
    console.log("Retry exhausted as expected:", (err as Error).message);
  }

  const scheduledId = scheduler.schedule("DataParserAgent", { scheduled: true }, 50);
  console.log("Scheduled job id:", scheduledId);

  const intervalId = scheduler.scheduleRecurring("DataParserAgent", 50, { heartbeat: true });
  await new Promise((resolve) => setTimeout(resolve, 120));
  scheduler.cancelScheduled(intervalId);

  console.log("Executor metrics:", executor.getMetrics());
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
