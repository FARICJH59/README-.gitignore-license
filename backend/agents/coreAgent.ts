import { Agent, callable } from "agents";

export class CoreAgent extends Agent {
  initialState = { tasks: [] as string[] };

  @callable()
  addTask(task: string) {
    this.setState({ tasks: [...this.state.tasks, task] });
    return this.state.tasks;
  }

  @callable()
  listTasks() {
    return this.state.tasks;
  }
}
