[CmdletBinding()]
param(
    [ValidateSet('install','start','stop','status','minimal','uninstall')]
    [string]$Action = 'status',
    [string]$DataRoot = $env:LOCALAPPDATA
)
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$pluginRoot = Split-Path -Parent $PSScriptRoot
$pin = Get-Content -LiteralPath (Join-Path $pluginRoot 'runtime.json') -Raw | ConvertFrom-Json
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Windows x64 is required.' }
if ([string]::IsNullOrWhiteSpace($DataRoot)) { throw 'LOCALAPPDATA is unavailable.' }
if (-not [Environment]::Is64BitOperatingSystem) { throw 'Windows x64 is required.' }
$base = [IO.Path]::GetFullPath($DataRoot)
$runtimeDir = Join-Path $base ('codex-rpc-plugin/runtime/' + $pin.version)
$exe = Join-Path $runtimeDir $pin.asset
$settingsDir = Join-Path $base 'codex-rich-presence'
$settingsPath = Join-Path $settingsDir 'rpc-buttons.json'
$statusPath = Join-Path $settingsDir 'status.txt'
$utf8 = [Text.UTF8Encoding]::new($false)

function Get-ManagedProcesses {
    @(Get-Process -Name 'codex-rich-presence' -ErrorAction SilentlyContinue | Where-Object {
        try { $_.Path -and [IO.Path]::GetFullPath($_.Path).Equals($exe, [StringComparison]::OrdinalIgnoreCase) } catch { $false }
    })
}
function Assert-Binary {
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Runtime is not installed.' }
    $hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
    if ($hash -ine $pin.sha256) { throw 'Runtime checksum mismatch; refusing to execute. Remove or reinstall the corrupted file.' }
}
function Stop-ManagedProcesses {
    foreach ($process in @(Get-ManagedProcesses)) {
        # Retain the process handle so the result cannot race a pending exit.
        $null = $process.Handle
        Stop-Process -InputObject $process
        if (-not $process.WaitForExit(5000)) { throw 'RPC did not exit within 5 seconds.' }
    }
}
function Set-MinimalSettings {
    $settings = @{}
    if (Test-Path -LiteralPath $settingsPath) {
        $obj = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
        foreach ($property in $obj.PSObject.Properties) { $settings[$property.Name] = $property.Value }
    }
    foreach ($key in @('show_primary_usage','show_weekly_usage','show_usage','show_effort','show_fast_mode','show_credits','show_plan','hide_model','notify_low','notify_reset','check_updates')) { $settings[$key] = $false }
    $settings.mode = 'playing'
    $settings.buttons = @()
    $settings.show_elapsed = $true
    $settings.custom_state = '{model}'
    $settings.paused_until_ms = 0
    if (-not $settings.ContainsKey('idle_clear_minutes')) { $settings.idle_clear_minutes = 0 }
    New-Item -ItemType Directory -Force $settingsDir | Out-Null
    $temp = $settingsPath + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::WriteAllText($temp, ($settings | ConvertTo-Json -Depth 10), $utf8)
        Move-Item -LiteralPath $temp -Destination $settingsPath -Force
    } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp } }
}
function Install-Runtime {
    if (Test-Path -LiteralPath $exe) {
        Assert-Binary
        if (-not (Test-Path -LiteralPath $settingsPath)) { Set-MinimalSettings }
        return
    }
    New-Item -ItemType Directory -Force $runtimeDir | Out-Null
    $temp = Join-Path $runtimeDir ([Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $pin.url -OutFile $temp -UseBasicParsing
        if ((Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash -ine $pin.sha256) { throw 'Downloaded runtime checksum mismatch; refusing installation.' }
        Move-Item -LiteralPath $temp -Destination $exe
    } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp } }
    if (-not (Test-Path -LiteralPath $settingsPath)) { Set-MinimalSettings }
}
switch ($Action) {
    'install' { Install-Runtime }
    'minimal' { Set-MinimalSettings }
    'start' {
        Install-Runtime
        Assert-Binary
        if (@(Get-ManagedProcesses).Count -eq 0) {
            $other = @(Get-Process -Name 'codex-rich-presence' -ErrorAction SilentlyContinue)
            if ($other.Count -gt 0) { throw 'Another Codex RPC install is running. Quit it in the tray before starting this plugin runtime.' }
            Start-Process -FilePath $exe -WorkingDirectory $runtimeDir -WindowStyle Hidden | Out-Null
            Start-Sleep -Milliseconds 1000
        }
    }
    'stop' { Stop-ManagedProcesses }
    'uninstall' {
        Stop-ManagedProcesses
        # Delete only the known file; never recurse through a computed directory.
        if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe }
        if ((Test-Path -LiteralPath $runtimeDir) -and @(Get-ChildItem -LiteralPath $runtimeDir -Force).Count -eq 0) { Remove-Item -LiteralPath $runtimeDir }
    }
}
$processes = @(Get-ManagedProcesses)
$result = [ordered]@{ action=$Action; runtime_version=$pin.version; installed=(Test-Path -LiteralPath $exe -PathType Leaf); running=($processes.Count -gt 0); pids=@($processes | ForEach-Object { $_.Id }); discord='unknown'; presence='unknown'; model=$null; status_fresh=$false }
if ($processes.Count -gt 0 -and (Test-Path -LiteralPath $statusPath)) {
    $file = Get-Item -LiteralPath $statusPath
    $age = ([DateTime]::UtcNow - $file.LastWriteTimeUtc).TotalSeconds
    $started = ($processes | Sort-Object StartTime | Select-Object -First 1).StartTime.ToUniversalTime()
    if ($age -ge 0 -and $age -le 30 -and $file.LastWriteTimeUtc -ge $started) {
        $parts = (Get-Content -LiteralPath $statusPath -Raw).Trim().Split('|')
        if ($parts.Count -ge 6) {
            $result.status_fresh = $true
            $result.model = $parts[1]
            $result.discord = $parts[3]
            $result.presence = $parts[5]
        }
    }
}
$result | ConvertTo-Json -Depth 5
