import { AgentDescriptor } from "../types";

export class MarketplaceInstaller {
  private installed: AgentDescriptor[] = [];

  install(agent: AgentDescriptor) {
    if (agent.layer !== "marketplace") {
      throw new Error(`MarketplaceInstaller can only install marketplace agents, received ${agent.layer}`);
    }
    this.installed.push(agent);
    return { status: "installed", agent: agent.name };
  }

  listInstalled() {
    return [...this.installed];
  }
}
