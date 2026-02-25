<#
.SYNOPSIS
    Test runner script with support for dry-run mode (PowerShell version)

.DESCRIPTION
    A PowerShell wrapper for running Python tests with various options including dry-run mode

.EXAMPLE
    .\run_tests.ps1
    Run all tests

.EXAMPLE
    .\run_tests.ps1 -DryRun
    Show what tests would be run without executing them (dry mode)

.EXAMPLE
    .\run_tests.ps1 -Marker unit
    Run only unit tests

.EXAMPLE
    .\run_tests.ps1 -Coverage
    Run tests with coverage report

.EXAMPLE
    .\run_tests.ps1 -DryRun -Marker unit
    Dry run for unit tests only
#>

param(
    [switch]$DryRun,
    [switch]$Collect,
    [string]$Marker,
    [switch]$Coverage,
    [switch]$Verbose,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$AdditionalArgs
)

# Build command arguments
$args = @()

if ($DryRun -or $Collect) {
    Write-Host "🔍 DRY RUN MODE: Collecting tests without execution`n" -ForegroundColor Cyan
    $args += "--dry-run"
}

if ($Marker) {
    $args += "-m", $Marker
}

if ($Coverage) {
    $args += "--cov"
}

if ($Verbose) {
    $args += "-v"
}

if ($AdditionalArgs) {
    $args += $AdditionalArgs
}

# Run the Python test runner
Write-Host "Running command: python run_tests.py $($args -join ' ')`n" -ForegroundColor Green

try {
    & python run_tests.py @args
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "`n✅ Test execution completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Test execution failed with exit code: $exitCode" -ForegroundColor Red
    }

    exit $exitCode
} catch {
    Write-Host "`n❌ Error running tests: $_" -ForegroundColor Red
    exit 1
}
