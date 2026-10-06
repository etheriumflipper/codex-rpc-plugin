$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$rpc = Join-Path $root 'plugins/codex-rpc/scripts/rpc.ps1'
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('codex-rpc-test-' + [Guid]::NewGuid().ToString('N'))
function Assert($condition, $message) { if (-not $condition) { throw $message } }
try {
    $state = & $rpc -Action status -DataRoot $scratch | ConvertFrom-Json
    Assert (-not $state.installed -and -not $state.running) 'Absent runtime should be reported.'
    Assert (-not (Test-Path $scratch)) 'Status must not create directories.'
    & $rpc -Action minimal -DataRoot $scratch | Out-Null
    $settingsPath = Join-Path $scratch 'codex-rich-presence/rpc-buttons.json'
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    Assert ($settings.custom_state -eq '{model}' -and $settings.show_elapsed -and -not $settings.hide_model) 'Model/time defaults failed.'
    Assert (-not $settings.show_weekly_usage -and -not $settings.show_primary_usage -and -not $settings.check_updates -and $settings.buttons.Count -eq 0) 'Visibility/pin defaults failed.'
    $settings | Add-Member -NotePropertyName future_option -NotePropertyValue 'preserve me'
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
    & $rpc -Action minimal -DataRoot $scratch | Out-Null
    Assert ((Get-Content $settingsPath -Raw | ConvertFrom-Json).future_option -eq 'preserve me') 'Unknown settings were lost.'
    $runtimeDir = Join-Path $scratch 'codex-rpc-plugin/runtime/0.5.1'
    New-Item -ItemType Directory -Force $runtimeDir | Out-Null
    [IO.File]::WriteAllText((Join-Path $runtimeDir 'codex-rich-presence.exe'), 'corrupt')
    $rejected = $false
    try { & $rpc -Action start -DataRoot $scratch | Out-Null } catch { $rejected = $_.Exception.Message -match 'checksum mismatch' }
    Assert $rejected 'Corrupted runtime was not rejected.'
    [IO.File]::WriteAllText((Join-Path $runtimeDir 'keep.txt'), 'unrelated')
    & $rpc -Action uninstall -DataRoot $scratch | Out-Null
    Assert ((Test-Path (Join-Path $runtimeDir 'keep.txt')) -and (Test-Path $settingsPath)) 'Uninstall deleted unrelated files/settings.'
    Assert (-not (Test-Path (Join-Path $runtimeDir 'codex-rich-presence.exe'))) 'Uninstall retained managed binary.'
    Write-Output 'PASS: 8 offline lifecycle assertions; no runtime execution or network.'
} finally {
    # The fixed test prefix and canonical temp parent are checked before recursive cleanup.
    $resolved = [IO.Path]::GetFullPath($scratch)
    $tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($tempParent, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'codex-rpc-test-*') { throw 'Unsafe test cleanup path.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
