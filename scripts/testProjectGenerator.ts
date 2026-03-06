import { ProjectPipeline } from "../runtime/pipelines/projectPipeline";

async function main() {
  const pipeline = new ProjectPipeline();
  const result = await pipeline.run("fintech", "build a fintech platform for diaspora remittances");
  console.log("Template used:", result.templateName);
  console.log("Stack:", result.stack);
  console.log("Backend artifacts:", result.backend.artifacts.length);
  console.log("Frontend artifacts:", result.frontend.artifacts.length);
  console.log("Build time (ms):", result.buildTimeMs);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
