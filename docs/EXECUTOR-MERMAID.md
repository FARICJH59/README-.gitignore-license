## AxiomCore Executor Layer (Mermaid)

```mermaid
flowchart TB
  %% Layer grouping
  subgraph RuntimeExecutor["runtime/executor"]
    subgraph Registration["Registration"]
      AgentBootstrap["AgentBootstrap\n(registers descriptors)"]
      AgentRegistry["AgentRegistry\n(registerExecutorAgent)"]
    end

    subgraph Engine["Execution Engine"]
      AgentExecutor["AgentExecutor\nrun/stream/executePipeline"]
      AgentScheduler["AgentScheduler\nschedule + recurring"]
      AgentRetryManager["AgentRetryManager\nexponential backoff"]
      AgentSelfHeal["AgentSelfHeal\nrestart on failure"]
      MetricsRecorder["MetricsRecorder\nparsed/errors/executions/retries/recoveries"]
      AuditLogger["AuditLogger\nrecords events"]
    end

    subgraph Agents["Agents"]
      DataParserAgent["DataParserAgent\n- parseData\n- produces key/value list"]
      FraudDetectionAgent["FraudDetectionAgent\n- analyzeTransactions\n- flagSuspicious"]
      PredictionAgent["PredictionAgent\n- execute scoring\n- feature normalization 0-100"]
    end
  end

  %% Registration flow
  AgentBootstrap <-- registers --> AgentRegistry
  AgentRegistry --> AgentExecutor

  %% Input/Output
  IngestInput["Input payload"] --> AgentExecutor
  AgentExecutor -->|runs| DataParserAgent
  DataParserAgent -->|parsed key/values| FraudDetectionAgent
  FraudDetectionAgent -->|flags/metrics| PredictionAgent
  PredictionAgent -->|score+label output| PipelineOutput["Pipeline Output"]

  %% Metrics & Audit
  AgentExecutor -.-> AuditLogger
  AgentExecutor -.-> MetricsRecorder
  DataParserAgent -. audit .-> AuditLogger
  FraudDetectionAgent -. audit .-> AuditLogger
  PredictionAgent -. audit .-> AuditLogger
  DataParserAgent -. metrics .-> MetricsRecorder
  FraudDetectionAgent -. metrics .-> MetricsRecorder
  PredictionAgent -. metrics .-> MetricsRecorder

  %% Scheduler / Retry / Self-heal
  AgentScheduler -->|invoke later/interval| AgentExecutor
  AgentRetryManager -->|retry on error| AgentExecutor
  AgentSelfHeal -->|restart agent| AgentExecutor
  AgentExecutor -->|restarts| AgentSelfHeal

  %% Notes on PredictionAgent normalization
  note right of PredictionAgent
    - Filters non-numeric/NaN features
    - Normalizes features (0-100 baseline)
    - Uses observed max to avoid ceiling
    - Emits score + label (low/medium/high)
  end

  classDef reg fill:#eef,stroke:#446;
  classDef eng fill:#efe,stroke:#484;
  classDef agent fill:#fee,stroke:#844;

  class AgentBootstrap,AgentRegistry reg;
  class AgentExecutor,AgentScheduler,AgentRetryManager,AgentSelfHeal,MetricsRecorder,AuditLogger eng;
  class DataParserAgent,FraudDetectionAgent,PredictionAgent agent;
```
