import { Agent, callable } from "agents";

type Task = { id: string; description: string; status: "pending" | "running" | "done"; ts: number };

export class CoreAgent extends Agent {
  initialState = { tasks: [] as Task[], context: {} as Record<string, unknown> };

  @callable()
  addTask(description: string) {
    const task: Task = { id: crypto.randomUUID(), description, status: "pending", ts: Date.now() };
    const tasks = [...this.state.tasks, task];
    this.setState({ tasks });
    return task;
  }

  @callable()
  updateContext(key: string, value: unknown) {
    const context = { ...(this.state.context ?? {}), [key]: value };
    this.setState({ context });
    return context;
  }

  @callable()
  listTasks() {
    return this.state.tasks;
  }

  @callable()
  completeTask(id: string) {
    const tasks = this.state.tasks.map((t) => (t.id === id ? { ...t, status: "done" as const } : t));
    this.setState({ tasks });
    return tasks;
  }
}
