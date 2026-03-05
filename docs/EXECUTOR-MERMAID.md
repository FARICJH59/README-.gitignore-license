## AxiomCore Executor-Layer Runtime Flow

```mermaid
flowchart TD
  %% ====================
  %% Subgraphs
  %% ====================
  subgraph "Agents"
    DP[DataParserAgent]
    FD[FraudDetectionAgent]
    PR[PredictionAgent]
    PC[PricingAgent]
  end

  subgraph "Executor Engine"
    AE[AgentExecutor\nrun | stream | executePipeline]
    AS[AgentScheduler\nschedule | recurring]
    RM[AgentRetryManager\nexponential backoff]
    SH[AgentSelfHeal\nrestart + recover]
  end

  subgraph "Bootstrap & Registry"
    AB[AgentBootstrap\nload descriptors]
    AR[AgentRegistry\nregisterExecutorAgent]
    LV[LayerValidator\nschema & guardrails]
  end

  subgraph "Telemetry & Governance"
    ML[MetricsRecorder\nparsed/errors/executions/retries/recoveries]
    AL[AuditLogger\nread/alert events]
  end

  %% ====================
  %% Agent Registration
  %% ====================
  DP -->|register| AB
  FD -->|register| AB
  PR -->|register| AB
  PC -->|register| AB
  AB -->|registers| AR
  AR -->|validates| LV
  LV -->|approved catalog| AE

  %% ====================
  %% Pipeline Flow
  %% ====================
  Input["Input payload"] --> DP
  DP -->|parsed data| FD
  FD -->|fraud flags| PR
  PR -->|score + label| PC
  PC -->|pricing result| Output["Priced output"]

  %% ====================
  %% Executor Engine Flow
  %% ====================
  AE -->|run/stream| DP
  AE --> FD
  AE --> PR
  AE --> PC
  AE --> AS
  AS -->|scheduled execution| AE
  AE --> RM
  RM -->|retry with backoff| AE
  AE --> SH
  SH -->|restart agent| AE

  %% ====================
  %% Metrics & Audit
  %% ====================
  DP -. metrics .-> ML
  FD -. metrics .-> ML
  PR -. metrics .-> ML
  PC -. metrics .-> ML
  AE -. metrics .-> ML
  AS -. metrics .-> ML
  RM -. metrics .-> ML
  SH -. metrics .-> ML

  DP -. audit .-> AL
  FD -. audit .-> AL
  PR -. audit .-> AL
  PC -. audit .-> AL
  AE -. audit .-> AL
  AS -. audit .-> AL
  RM -. audit .-> AL
  SH -. audit .-> AL

  %% ====================
  %% PredictionAgent Details
  %% ====================
  PR -.-|"feature normalization (0-100)"| PR
  PR -.-|"observed-max guard"| PR
  PR -.-|"score output -> Pricing"| PC

  %% ====================
  %% Styling / Notes
  %% ====================
  classDef agent fill:#f9f,stroke:#333,stroke-width:1px;
  classDef engine fill:#9f9,stroke:#333,stroke-width:1px;
  classDef registry fill:#ff9,stroke:#333,stroke-width:1px;
  classDef telemetry fill:#9ff,stroke:#333,stroke-width:1px;

  class DP,FD,PR,PC agent;
  class AE,AS,RM,SH engine;
  class AB,AR,LV registry;
  class ML,AL telemetry;
```
