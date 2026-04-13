param(
  [switch]$ProbeModels
)

$ErrorActionPreference = 'Stop'
$checks = [System.Collections.Generic.List[object]]::new()
$hasError = $false

function Add-Check {
  param(
    [string]$Name,
    [string]$Status,
    [string]$Detail
  )

  if ($Status -eq 'ERROR') {
    $script:hasError = $true
  }

  $script:checks.Add([pscustomobject]@{
    Check  = $Name
    Status = $Status
    Detail = $Detail
  }) | Out-Null
}

function Invoke-Capture {
  param(
    [string]$Command,
    [string[]]$Arguments = @()
  )

  $output = & $Command @Arguments 2>&1
  $exitCode = $LASTEXITCODE
  $text = (($output | ForEach-Object { "$_" }) -join [Environment]::NewLine).Trim()

  [pscustomobject]@{
    ExitCode = $exitCode
    Output   = $text
  }
}

function Resolve-OpenClaw {
  $cmdShim = Get-Command openclaw.cmd -ErrorAction SilentlyContinue
  if ($cmdShim) {
    return $cmdShim.Source
  }

  $direct = Get-Command openclaw -ErrorAction SilentlyContinue
  if ($direct) {
    return $direct.Source
  }

  $npmShim = Join-Path $env:APPDATA 'npm\openclaw.cmd'
  if (Test-Path $npmShim) {
    return $npmShim
  }

  return $null
}

function Check-Command {
  param(
    [string]$Name,
    [string]$VersionArg = '--version'
  )

  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $command) {
    Add-Check $Name 'ERROR' 'command not found'
    return $null
  }

  $result = Invoke-Capture -Command $command.Source -Arguments @($VersionArg)
  if ($result.ExitCode -ne 0) {
    Add-Check $Name 'ERROR' "installed but failed: $($result.Output)"
    return $command.Source
  }

  Add-Check $Name 'OK' $result.Output
  return $command.Source
}

$nodePath = Check-Command -Name 'node'
if ($nodePath) {
  try {
    $nodeVersionText = (Invoke-Capture -Command $nodePath -Arguments @('--version')).Output
    $nodeVersion = [version]($nodeVersionText.Trim().TrimStart('v'))
    if ($nodeVersion -lt [version]'22.14.0') {
      Add-Check 'node-version' 'ERROR' "Node $nodeVersion is too old; need 22.14+"
    } elseif ($nodeVersion.Major -ne 24) {
      Add-Check 'node-version' 'WARN' "Node $nodeVersion is supported, but Node 24 is recommended"
    } else {
      Add-Check 'node-version' 'OK' "Node $nodeVersion"
    }
  } catch {
    Add-Check 'node-version' 'WARN' 'unable to parse node version'
  }
}

$null = Check-Command -Name 'npm'

$openclawPath = Resolve-OpenClaw
if (-not $openclawPath) {
  Add-Check 'openclaw' 'ERROR' 'CLI not found; install via official installer or npm'
} else {
  $openclawVersion = Invoke-Capture -Command $openclawPath -Arguments @('--version')
  if ($openclawVersion.ExitCode -eq 0) {
    Add-Check 'openclaw' 'OK' $openclawVersion.Output
  } else {
    Add-Check 'openclaw' 'ERROR' $openclawVersion.Output
  }
}

$envFile = Join-Path $HOME '.openclaw\.env'
if (Test-Path $envFile) {
  Add-Check 'env-file' 'OK' $envFile
} else {
  Add-Check 'env-file' 'WARN' "missing $envFile"
}

$configFile = Join-Path $HOME '.openclaw\openclaw.json'
if (Test-Path $configFile) {
  Add-Check 'config-file' 'OK' $configFile
} else {
  Add-Check 'config-file' 'WARN' "missing $configFile"
}

if ($openclawPath) {
  $configPath = Invoke-Capture -Command $openclawPath -Arguments @('config', 'file')
  if ($configPath.ExitCode -eq 0) {
    Add-Check 'config-file-active' 'OK' $configPath.Output
  } else {
    Add-Check 'config-file-active' 'WARN' $configPath.Output
  }

  $doctor = Invoke-Capture -Command $openclawPath -Arguments @('doctor', '--non-interactive')
  if ($doctor.ExitCode -eq 0) {
    Add-Check 'doctor' 'OK' 'doctor completed without a hard failure'
  } else {
    Add-Check 'doctor' 'WARN' ($doctor.Output -replace '\s+', ' ').Trim()
  }

  $gatewayStatus = Invoke-Capture -Command $openclawPath -Arguments @('gateway', 'status')
  if ($gatewayStatus.ExitCode -eq 0) {
    Add-Check 'gateway-status' 'OK' ($gatewayStatus.Output -replace '\s+', ' ').Trim()
  } else {
    Add-Check 'gateway-status' 'WARN' ($gatewayStatus.Output -replace '\s+', ' ').Trim()
  }

  $health = Invoke-Capture -Command $openclawPath -Arguments @('health')
  if ($health.ExitCode -eq 0) {
    Add-Check 'health' 'OK' 'health command succeeded'
  } else {
    Add-Check 'health' 'WARN' ($health.Output -replace '\s+', ' ').Trim()
  }

  $models = Invoke-Capture -Command $openclawPath -Arguments @('models', 'status', '--plain')
  if ($models.ExitCode -eq 0) {
    Add-Check 'models-status' 'OK' 'models status available'
  } else {
    Add-Check 'models-status' 'WARN' ($models.Output -replace '\s+', ' ').Trim()
  }

  if ($ProbeModels) {
    $probe = Invoke-Capture -Command $openclawPath -Arguments @('models', 'status', '--probe')
    if ($probe.ExitCode -eq 0) {
      Add-Check 'models-probe' 'OK' 'live provider probe succeeded'
    } else {
      Add-Check 'models-probe' 'WARN' ($probe.Output -replace '\s+', ' ').Trim()
    }
  }
}

if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
  try {
    $portTest = Test-NetConnection 127.0.0.1 -Port 18789 -WarningAction SilentlyContinue
    if ($portTest.TcpTestSucceeded) {
      Add-Check 'port-18789' 'OK' '127.0.0.1:18789 reachable'
    } else {
      Add-Check 'port-18789' 'WARN' '127.0.0.1:18789 not reachable'
    }
  } catch {
    Add-Check 'port-18789' 'WARN' 'unable to test port 18789'
  }
}

$checks | Format-Table -AutoSize

if ($hasError) {
  exit 1
}
