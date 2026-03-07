import { DurableObjectNamespace } from "cloudflare:workers";
import { appendTelemetry, getJson, listByPrefix } from "../../utils/kvHelper";

interface IotEnv {
  KV_STATE: any;
  AXIOM_DO: DurableObjectNamespace;
}

export async function handleTelemetry(request: Request, env: IotEnv) {
  const { deviceId, payload } = await request.json();
  await appendTelemetry(env as any, deviceId, payload ?? {});
  const id = env.AXIOM_DO.idFromName(`device:${deviceId}`);
  const stub = env.AXIOM_DO.get(id);
  await stub.fetch(new Request("https://do.internal/telemetry", { method: "POST", body: JSON.stringify({ deviceId, payload }) }));
  return new Response(JSON.stringify({ status: "accepted", deviceId }), { headers: { "content-type": "application/json" } });
}

export async function handleListDevices(env: IotEnv) {
  const keys = await listByPrefix(env as any, "iot:");
  const devices = [...new Set(keys.map((k) => k.split(":")[1]))];
  const latest = await Promise.all(
    devices.map(async (deviceId) => {
      const key = keys
        .filter((k) => k.includes(deviceId))
        .sort()
        .pop();
      const data = key ? await getJson(env as any, key) : null;
      return { deviceId, last: data };
    })
  );
  return new Response(JSON.stringify({ devices: latest }), { headers: { "content-type": "application/json" } });
}
