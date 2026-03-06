export function generateStableId(prefix = "id") {
  if (typeof crypto !== "undefined") {
    if ("randomUUID" in crypto && typeof crypto.randomUUID === "function") {
      return `${prefix}-${crypto.randomUUID()}`;
    }
    if ("getRandomValues" in crypto && typeof crypto.getRandomValues === "function") {
      const buffer = new Uint32Array(4);
      crypto.getRandomValues(buffer);
      const token = Array.from(buffer, (value) => value.toString(16)).join("-");
      return `${prefix}-${token}`;
    }
  }
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}
