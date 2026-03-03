import { useEffect, useMemo, useState } from "react";

/**
 * Minimal stub of the agents/react hook used in the Cloudflare scaffold.
 * Maintains local message state and echoes interactions for demo purposes.
 */
export function useAgent({ agent, onStateUpdate }) {
  const [state, setState] = useState({ messages: [] });

  useEffect(() => {
    if (typeof onStateUpdate === "function") {
      onStateUpdate(state);
    }
  }, [state, onStateUpdate]);

  const stub = useMemo(
    () => ({
      async sendMessage(content) {
        const userMessage = { role: "user", content, ts: Date.now() };
        const assistantMessage = {
          role: "assistant",
          content: `Echo from ${agent}: ${content}`,
          ts: Date.now() + 1,
        };
        setState((prev) => {
          const messages = [...prev.messages, userMessage, assistantMessage];
          return { ...prev, messages };
        });
        return assistantMessage;
      },
    }),
    [agent]
  );

  return { state, messages: state.messages, stub };
}
