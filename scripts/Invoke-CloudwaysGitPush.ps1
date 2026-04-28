param(
    [Parameter(Mandatory)][string]$SshHost,
    [Parameter(Mandatory)][int]$SshPort,
    [Parameter(Mandatory)][string]$AppPath,
    [string]$User = "master"
)

$scriptPath = Join-Path $PSScriptRoot "server-git-push.sh"
if (-not (Test-Path $scriptPath)) { throw "Missing $scriptPath" }

$bash = Get-Content -Raw -LiteralPath $scriptPath
# bash-safe single-quoted string
$escapedPath = $AppPath -replace "'", "'\''"
$stdin = "export APP_PATH='$escapedPath'`n$bash"

Write-Host "SSH $User@${SshHost}:$SshPort" -ForegroundColor Cyan
Write-Host "APP_PATH=$AppPath" -ForegroundColor Gray

$stdin | ssh -p $SshPort "${User}@${SshHost}" "bash -s"
