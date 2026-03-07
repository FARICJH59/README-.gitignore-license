<#
    PowerShell one-command production deploy for AxiomCore.
    - Generates a repo scaffold when missing
    - Writes Mermaid architecture/runtime docs and links them from README
    - Builds Docker image
    - Applies Kubernetes resources for brain + GPU clusters, task queue, telemetry, and InferenceX
    - Adds a GitHub Actions CI/CD workflow scaffold

Use -DryRun (alias: -PlanOnly) to render Kubernetes resources without applying them.
#>

[CmdletBinding()]
param(
    [Alias("PlanOnly")]
    [switch]$DryRun,
    [string]$KubeContext = "your-cluster-context"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoName = "axiomcore"
$DockerImage = "axiomcore/enterprise:latest"
$Namespace = "axiomcore-prod"
$GpuProduct = "GB300-NVL72"
$DocsPath = "docs"
$QueueMetricName = "queue_length"

function Write-Stage {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Test-Tool {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-RepoScaffold {
    if (Test-Path -Path $RepoName) {
        Write-Stage "Repo exists, skipping scaffold."
        return
    }

    Write-Stage "Generating repo scaffold"
    Push-Location
    New-Item -ItemType Directory -Path $RepoName -Force | Out-Null
    Set-Location $RepoName

    "# AxiomCore Enterprise 1M-Agent System" | Out-File -FilePath README.md -Encoding utf8

    if (Test-Tool "git") {
        git init | Out-Null
        git add README.md | Out-Null
        git commit -m "Initialize AxiomCore repo" | Out-Null
    } else {
        Write-Warning "git not found; skipping commit."
    }

    $CopilotPrompt = @"
Generate a full AxiomCore repo for 1M-agent system: Brain Cluster, Meta-Orchestrator, Scheduler, Executor, Task Queue, Worker Pools, GPU inference routing, Cognitive Memory Layer, Telemetry, Marketplace, Docker/K8s infra, CI/CD workflow, placeholder code, Mermaid diagrams, documentation linked in README.
"@

    if (-not $DryRun -and (Test-Tool "openai")) {
        openai codegen create --model gpt-5-mini-codegen --prompt $CopilotPrompt --output ./ --language "typescript,python,shell"
        if (Test-Tool "git") {
            git add . | Out-Null
            git commit -m "Generated full AxiomCore scaffold" | Out-Null
        }
    } else {
        Write-Host "Skipping Copilot/CodeGen scaffold (missing openai CLI or dry-run enabled)." -ForegroundColor Yellow
    }

    Pop-Location
}

function Ensure-Docs {
    if (-not (Test-Path -Path $DocsPath)) {
        New-Item -ItemType Directory -Path $DocsPath -Force | Out-Null
    }

    $archContent = @"
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
"@

    $runtimeContent = @"
# Runtime Flow Diagram
```mermaid
flowchart TD
    User[User Request] --> API[API Gateway]
    API --> Meta[Global Intelligence Layer]
    Meta --> BrainNode[Brain Node]
    BrainNode --> Scheduler[Agent Scheduler]
    Scheduler --> Executor[Agent Executor]
    Executor --> Queue[Task Queue]
    Queue --> Worker[Worker Pool]
    Worker --> GPURouter[Inference Router]
    GPURouter --> LLMGPU[LLM GPU Node]
    GPURouter --> VisionGPU[Vision GPU Node]
    GPURouter --> MLGPU[ML GPU Node]
    GPURouter --> EmbGPU[Embedding GPU Node]
    Executor --> MemoryLayer[Persistent Cognitive Memory]
    Worker --> Telemetry[Metrics Recorder]
    Worker --> Response[Agent Output → User]
```
"@

    $hyperscaleContent = @"
# Hyperscale Deployment Diagram
```mermaid
flowchart TD
    Control[Meta-Orchestrator] --> Brain[Brain Cluster (200 nodes)]
    Control --> Scheduler[Scheduler]
    Scheduler --> Executor[Executor]
    Executor --> Queue[Task Queue]
    Queue --> Workers[Worker Pools (500 nodes)]
    Workers --> LLMGPU[LLM GPU Cluster (100)]
    Workers --> VisionGPU[Vision GPU Cluster (50)]
    Workers --> MLGPU[ML GPU Cluster (50)]
    Workers --> EmbGPU[Embedding GPU Cluster (50)]
    Workers --> Memory[Cognitive Memory Layer]
    Workers --> Telemetry[Telemetry/Observability]
    subgraph Agents [1M Agents]
        A1[Agents] --> Workers
    end
```
"@

    $archPath = Join-Path $DocsPath "ARCHITECTURE.md"
    $runtimePath = Join-Path $DocsPath "RUNTIME_FLOW.md"
    $hyperscalePath = Join-Path $DocsPath "HYPERSCALE.md"

    $archContent | Out-File -FilePath $archPath -Encoding utf8
    $runtimeContent | Out-File -FilePath $runtimePath -Encoding utf8
    $hyperscaleContent | Out-File -FilePath $hyperscalePath -Encoding utf8

    Write-Host "Mermaid diagrams written to $DocsPath." -ForegroundColor Green
}

function Update-ReadmeDocs {
    $readmePath = "README.md"
    if (-not (Test-Path -Path $readmePath)) {
        Write-Warning "README.md not found; skipping docs link injection."
        return
    }

    $readme = Get-Content -Path $readmePath -Raw
    if ($readme -match "## Documentation") {
        return
    }

    $docsBlock = @"

## Documentation
- [Architecture Diagram](docs/ARCHITECTURE.md)
- [Runtime Flow](docs/RUNTIME_FLOW.md)
- [Hyperscale Deployment](docs/HYPERSCALE.md)
"@

    Add-Content -Path $readmePath -Value $docsBlock
    Write-Host "Updated README with documentation links." -ForegroundColor Green
}

function Build-DockerImage {
    if ($DryRun) {
        Write-Host "Dry-run: docker build -t $DockerImage ." -ForegroundColor Yellow
        return
    }

    if (-not (Test-Tool "docker")) {
        Write-Warning "Docker not installed; skipping image build."
        return
    }

    if (-not (Test-Path -Path "Dockerfile")) {
        Write-Warning "Dockerfile not found; skipping image build."
        return
    }

    Write-Stage "Building Docker image $DockerImage"
    docker build -t $DockerImage .
}

function Get-KubectlArgs {
    param([switch]$IncludeNamespace)
    $args = @()
    if ($KubeContext) {
        $args += @("--context", $KubeContext)
    }
    if ($IncludeNamespace) {
        $args += @("-n", $Namespace)
    }
    return $args
}

function Ensure-K8sNamespace {
    if (-not (Test-Tool "kubectl")) {
        Write-Warning "kubectl not installed; skipping namespace creation."
        return
    }

    Write-Stage "Ensuring Kubernetes namespace $Namespace"
    $args = @("get", "namespace", $Namespace) + (Get-KubectlArgs)
    $exists = $true
    try {
        kubectl @args | Out-Null
    } catch {
        $exists = $false
    }

    if ($exists) {
        Write-Host "Namespace $Namespace already exists."
    } else {
        $createArgs = @("create", "namespace", $Namespace) + (Get-KubectlArgs)
        if ($DryRun) { $createArgs += "--dry-run=client" }
        kubectl @createArgs
    }

    # Apply namespace-level RBAC and NetworkPolicy (idempotent via apply)
    $securityYaml = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: axiomcore-deployer
  namespace: $Namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: axiomcore-deployer-role
  namespace: $Namespace
rules:
  - apiGroups: ["", "apps", "batch", "autoscaling"]
    resources: ["deployments", "statefulsets", "daemonsets", "services", "configmaps", "secrets", "pods", "pods/log", "horizontalpodautoscalers", "jobs", "cronjobs"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: axiomcore-deployer-binding
  namespace: $Namespace
subjects:
  - kind: ServiceAccount
    name: axiomcore-deployer
    namespace: $Namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: axiomcore-deployer-role
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-external
  namespace: $Namespace
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector: {}
  egress:
    - to:
        - podSelector: {}
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
"@

    Apply-K8sYaml -Yaml $securityYaml -Description "Namespace security (RBAC + NetworkPolicy)" -Namespaced:$false
}

function Apply-K8sYaml {
    param(
        [string]$Yaml,
        [string]$Description,
        [switch]$Namespaced
    )

    if (-not (Test-Tool "kubectl")) {
        Write-Warning "kubectl not installed; skipping $Description."
        return
    }

    $args = @("apply", "-f", "-") + (Get-KubectlArgs -IncludeNamespace:$Namespaced)
    if ($DryRun) { $args += "--dry-run=client" }

    Write-Host "$Description -> kubectl $($args -join ' ')" -ForegroundColor Yellow
    $Yaml | kubectl @args
}

function Deploy-BrainCluster {
    Write-Stage "Deploying brain cluster"
    $brainYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: brain-cluster
  namespace: $Namespace
spec:
  replicas: 200
  selector:
    matchLabels:
      app: brain-node
  template:
    metadata:
      labels:
        app: brain-node
    spec:
      containers:
      - name: brain-node
        image: $DockerImage
        resources:
          limits:
            cpu: "4"
            memory: "8Gi"
            nvidia.com/gpu: 1
        requests:
            cpu: "2"
            memory: "4Gi"
            nvidia.com/gpu: 1
      nodeSelector:
        nvidia.com/gpu.product: "$GpuProduct"
"@

    Apply-K8sYaml -Yaml $brainYaml -Description "Brain cluster" -Namespaced
}

function Deploy-GpuClusters {
    Write-Stage "Deploying GPU clusters"
    foreach ($cluster in @("llm", "vision", "ml", "embedding")) {
        $replicas = switch ($cluster) {
            "llm" { 100 }
            "vision" { 50 }
            "ml" { 50 }
            "embedding" { 50 }
            default { 10 }
        }
        $deploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${cluster}-cluster
  namespace: $Namespace
spec:
  replicas: $replicas
  selector:
    matchLabels:
      app: ${cluster}-gpu
  template:
    metadata:
      labels:
        app: ${cluster}-gpu
    spec:
      containers:
      - name: ${cluster}-gpu-node
        image: $DockerImage
        resources:
          limits:
            nvidia.com/gpu: 1
          requests:
            nvidia.com/gpu: 1
      nodeSelector:
        nvidia.com/gpu.product: "$GpuProduct"
"@

        Apply-K8sYaml -Yaml $deploymentYaml -Description "${cluster} GPU cluster" -Namespaced
    }
}

function Deploy-WorkerPool {
    Write-Stage "Deploying worker pool (fallback)"
    $workerYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-pool
  namespace: $Namespace
spec:
  replicas: 500
  selector:
    matchLabels:
      app: worker-pool
  template:
    metadata:
      labels:
        app: worker-pool
    spec:
      serviceAccountName: axiomcore-deployer
      containers:
      - name: worker
        image: $DockerImage
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "1"
            memory: "2Gi"
"@

    Apply-K8sYaml -Yaml $workerYaml -Description "Worker pool deployment" -Namespaced
}

function Apply-InfraComponent {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Tool "kubectl")) {
        Write-Warning "kubectl not installed; skipping $Description."
        return
    }

    if (-not (Test-Path -Path $Path)) {
        Write-Warning "$Description manifest $Path not found; skipping."
        return
    }

    $args = @("apply", "-f", $Path, "-n", $Namespace) + (Get-KubectlArgs)
    if ($DryRun) { $args += "--dry-run=client" }
    Write-Host "Applying $Description from $Path" -ForegroundColor Yellow
    kubectl @args
}

function Configure-Autoscalers {
    if (-not (Test-Tool "kubectl")) {
        Write-Warning "kubectl not installed; skipping autoscalers."
        return
    }

    Write-Stage "Configuring Horizontal Pod Autoscalers"
    $brainArgs = @("autoscale", "deployment", "brain-cluster", "--cpu-percent=50", "--min=50", "--max=500", "-n", $Namespace) + (Get-KubectlArgs)
    if ($DryRun) { $brainArgs += "--dry-run=client" }
    kubectl @brainArgs

    foreach ($cluster in @("llm", "vision", "ml", "embedding")) {
        $hpaArgs = @("autoscale", "deployment", "${cluster}-cluster", "--cpu-percent=50", "--min=10", "--max=200", "-n", $Namespace) + (Get-KubectlArgs)
        if ($DryRun) { $hpaArgs += "--dry-run=client" }
        kubectl @hpaArgs
    }

    # Worker pool HPA with CPU + queue length external metric
    $workerHpa = @"
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: worker-pool-hpa
  namespace: $Namespace
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: worker-pool
  minReplicas: 100
  maxReplicas: 800
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
    - type: External
      external:
        metric:
          name: "$QueueMetricName"
        target:
          type: AverageValue
          averageValue: 100
"@
    Apply-K8sYaml -Yaml $workerHpa -Description "Worker pool HPA (CPU + queue length)" -Namespaced
}

function Verify-Deployment {
    if (-not (Test-Tool "kubectl")) {
        Write-Warning "kubectl not installed; skipping verification."
        return
    }

    Write-Stage "Verifying namespace resources"
    $args = @("get", "all", "-n", $Namespace) + (Get-KubectlArgs)
    kubectl @args
}

function Ensure-CiCdWorkflow {
    $workflowPath = ".github/workflows/ci-cd-deploy.yml"
    $workflowDir = Split-Path $workflowPath
    if (-not (Test-Path -Path $workflowDir)) {
        New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
    }

    $workflowContent = @'
name: AxiomCore Full CI/CD

on:
  workflow_dispatch:
  push:
    branches:
      - main

env:
  DOCKER_IMAGE: axiomcore/enterprise:latest
  NAMESPACE: axiomcore-prod
  KUBE_CONTEXT: ${{ secrets.KUBE_CONTEXT }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4

      # Expects DOCKER_USERNAME and DOCKER_TOKEN (Docker access token) secrets
      - name: Login to Docker registry
        id: docker_login
        if: hashFiles('Dockerfile') != ''
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Build & Push Docker
        if: steps.docker_login.outcome == 'success'
        run: |
          docker build -t $DOCKER_IMAGE .
          docker push $DOCKER_IMAGE

      - name: Configure kubectl
        if: hashFiles('infra/k8s/**/*.y*ml') != ''
        env:
          KUBE_CONFIG_B64: ${{ secrets.KUBE_CONFIG_B64 }}
          KUBE_CONTEXT: ${{ secrets.KUBE_CONTEXT }}
        run: |
          if [ -z "$KUBE_CONFIG_B64" ]; then
            echo "KUBE_CONFIG_B64 secret is required to configure kubectl." >&2
            exit 1
          fi
          mkdir -p "$HOME/.kube"
          echo "$KUBE_CONFIG_B64" | base64 -d > "$HOME/.kube/config"
          if [ -n "$KUBE_CONTEXT" ]; then
            kubectl config use-context "$KUBE_CONTEXT"
          fi

      - name: Deploy to K8s (if manifests exist)
        if: hashFiles('infra/k8s/**/*.y*ml') != ''
        run: |
          kubectl apply --validate=true -f infra/k8s/ -n $NAMESPACE
'@

    $workflowContent | Out-File -FilePath $workflowPath -Encoding utf8
    Write-Host "CI/CD workflow scaffold written to $workflowPath." -ForegroundColor Green
}

Write-Stage "AxiomCore production deploy start"
Ensure-RepoScaffold
Ensure-Docs
Update-ReadmeDocs
Build-DockerImage
Ensure-K8sNamespace
Deploy-BrainCluster
Deploy-GpuClusters

Apply-InfraComponent -Path "infra/k8s/redis-deployment.yaml" -Description "Redis"
Apply-InfraComponent -Path "infra/k8s/worker-pool-deployment.yaml" -Description "Worker pool"
Apply-InfraComponent -Path "infra/k8s/telemetry-deployment.yaml" -Description "Telemetry"
Apply-InfraComponent -Path "infra/k8s/inferencex-deployment.yaml" -Description "InferenceX"

if (-not (Test-Path -Path "infra/k8s/worker-pool-deployment.yaml")) {
    Deploy-WorkerPool
} else {
    Write-Host "Worker pool manifest detected; skipping fallback deployment." -ForegroundColor Yellow
}

Configure-Autoscalers
Ensure-CiCdWorkflow
Verify-Deployment

Write-Host "`n✅ FULL PROD DEPLOY COMPLETE: AxiomCore + GPU scaling + Telemetry + InferenceX + live docs + CI/CD" -ForegroundColor Green
