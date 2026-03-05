export type MetricSnapshot = {
  parsed: number;
  errors: number;
  executions: number;
  retries: number;
  recoveries: number;
  lastUpdated: number;
};

export class MetricsRecorder {
  private snapshot: MetricSnapshot = {
    parsed: 0,
    errors: 0,
    executions: 0,
    retries: 0,
    recoveries: 0,
    lastUpdated: Date.now(),
  };

  recordParsed(count = 1) {
    this.snapshot = {
      ...this.snapshot,
      parsed: this.snapshot.parsed + count,
      lastUpdated: Date.now(),
    };
    return this.snapshot;
  }

  recordError(count = 1) {
    this.snapshot = {
      ...this.snapshot,
      errors: this.snapshot.errors + count,
      lastUpdated: Date.now(),
    };
    return this.snapshot;
  }

  getSnapshot() {
    return { ...this.snapshot };
  }

  recordExecution(count = 1) {
    this.snapshot = {
      ...this.snapshot,
      executions: this.snapshot.executions + count,
      lastUpdated: Date.now(),
    };
    return this.snapshot;
  }

  recordRetry(count = 1) {
    this.snapshot = {
      ...this.snapshot,
      retries: this.snapshot.retries + count,
      lastUpdated: Date.now(),
    };
    return this.snapshot;
  }

  recordRecovery(count = 1) {
    this.snapshot = {
      ...this.snapshot,
      recoveries: this.snapshot.recoveries + count,
      lastUpdated: Date.now(),
    };
    return this.snapshot;
  }
}
