import { Permission } from "../types";

type AuditEvent = {
  agent: string;
  action: string;
  permission: Permission;
  timestamp: number;
  details?: Record<string, unknown>;
};

export class AuditLogger {
  private events: AuditEvent[] = [];

  record(agent: string, action: string, permission: Permission, details?: Record<string, unknown>) {
    const event: AuditEvent = {
      agent,
      action,
      permission,
      timestamp: Date.now(),
      details,
    };
    this.events.push(event);
    console.debug(`[Audit] ${agent} -> ${action} (${permission})`, details ?? {});
  }

  getEvents() {
    return [...this.events];
  }
}
