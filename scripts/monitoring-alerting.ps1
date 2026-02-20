#!/usr/bin/env pwsh
# Monitoring and Alerting System
# Captures logs, metrics, and telemetry with auto-redeploy capabilities

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('setup', 'monitor', 'alert', 'redeploy')]
    [string]$Action = "monitor",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "axiomcore",
    
    [Parameter(Mandatory=$false)]
    [int]$CheckInterval = 60,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoRedeploy,
    
    [Parameter(Mandatory=$false)]
    [switch]$Continuous
)

$ErrorActionPreference = "Stop"

$monitoringDir = Join-Path $PSScriptRoot ".." ".brain"
$metricsFile = Join-Path $monitoringDir "metrics.json"
$alertsFile = Join-Path $monitoringDir "alerts.json"
$iotTelemetryFile = Join-Path $monitoringDir "iot-telemetry.json"

# Ensure directories exist
if (-not (Test-Path $monitoringDir)) {
    New-Item -ItemType Directory -Path $monitoringDir -Force | Out-Null
}

# Initialize metrics database
function Initialize-Metrics {
    if (-not (Test-Path $metricsFile)) {
        $initialMetrics = @{
            lastUpdated = Get-Date -Format "o"
            services = @{}
            ml = @{
                models = @()
                predictions = @()
                accuracy = @{}
            }
            iot = @{
                devices = @()
                events = @()
                telemetry = @{}
            }
        }
        $initialMetrics | ConvertTo-Json -Depth 10 | Set-Content -Path $metricsFile -Force
    }
}

# Initialize alerts database
function Initialize-Alerts {
    if (-not (Test-Path $alertsFile)) {
        $initialAlerts = @{
            lastChecked = Get-Date -Format "o"
            active = @()
            resolved = @()
            rules = @(
                @{
                    name = "high-cpu-usage"
                    condition = "cpu > 80"
                    severity = "warning"
                    action = "notify"
                }
                @{
                    name = "high-memory-usage"
                    condition = "memory > 85"
                    severity = "warning"
                    action = "notify"
                }
                @{
                    name = "pod-restart"
                    condition = "restarts > 5"
                    severity = "critical"
                    action = "redeploy"
                }
                @{
                    name = "api-error-rate"
                    condition = "error_rate > 5"
                    severity = "critical"
                    action = "alert"
                }
                @{
                    name = "ml-accuracy-drop"
                    condition = "accuracy < 0.85"
                    severity = "warning"
                    action = "retrain"
                }
            )
        }
        $initialAlerts | ConvertTo-Json -Depth 10 | Set-Content -Path $alertsFile -Force
    }
}

