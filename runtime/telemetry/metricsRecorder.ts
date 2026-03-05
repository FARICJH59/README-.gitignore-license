export type MetricSnapshot = {
  parsed: number;
  errors: number;
  lastUpdated: number;
};

export class MetricsRecorder {
  private snapshot: MetricSnapshot = { parsed: 0, errors: 0, lastUpdated: Date.now() };

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
}
