/**
 * Registration metadata for an agent. The shape is intentionally flat so the
 * bootstrapper can safely clone values without deep-copy utilities.
 */
export interface AgentRegistration {
  name: string;
  role: string;
  permissions: string[];
  version: string;
}

export class AgentBootstrap {
  private registeredAgents: AgentRegistration[] = [];

  /**
   * Register a list of agents for the current worker lifecycle. Agents are
   * deduplicated by name and version to avoid double registration across
   * repeated bootstrap calls.
   */
  autoRegister(agents: AgentRegistration[]) {
    for (const agent of agents) {
      const existing = this.registeredAgents.find(
        (registered) => registered.name === agent.name && registered.version === agent.version,
      );
      if (existing) {
        const existingPermissions = new Set(existing.permissions);
        const incomingPermissions = new Set(agent.permissions);
        const permissionsMatch =
          existingPermissions.size === incomingPermissions.size &&
          [...existingPermissions].every((permission) => incomingPermissions.has(permission));
        if (existing.role !== agent.role || !permissionsMatch) {
          console.warn(
            `Agent ${agent.name}@${agent.version} already registered with different metadata; skipping re-registration.`,
          );
        }
        continue;
      }

      const normalizedAgent: AgentRegistration = {
        name: agent.name,
        role: agent.role,
        permissions: [...agent.permissions],
        version: agent.version,
      };
      this.registeredAgents.push(normalizedAgent);
    }
  }

  /**
   * Returns a copy of the registered agents to prevent callers from mutating
   * the internal registry.
   */
  getRegisteredAgents() {
    return this.registeredAgents.map((agent) => ({
      ...agent,
      permissions: [...agent.permissions],
    }));
  }
}
