import { useAgent } from "agents/react";
import { useMemo, useState } from "react";

const bubbleClass = {
  user: "bg-indigo-600 text-white ml-auto",
  assistant: "bg-slate-100 text-slate-900 mr-auto",
};

const roleTextClass = {
  user: "text-indigo-50",
  assistant: "text-slate-900",
};

export default function ChatUI() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const agent = useAgent({
    agent: "ChatAgent",
    onStateUpdate: (state) => setMessages(state.messages ?? []),
  });

  const ordered = useMemo(
    () => [...messages].sort((a, b) => (a.ts ?? 0) - (b.ts ?? 0)),
    [messages]
  );

  const handleSend = async (e) => {
    e?.preventDefault();
    if (!input.trim()) return;
    await agent.stub.sendMessage(input.trim());
    setInput("");
  };

  return (
    <div className="flex h-full flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-indigo-500">Cloudflare AI Playground</p>
          <h2 className="text-lg font-semibold text-slate-900">Chat with ChatAgent</h2>
        </div>
        <span className="rounded-full bg-indigo-50 px-3 py-1 text-xs font-semibold text-indigo-700">
          Agent: ChatAgent
        </span>
      </div>

      <div className="flex-1 space-y-3 overflow-y-auto rounded-xl bg-slate-50 p-3">
        {ordered.length === 0 ? (
          <p className="text-sm text-slate-500">Start the conversation to see streaming responses.</p>
        ) : (
          ordered.map((msg, idx) => (
            <div
              key={`${msg.ts}-${idx}`}
              className={`max-w-[85%] rounded-2xl px-4 py-3 text-sm shadow-sm ${bubbleClass[msg.role] ?? ""}`}
            >
              <p className={`text-xs uppercase tracking-wide ${roleTextClass[msg.role] ?? "text-slate-900"}`}>
                {msg.role}
              </p>
              <p className="mt-1 leading-relaxed">{msg.content}</p>
            </div>
          ))
        )}
      </div>

      <form onSubmit={handleSend} className="flex gap-2">
        <input
          className="flex-1 rounded-xl border border-slate-200 px-3 py-2 text-sm outline-none focus:border-indigo-500 focus:ring focus:ring-indigo-100"
          placeholder="Ask the agent something..."
          value={input}
          onChange={(e) => setInput(e.target.value)}
        />
        <button
          type="submit"
          className="rounded-xl bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        >
          Send
        </button>
      </form>
    </div>
  );
}
