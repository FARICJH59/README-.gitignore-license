import { Agent } from "agents";
import { AgentDescriptor } from "../types";
import { revenueEngine } from "./revenueEngine";
import { enforceLayerPlacement } from "../governance/layerValidator";

export class PricingAgent extends Agent {
  initialState = { priceBooks: [] as string[] };
}

const descriptor: AgentDescriptor = {
  name: "PricingAgent",
  layer: "revenue",
  capabilities: [],
  permissions: ["read", "write", "alert"],
  path: "runtime/revenue/pricingAgent.ts",
};

enforceLayerPlacement(descriptor);
revenueEngine.register(descriptor);
