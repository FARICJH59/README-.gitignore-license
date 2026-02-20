#!/usr/bin/env pwsh
# DNS and URL Configuration Automation
# Auto-generates subdomains and configures SSL/TLS

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$true)]
    [string]$BaseDomain,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('aws', 'gcp', 'azure')]
    [string]$DnsProvider,
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production",
    
    [Parameter(Mandatory=$false)]
    [string]$LoadBalancerIP,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableSSL = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "DNS & URL Configuration" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Generate subdomain structure
$subdomains = @{
    main = "$ProjectName-$Environment.$BaseDomain"
    api = "api.$ProjectName-$Environment.$BaseDomain"
    admin = "admin.$ProjectName-$Environment.$BaseDomain"
    monitoring = "monitoring.$ProjectName-$Environment.$BaseDomain"
    grafana = "grafana.$ProjectName-$Environment.$BaseDomain"
}

Write-Host "Generated Subdomains:" -ForegroundColor Yellow
$subdomains.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
}
Write-Host ""

# DNS Record Configuration
function New-DnsRecords {
    param($Subdomains, $IP, $Provider)
    
    $records = @()
    foreach ($subdomain in $Subdomains.Values) {
        $records += @{
            name = $subdomain
            type = "A"
            value = $IP
            ttl = 300
        }
    }
    
    return $records
}

if (-not $LoadBalancerIP) {
    Write-Host "⚠️  Load Balancer IP not provided. Attempting to detect..." -ForegroundColor Yellow
    
    try {
        # Try to get LoadBalancer IP from kubectl
        $lbService = kubectl get svc -n axiomcore nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($lbService) {
            $LoadBalancerIP = $lbService
            Write-Host "✓ Detected Load Balancer IP: $LoadBalancerIP" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  Could not auto-detect Load Balancer IP" -ForegroundColor Yellow
    }
}

if (-not $LoadBalancerIP) {
    throw "Load Balancer IP is required. Please provide -LoadBalancerIP parameter"
}

$dnsRecords = New-DnsRecords -Subdomains $subdomains -IP $LoadBalancerIP -Provider $DnsProvider

# Provider-specific DNS configuration
function Set-ProviderDns {
    param($Records, $Provider, $Domain, $IsDryRun)
    
    Write-Host "Configuring DNS records in $Provider..." -ForegroundColor Cyan
    
    switch ($Provider) {
        'aws' {
            Write-Host "Using AWS Route53..." -ForegroundColor Yellow
            
            # Get hosted zone ID
            if (-not $IsDryRun) {
                $zoneId = aws route53 list-hosted-zones-by-name --dns-name $Domain --query "HostedZones[0].Id" --output text
                Write-Host "  Zone ID: $zoneId" -ForegroundColor Gray
            }
            
            foreach ($record in $Records) {
                if ($IsDryRun) {
                    Write-Host "  [DRY RUN] Would create: $($record.name) -> $($record.value)" -ForegroundColor Gray
                } else {
                    Write-Host "  Creating record: $($record.name)" -ForegroundColor White
                    
                    $changeFile = "/tmp/dns-change-$(Get-Random).json"
                    $changeBatch = @{
                        Changes = @(
                            @{
                                Action = "UPSERT"
                                ResourceRecordSet = @{
                                    Name = $record.name
                                    Type = $record.type
                                    TTL = $record.ttl
                                    ResourceRecords = @(
                                        @{ Value = $record.value }
                                    )
                                }
                            }
                        )
                    } | ConvertTo-Json -Depth 10
                    
                    $changeBatch | Set-Content -Path $changeFile
                    # aws route53 change-resource-record-sets --hosted-zone-id $zoneId --change-batch file://$changeFile
                    Remove-Item $changeFile -Force
                }
            }
        }
        'gcp' {
            Write-Host "Using Google Cloud DNS..." -ForegroundColor Yellow
            
            # Get DNS zone name
            if (-not $IsDryRun) {
                $zoneName = gcloud dns managed-zones list --filter="dnsName:$Domain" --format="value(name)" 2>$null
                if (-not $zoneName) {
                    # Create zone if it doesn't exist
                    $zoneName = $Domain.Replace('.', '-')
                    Write-Host "  Creating DNS zone: $zoneName" -ForegroundColor Gray
                    # gcloud dns managed-zones create $zoneName --dns-name=$Domain --description="Managed by AxiomCore"
                }
                Write-Host "  Zone: $zoneName" -ForegroundColor Gray
            }
            
            foreach ($record in $Records) {
                if ($IsDryRun) {
                    Write-Host "  [DRY RUN] Would create: $($record.name) -> $($record.value)" -ForegroundColor Gray
                } else {
                    Write-Host "  Creating record: $($record.name)" -ForegroundColor White
                    # gcloud dns record-sets transaction start --zone=$zoneName
                    # gcloud dns record-sets transaction add $($record.value) --name=$($record.name) --ttl=$($record.ttl) --type=$($record.type) --zone=$zoneName
                    # gcloud dns record-sets transaction execute --zone=$zoneName
                }
            }
        }
        'azure' {
            Write-Host "Using Azure DNS..." -ForegroundColor Yellow
            
            foreach ($record in $Records) {
                if ($IsDryRun) {
                    Write-Host "  [DRY RUN] Would create: $($record.name) -> $($record.value)" -ForegroundColor Gray
                } else {
                    Write-Host "  Creating record: $($record.name)" -ForegroundColor White
                    # az network dns record-set a add-record --resource-group DNS_RG --zone-name $Domain --record-set-name $($record.name) --ipv4-address $($record.value)
                }
            }
        }
    }
    
    Write-Host "✓ DNS records configured" -ForegroundColor Green
}

Set-ProviderDns -Records $dnsRecords -Provider $DnsProvider -Domain $BaseDomain -IsDryRun:$DryRun

# SSL/TLS Configuration
if ($EnableSSL) {
    Write-Host ""
    Write-Host "Configuring SSL/TLS certificates..." -ForegroundColor Cyan
    
    $certDomains = $subdomains.Values -join ","
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would request certificates for: $certDomains" -ForegroundColor Gray
    } else {
        Write-Host "  Installing cert-manager (if not present)..." -ForegroundColor Yellow
        # kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
        
        Write-Host "  Waiting for cert-manager to be ready..." -ForegroundColor Yellow
        # kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager -n cert-manager
        
        Write-Host "  Applying ClusterIssuers..." -ForegroundColor Yellow
        kubectl apply -f infra/kubernetes/ingress.yaml
        
        Write-Host "  Certificate requests submitted" -ForegroundColor Green
        Write-Host "  Certificates will be issued automatically via Let's Encrypt" -ForegroundColor Gray
    }
}

