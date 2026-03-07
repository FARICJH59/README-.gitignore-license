export type GPUClusters = {
  LLM: number;
  Vision: number;
  ML: number;
  Embedding: number;
};

export type UsageMetrics = {
  timestamp: string;
  active_brain_nodes: number;
  active_worker_nodes: number;
  gpu_clusters: GPUClusters;
  energy_consumption_mwh?: number;
  carbon_quota?: string;
};

export type DriftReport = {
  timestamp: string;
  drift_detected: boolean;
  changed_files: string[];
  summary: string;
};

export type JobItem = {
  id: string;
  type: string;
  status: string;
  eta_sec?: number;
};

export type JobsReport = {
  timestamp: string;
  queue_depth: number;
  throughput_per_min: number;
  pending: number;
  active: number;
  completed_last_hour: number;
  failures_last_hour: number;
  jobs: JobItem[];
};

export type LogEntry = {
  timestamp: string;
  level: "info" | "warn" | "error";
  message: string;
};
