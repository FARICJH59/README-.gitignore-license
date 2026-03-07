/* eslint-disable @typescript-eslint/no-var-requires */
/// <reference types="node" />
const fs = require("node:fs") as typeof import("node:fs");
const path = require("node:path") as typeof import("node:path");
const { enforceLayerPlacement, validateLayerName } = require("../runtime/governance/layerValidator");
type AgentDescriptor = import("../runtime/types").AgentDescriptor;
type LayerName = import("../runtime/types").LayerName;
type Permission = import("../runtime/types").Permission;

type BasicAgentEntry = { path: string; layer: string; name?: string; permissions?: Permission[] };

const baseDir = path.resolve(process.cwd());

function readAgents(): BasicAgentEntry[] {
  const filePath = path.join(baseDir, "newAgents.json");
  const data = fs.readFileSync(filePath, "utf-8");
  return JSON.parse(data);
}

function fileExists(agentPath: string) {
  const fullPath = path.join(baseDir, agentPath);
  return fs.existsSync(fullPath);
}

function toDescriptor(entry: BasicAgentEntry): AgentDescriptor {
  const layer = entry.layer;
  if (!validateLayerName(layer)) {
    throw new Error(`Invalid layer in newAgents.json: ${entry.layer}`);
  }
  const typedLayer = layer as LayerName;
  const name = entry.name ?? path.basename(entry.path, ".ts");
  const permissions = entry.permissions ?? (["read"] as Permission[]);
  return {
    name,
    layer: typedLayer,
    capabilities: [],
    permissions,
    path: entry.path,
  };
}

function validate() {
  const entries = readAgents();
  if (!entries.length) throw new Error("newAgents.json is empty");

  entries.forEach((entry) => {
    if (!entry.path || !entry.layer) {
      throw new Error("Each agent entry requires path and layer");
    }
    if (!fileExists(entry.path)) {
      throw new Error(`Missing agent file: ${entry.path}`);
    }
    const descriptor = toDescriptor(entry);
    enforceLayerPlacement(descriptor);
  });

  console.log(`✅ ${entries.length} agent(s) validated and layer-compliant.`);
}

validate();
