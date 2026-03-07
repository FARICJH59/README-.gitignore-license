# Architecture Diagram
```mermaid
flowchart TD
    Users --> API[API Gateway / Load Balancer]
    API --> GIL[Global Intelligence Layer (Meta-Orchestrator)]
    GIL --> BrainCluster[Brain Cluster (200 nodes)]
    BrainCluster --> Scheduler[Agent Scheduler]
    Scheduler --> Executor[Agent Executor]
    Executor --> TaskQueue[Task Queue]
    TaskQueue --> WorkerPool[Worker Pools]
    WorkerPool --> GPURouter[GPU-Aware Inference Router]
    GPURouter --> LLMCluster[LLM GPU Nodes]
    GPURouter --> VisionCluster[Vision GPU Nodes]
    GPURouter --> MLCluster[ML GPU Nodes]
    GPURouter --> EmbCluster[Embedding GPU Nodes]
    Executor --> MemoryLayer[Cognitive Memory]
    Executor --> Telemetry[Telemetry & Observability]
```
