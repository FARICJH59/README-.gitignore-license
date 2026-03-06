import type { KnowledgeGraph } from "../../backend/runtime/cognitive/knowledgeGraph";
import type { MemoryStore } from "../../backend/runtime/cognitive/memoryStore";
import type { ReasoningEngine } from "../../backend/runtime/cognitive/reasoningEngine";

export type AgentContext = {
  graph?: KnowledgeGraph;
  memoryStore?: MemoryStore;
  reasoning?: ReasoningEngine;
  [key: string]: unknown;
};
export type AgentEnv = { context?: AgentContext } & Record<string, unknown>;
export type AgentInit<TState = unknown> = { state?: TState; env?: AgentEnv };

export class Agent<TState = unknown> {
  state: TState;
  env: AgentEnv;
  context?: AgentContext;

  constructor(init?: AgentInit<TState>) {
    const hasInitialState = (value: unknown): value is { initialState: TState } =>
      typeof (value as { initialState?: TState }).initialState !== "undefined";
    if (init?.state !== undefined) {
      this.state = init.state;
    } else if (hasInitialState(this)) {
      this.state = (this as { initialState: TState }).initialState;
    } else {
      this.state = {} as TState;
    }
    this.env = { ...(init?.env ?? {}) };
    this.context = init?.env?.context;
  }

  setState(next: TState) {
    this.state = next;
  }
}

/**
 * No-op decorator placeholder used for callable methods in local/test contexts.
 * In production, the real implementation would expose methods to the agent runtime.
 */
export function callable(): MethodDecorator {
  return (_target, _propertyKey, descriptor) => descriptor;
}
