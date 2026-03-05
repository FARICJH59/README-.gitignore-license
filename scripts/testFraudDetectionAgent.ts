import { FraudDetectionAgent } from "../runtime/executor/fraudDetectionAgent";

const agent = new FraudDetectionAgent({
  state: {
    metrics: { analyzed: 0, flagged: 0, alerts: 0, lastUpdated: Date.now() },
    lastAuditLogCount: 0,
    flagged: [],
  },
});

const sample = [
  { id: "tx-1", amount: 1200, velocity: 8, device: "unknown-device", location: "remote" },
  { id: "tx-2", amount: 80, velocity: 1, device: "mobile", location: "home" },
];

const analysis = agent.analyzeTransactions(sample);
console.log("Flagged", analysis.flagged);

const manualFlag = agent.flagSuspicious("tx-3", "manual review", 0.95);
console.log("Manual flag", manualFlag);

const metrics = agent.getMetrics();
console.log("Metrics", metrics);
console.assert(metrics.flagged === 2, "Expected two flagged transactions (analysis + manual)");

const flags = agent.listFlags();
console.log("Flags", flags);
console.assert(flags.length === 2, "Expected flags list to include both entries");