# Collect service metrics
function Get-ServiceMetrics {
    param($Namespace)
    
    Write-Host "Collecting service metrics..." -ForegroundColor Cyan
    
    $metrics = @{
        timestamp = Get-Date -Format "o"
        pods = @()
        nodes = @()
    }
    
    try {
        # Get pod metrics
        $podsJson = kubectl get pods -n $Namespace -o json 2>$null
        if ($podsJson) {
            $pods = $podsJson | ConvertFrom-Json
            
            foreach ($pod in $pods.items) {
                $podMetrics = @{
                    name = $pod.metadata.name
                    status = $pod.status.phase
                    restarts = ($pod.status.containerStatuses | Measure-Object -Property restartCount -Sum).Sum
                    ready = ($pod.status.conditions | Where-Object { $_.type -eq 'Ready' }).status
                    age = ((Get-Date) - [DateTime]$pod.metadata.creationTimestamp).TotalHours
                }
                
                # Try to get resource usage
                try {
                    $topData = kubectl top pod $pod.metadata.name -n $Namespace 2>$null
                    if ($topData) {
                        $parts = $topData -split '\s+'
                        if ($parts.Count -ge 3) {
                            $podMetrics.cpu = $parts[1]
                            $podMetrics.memory = $parts[2]
                        }
                    }
                } catch {
                    # Metrics server might not be available
                    $podMetrics.cpu = "N/A"
                    $podMetrics.memory = "N/A"
                }
                
                $metrics.pods += $podMetrics
            }
        }
        
        # Get node metrics
        $nodesJson = kubectl get nodes -o json 2>$null
        if ($nodesJson) {
            $nodes = $nodesJson | ConvertFrom-Json
            
            foreach ($node in $nodes.items) {
                $nodeMetrics = @{
                    name = $node.metadata.name
                    status = ($node.status.conditions | Where-Object { $_.type -eq 'Ready' }).status
                    allocatable = @{
                        cpu = $node.status.allocatable.cpu
                        memory = $node.status.allocatable.memory
                    }
                }
                
                $metrics.nodes += $nodeMetrics
            }
        }
    } catch {
        Write-Host "⚠️  Could not collect all metrics: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    return $metrics
}

# Collect ML metrics
function Get-MLMetrics {
    Write-Host "Collecting ML metrics..." -ForegroundColor Cyan
    
    $mlMetrics = @{
        timestamp = Get-Date -Format "o"
        models = @()
    }
    
    # Check for ML service pods
    try {
        $mlPods = kubectl get pods -n axiomcore -l component=ml -o json 2>$null | ConvertFrom-Json
        
        foreach ($pod in $mlPods.items) {
            # TODO: Query the ML service API for actual metrics
            # This is a placeholder structure for ML metrics
            # In production, replace with actual API calls to ML service
            $modelMetric = @{
                name = $pod.metadata.name
                status = $pod.status.phase
                lastInference = Get-Date -Format "o"
                inferenceCount = 0
                averageLatency = 0
                accuracy = 0.0  # Placeholder - query from ML service API
            }
            
            $mlMetrics.models += $modelMetric
        }
    } catch {
        Write-Host "⚠️  ML metrics not available" -ForegroundColor Yellow
    }
    
    return $mlMetrics
}

# Collect IoT telemetry
function Get-IoTTelemetry {
    Write-Host "Collecting IoT telemetry..." -ForegroundColor Cyan
    
    $iotMetrics = @{
        timestamp = Get-Date -Format "o"
        devices = @()
        events = @()
    }
    
    # Check for IoT ingestion service
    try {
        $iotPods = kubectl get pods -n axiomcore -l app=api-ingestion -o json 2>$null | ConvertFrom-Json
        
        foreach ($pod in $iotPods.items) {
            # In a real implementation, query the ingestion service API
            $deviceMetric = @{
                pod = $pod.metadata.name
                status = $pod.status.phase
                connectedDevices = 0
                eventsProcessed = 0
                lastEvent = Get-Date -Format "o"
            }
            
            $iotMetrics.devices += $deviceMetric
        }
    } catch {
        Write-Host "⚠️  IoT telemetry not available" -ForegroundColor Yellow
    }
    
    return $iotMetrics
}

# Check alert rules
function Test-AlertRules {
    param($Metrics, $MLMetrics, $IoTMetrics)
    
    Write-Host "Checking alert rules..." -ForegroundColor Cyan
    
    $alerts = Get-Content $alertsFile | ConvertFrom-Json
    $triggeredAlerts = @()
    
    # Check pod restarts
    foreach ($pod in $Metrics.pods) {
        if ($pod.restarts -gt 5) {
            $triggeredAlerts += @{
                rule = "pod-restart"
                severity = "critical"
                message = "Pod $($pod.name) has restarted $($pod.restarts) times"
                action = "redeploy"
                timestamp = Get-Date -Format "o"
                pod = $pod.name
            }
        }
    }
    
    # Check ML model accuracy
    foreach ($model in $MLMetrics.models) {
        if ($model.accuracy -lt 0.85) {
            $triggeredAlerts += @{
                rule = "ml-accuracy-drop"
                severity = "warning"
                message = "ML model $($model.name) accuracy dropped to $($model.accuracy)"
                action = "retrain"
                timestamp = Get-Date -Format "o"
                model = $model.name
            }
        }
    }
    
    # Check pod status
    foreach ($pod in $Metrics.pods) {
        if ($pod.status -ne 'Running' -and $pod.status -ne 'Succeeded') {
            $triggeredAlerts += @{
                rule = "pod-not-running"
                severity = "critical"
                message = "Pod $($pod.name) is in $($pod.status) state"
                action = "investigate"
                timestamp = Get-Date -Format "o"
                pod = $pod.name
            }
        }
    }
    
    return $triggeredAlerts
}

# Send alert notification
function Send-AlertNotification {
    param($Alert)
    
    $severityColor = switch ($Alert.severity) {
        'critical' { 'Red' }
        'warning' { 'Yellow' }
        default { 'White' }
    }
    
    Write-Host ""
    Write-Host "🚨 ALERT TRIGGERED 🚨" -ForegroundColor $severityColor
    Write-Host "Rule: $($Alert.rule)" -ForegroundColor White
    Write-Host "Severity: $($Alert.severity)" -ForegroundColor $severityColor
    Write-Host "Message: $($Alert.message)" -ForegroundColor White
    Write-Host "Action: $($Alert.action)" -ForegroundColor Yellow
    Write-Host "Time: $($Alert.timestamp)" -ForegroundColor Gray
    Write-Host ""
    
    # In a real implementation, send to Slack, PagerDuty, email, etc.
}

# Auto-redeploy service
function Invoke-AutoRedeploy {
    param($PodName, $Namespace)
    
    Write-Host "Auto-redeploying pod: $PodName" -ForegroundColor Yellow
    
    try {
        # Delete the pod to trigger recreation
        kubectl delete pod $PodName -n $Namespace
        Write-Host "✓ Pod deleted. Kubernetes will recreate it automatically." -ForegroundColor Green
        
        # Wait for new pod to be ready
        Start-Sleep -Seconds 10
        
        $newPods = kubectl get pods -n $Namespace -o json | ConvertFrom-Json
        $appLabel = $PodName -replace '-[^-]+-[^-]+$', ''
        $newPod = $newPods.items | Where-Object { $_.metadata.name -like "$appLabel*" } | Select-Object -First 1
        
        if ($newPod) {
            Write-Host "✓ New pod: $($newPod.metadata.name)" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Auto-redeploy failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main monitoring loop
function Start-MonitoringLoop {
    param($Namespace, $Interval, $AutoRedeploy, $Continuous)
    
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Monitoring System Started" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Namespace: $Namespace" -ForegroundColor White
    Write-Host "Check Interval: $Interval seconds" -ForegroundColor White
    Write-Host "Auto-Redeploy: $(if ($AutoRedeploy) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($AutoRedeploy) { 'Green' } else { 'Yellow' })
    Write-Host "Continuous: $(if ($Continuous) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host ""
    
    do {
        $startTime = Get-Date
        
        # Collect metrics
        $serviceMetrics = Get-ServiceMetrics -Namespace $Namespace
        $mlMetrics = Get-MLMetrics
        $iotMetrics = Get-IoTTelemetry
        
        # Save metrics
        $allMetrics = @{
            timestamp = Get-Date -Format "o"
            services = $serviceMetrics
            ml = $mlMetrics
            iot = $iotMetrics
        }
        $allMetrics | ConvertTo-Json -Depth 10 | Set-Content -Path $metricsFile -Force
        
        # Check alerts
        $triggeredAlerts = Test-AlertRules -Metrics $serviceMetrics -MLMetrics $mlMetrics -IoTMetrics $iotMetrics
        
        # Process alerts
        foreach ($alert in $triggeredAlerts) {
            Send-AlertNotification -Alert $alert
            
            if ($AutoRedeploy -and $alert.action -eq 'redeploy' -and $alert.pod) {
                Invoke-AutoRedeploy -PodName $alert.pod -Namespace $Namespace
            }
        }
        
        # Update alerts file
        $alertsData = Get-Content $alertsFile | ConvertFrom-Json
        $alertsData.lastChecked = Get-Date -Format "o"
        $alertsData.active = $triggeredAlerts
        $alertsData | ConvertTo-Json -Depth 10 | Set-Content -Path $alertsFile -Force
        
        # Summary
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Check completed - Pods: $($serviceMetrics.pods.Count) | Alerts: $($triggeredAlerts.Count)" -ForegroundColor Cyan
        
        if ($Continuous) {
            $elapsed = ((Get-Date) - $startTime).TotalSeconds
            $sleepTime = [Math]::Max(0, $Interval - $elapsed)
            if ($sleepTime -gt 0) {
                Start-Sleep -Seconds $sleepTime
            }
        }
        
    } while ($Continuous)
}

# Execute action
switch ($Action) {
    'setup' {
        Write-Host "Setting up monitoring system..." -ForegroundColor Cyan
        Initialize-Metrics
        Initialize-Alerts
        Write-Host "✓ Monitoring system initialized" -ForegroundColor Green
    }
    
    'monitor' {
        Initialize-Metrics
        Initialize-Alerts
        Start-MonitoringLoop -Namespace $Namespace -Interval $CheckInterval -AutoRedeploy:$AutoRedeploy -Continuous:$Continuous
    }
    
    'alert' {
        $alerts = Get-Content $alertsFile | ConvertFrom-Json
        Write-Host "Active Alerts: $($alerts.active.Count)" -ForegroundColor Yellow
        foreach ($alert in $alerts.active) {
            Send-AlertNotification -Alert $alert
        }
    }
    
    'redeploy' {
        Write-Host "Manual redeploy requested" -ForegroundColor Yellow
        # Implementation would be similar to auto-redeploy
    }
}
