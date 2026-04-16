param(
  [string]$EnvFile = $(Join-Path (Split-Path -Parent $PSScriptRoot) '.env')
)

$ErrorActionPreference = 'Stop'

function Invoke-Native {
  param(
    [string]$Command,
    [string[]]$Arguments = @(),
    [switch]$AllowFailure
  )

  & $Command @Arguments
  $exitCode = $LASTEXITCODE

  if (-not $AllowFailure -and $exitCode -ne 0) {
    throw "$Command $($Arguments -join ' ') failed with exit code $exitCode"
  }

  return $exitCode
}

function Test-IsAdmin {
  $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($currentUser)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-NodeToPath {
  $paths = @(
    'C:\Program Files\nodejs',
    (Join-Path $env:APPDATA 'npm')
  )

  foreach ($path in $paths) {
    if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) {
      $env:PATH = "$path;$env:PATH"
    }
  }
}

function Test-NodeOk {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    return $false
  }

  try {
    $major = [int]((& $node.Source -p "Number(process.versions.node.split('.')[0])"))
    return $major -ge 22
  } catch {
    return $false
  }
}

if (-not (Test-IsAdmin)) {
  throw 'Please run this script from Administrator PowerShell.'
}

Add-NodeToPath

if (-not (Test-NodeOk)) {
  Invoke-Native 'winget' @(
    'install',
    'OpenJS.NodeJS.LTS',
    '--accept-package-agreements',
    '--accept-source-agreements'
  )
  Add-NodeToPath
}

if (-not (Test-Path $EnvFile)) {
  throw "env file not found: $EnvFile"
}

Invoke-Native 'npm' @('install', '-g', 'openclaw@latest')
Invoke-Native 'node' @((Join-Path $PSScriptRoot 'apply-openclaw-config.mjs'), '--env-file', $EnvFile)

$gatewayInstallExit = Invoke-Native 'openclaw' @('gateway', 'install') -AllowFailure
if ($gatewayInstallExit -ne 0) {
  Write-Host 'gateway install skipped or already installed; continuing'
}

$gatewayStartExit = Invoke-Native 'openclaw' @('gateway', 'start') -AllowFailure
if ($gatewayStartExit -ne 0) {
  Invoke-Native 'openclaw' @('gateway', 'restart')
}

Invoke-Native 'openclaw' @('gateway', 'status')
Invoke-Native 'openclaw' @('health', '--verbose')
Invoke-Native 'openclaw' @('dashboard')