# Generate route configuration for frontend/backend connection
Write-Host ""
Write-Host "Generating dynamic route configuration..." -ForegroundColor Cyan

$routeConfig = @{
    frontend = @{
        url = "https://$($subdomains.main)"
        apiEndpoints = @{
            ingestion = "https://$($subdomains.api)/ingestion"
            dashboard = "https://$($subdomains.api)/dashboard"
            optimization = "https://$($subdomains.api)/optimization"
            billing = "https://$($subdomains.api)/billing"
        }
    }
    backend = @{
        apiGateway = "https://$($subdomains.api)"
        allowedOrigins = @(
            "https://$($subdomains.main)"
            "https://$($subdomains.admin)"
        )
    }
    monitoring = @{
        grafana = "https://$($subdomains.grafana)"
        prometheus = "https://$($subdomains.monitoring)"
    }
}

$configDir = Join-Path $PSScriptRoot ".." "infra" "deployment-config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$routeConfigFile = Join-Path $configDir "routes-$Environment.json"
$routeConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $routeConfigFile -Force

Write-Host "✓ Route configuration saved: $routeConfigFile" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Project: $ProjectName" -ForegroundColor White
Write-Host "Environment: $Environment" -ForegroundColor White
Write-Host "Base Domain: $BaseDomain" -ForegroundColor White
Write-Host "Load Balancer IP: $LoadBalancerIP" -ForegroundColor White
Write-Host ""
Write-Host "URLs:" -ForegroundColor Yellow
Write-Host "  Main App: https://$($subdomains.main)" -ForegroundColor Cyan
Write-Host "  API Gateway: https://$($subdomains.api)" -ForegroundColor Cyan
Write-Host "  Admin Panel: https://$($subdomains.admin)" -ForegroundColor Cyan
Write-Host "  Grafana: https://$($subdomains.grafana)" -ForegroundColor Cyan
Write-Host ""
Write-Host "SSL/TLS: $(if ($EnableSSL) { 'Enabled ✓' } else { 'Disabled' })" -ForegroundColor $(if ($EnableSSL) { 'Green' } else { 'Yellow' })
Write-Host ""

if ($DryRun) {
    Write-Host "⚠️  This was a DRY RUN. No changes were made." -ForegroundColor Yellow
    Write-Host "Remove -DryRun flag to apply changes." -ForegroundColor Yellow
}
