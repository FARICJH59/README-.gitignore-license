export type TemplateDefinition = {
  name: string;
  industry: string;
  microservices: string[];
  dataModels: string[];
  mlModules: string[];
  apis: string[];
  frontend: string[];
  infrastructure: string[];
  database?: string;
  messageQueue?: string;
  frontendFramework?: string;
  backendFramework?: string;
};

let fsRef: typeof import("fs") | null = null;
let pathJoin = (...parts: string[]) => parts.join("/");

try {
  // Lazy require for worker compatibility
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const fs = require("fs") as typeof import("fs");
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const path = require("path") as typeof import("path");
  fsRef = fs;
  pathJoin = path.join.bind(path);
} catch {
  fsRef = null;
}

const DEFAULT_TEMPLATES: Record<string, TemplateDefinition> = {
  fintech: {
    name: "fintech",
    industry: "fintech",
    microservices: ["payments", "kyc", "ledger"],
    dataModels: ["customer", "transaction", "account"],
    mlModules: ["fraud", "risk-scoring"],
    apis: ["transactions", "kyc", "payouts"],
    frontend: ["dashboard", "onboarding", "payments"],
    infrastructure: ["api-gateway", "monitoring", "iam"],
    database: "postgres",
    messageQueue: "kafka",
    frontendFramework: "react",
    backendFramework: "fastapi",
  },
  healthcare: {
    name: "healthcare",
    industry: "healthcare",
    microservices: ["patient", "records", "appointments"],
    dataModels: ["patient", "provider", "appointment"],
    mlModules: ["triage", "diagnostics"],
    apis: ["ehr", "scheduling", "claims"],
    frontend: ["patient-portal", "provider-portal"],
    infrastructure: ["api-gateway", "hipaa-logging", "secure-storage"],
    database: "postgres",
    messageQueue: "nats",
    frontendFramework: "react",
    backendFramework: "fastapi",
  },
  saas: {
    name: "saas",
    industry: "saas",
    microservices: ["billing", "users", "notifications"],
    dataModels: ["user", "subscription", "invoice"],
    mlModules: ["churn", "recommendations"],
    apis: ["billing", "auth", "usage"],
    frontend: ["admin-console", "self-service-portal"],
    infrastructure: ["api-gateway", "observability", "feature-flags"],
    database: "postgres",
    messageQueue: "sqs",
    frontendFramework: "react",
    backendFramework: "node",
  },
  robotics: {
    name: "robotics",
    industry: "robotics",
    microservices: ["fleet", "telemetry", "control"],
    dataModels: ["robot", "mission", "telemetry"],
    mlModules: ["navigation", "anomaly-detection"],
    apis: ["fleet-control", "mission-planning"],
    frontend: ["operations-console"],
    infrastructure: ["mqtt-broker", "api-gateway", "edge-cache"],
    database: "timeseries",
    messageQueue: "mqtt",
    frontendFramework: "react",
    backendFramework: "rust",
  },
  ai_platform: {
    name: "ai_platform",
    industry: "ai_platform",
    microservices: ["model-registry", "training", "inference"],
    dataModels: ["dataset", "model", "deployment"],
    mlModules: ["auto-ml", "monitoring"],
    apis: ["training", "inference", "dataset"],
    frontend: ["console", "notebooks"],
    infrastructure: ["feature-store", "api-gateway", "observability"],
    database: "postgres",
    messageQueue: "kafka",
    frontendFramework: "react",
    backendFramework: "fastapi",
  },
  iot: {
    name: "iot",
    industry: "iot",
    microservices: ["device", "ingest", "rules-engine"],
    dataModels: ["device", "telemetry", "rule"],
    mlModules: ["anomaly-detection"],
    apis: ["device-management", "rules"],
    frontend: ["console", "analytics"],
    infrastructure: ["mqtt-broker", "api-gateway", "storage"],
    database: "timeseries",
    messageQueue: "mqtt",
    frontendFramework: "react",
    backendFramework: "node",
  },
  smart_city: {
    name: "smart_city",
    industry: "smart_city",
    microservices: ["traffic", "utilities", "public-safety"],
    dataModels: ["sensor", "event", "alert"],
    mlModules: ["demand-forecast", "incident-detection"],
    apis: ["traffic", "events", "alerts"],
    frontend: ["city-ops", "citizen-portal"],
    infrastructure: ["edge-gateway", "api-gateway", "monitoring"],
    database: "postgres",
    messageQueue: "kafka",
    frontendFramework: "react",
    backendFramework: "fastapi",
  },
};

const TEMPLATE_DIR = pathJoin(__dirname, "templates");

function parseYaml(raw: string) {
  const result: Record<string, unknown> = {};
  let currentKey: string | null = null;
  const lines = raw.split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    if (/^-\s*/.test(trimmed) && currentKey) {
      const value = trimmed.replace(/^-\s*/, "");
      const arr = (result[currentKey] as string[]) ?? [];
      arr.push(value);
      result[currentKey] = arr;
      continue;
    }
    const match = trimmed.match(/^([^:]+):\s*(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim();
      currentKey = key;
      if (!value) {
        result[key] = [];
      } else if (value.startsWith("[") && value.endsWith("]")) {
        try {
          result[key] = JSON.parse(value);
        } catch {
          try {
            // attempt to handle single-quoted arrays
            const normalized = value.replace(/'/g, '"');
            result[key] = JSON.parse(normalized);
          } catch {
            result[key] = value;
          }
        }
      } else {
        result[key] = value;
      }
    }
  }
  return Object.keys(result).length ? result : undefined;
}

function parseTemplate(raw: string): TemplateDefinition | undefined {
  try {
    return JSON.parse(raw) as TemplateDefinition;
  } catch {
    const yaml = parseYaml(raw);
    return yaml as TemplateDefinition | undefined;
  }
}

export function loadTemplate(name: string): TemplateDefinition {
  const key = name.replace(/\.ya?ml$/i, "").replace(/-/g, "_");
  const candidates = [`${key}.yaml`, `${key}.yml`, `${key}.json`].map((file) => pathJoin(TEMPLATE_DIR, file));
  for (const candidate of candidates) {
    try {
      if (fsRef?.existsSync(candidate)) {
        const raw = fsRef.readFileSync(candidate, "utf-8");
        const parsed = parseTemplate(raw);
        if (parsed) return parsed;
      }
    } catch {
      // continue to next candidate
    }
  }
  const fallback = DEFAULT_TEMPLATES[key];
  if (fallback) return fallback;
  return {
    name: key,
    industry: key,
    microservices: [],
    dataModels: [],
    mlModules: [],
    apis: [],
    frontend: [],
    infrastructure: [],
  };
}

export function listTemplates() {
  const defaults = Object.keys(DEFAULT_TEMPLATES);
  try {
    if (fsRef) {
      const files = fsRef.readdirSync(TEMPLATE_DIR);
      const yamlNames = files.filter((f) => f.endsWith(".yaml")).map((f) => f.replace(/\.yaml$/, ""));
      return Array.from(new Set([...defaults, ...yamlNames]));
    }
  } catch {
    // ignore
  }
  return defaults;
}
