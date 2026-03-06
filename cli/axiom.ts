#!/usr/bin/env node
import { ProjectPipeline } from "../runtime/pipelines/projectPipeline";
import { listTemplates } from "../runtime/project-generator/templateLoader";

async function main() {
  const [, , command, templateArg, ...rest] = process.argv;
  if (!command) {
    console.log("Usage: axiom build <template>");
    console.log(`Available templates: ${listTemplates().join(", ")}`);
    process.exit(1);
  }
  if (command !== "build") {
    console.error(`Unknown command: ${command}`);
    console.log(`Available templates: ${listTemplates().join(", ")}`);
    process.exit(1);
  }
  if (!templateArg) {
    console.error("Template name is required");
    process.exit(1);
  }
  const request = rest.length ? rest.join(" ") : `Generate ${templateArg} starter project`;
  const pipeline = new ProjectPipeline();
  const result = await pipeline.run(templateArg, request);
  console.log(`Project generated for ${result.templateName}`);
  console.log("Artifacts:");
  [...result.backend.artifacts, ...result.frontend.artifacts, ...result.ml.artifacts, ...result.devops.artifacts].forEach(
    (artifact) => {
      console.log(` - ${artifact.path}: ${artifact.description}`);
    },
  );
  console.log(`Build time: ${result.buildTimeMs}ms`);
}

main().catch((err) => {
  console.error("Build failed", err);
  process.exit(1);
});
