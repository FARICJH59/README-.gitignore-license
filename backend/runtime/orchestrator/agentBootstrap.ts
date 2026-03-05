export interface AgentRegistration {
  name: string;
  role: string;
  permissions: string[];
  version: string;
}

export class AgentBootstrap {
  private registeredAgents: AgentRegistration[] = [];

  autoRegister(agents: AgentRegistration[]) {
    for (const agent of agents) {
      const exists = this.registeredAgents.some(
        (registered) => registered.name === agent.name && registered.version === agent.version,
      );
      if (!exists) {
        this.registeredAgents.push({ ...agent, permissions: [...agent.permissions] });
      }
    }
  }

  getRegisteredAgents() {
    return [...this.registeredAgents];
  }
}
