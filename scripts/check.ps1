$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$plugin = Join-Path $root 'plugins/codex-rpc'
$manifest = Get-Content (Join-Path $plugin 'plugin.json') -Raw | ConvertFrom-Json
$legacy = Get-Content (Join-Path $plugin '.codex-plugin/plugin.json') -Raw | ConvertFrom-Json
$market = Get-Content (Join-Path $root '.agents/plugins/marketplace.json') -Raw | ConvertFrom-Json
$pin = Get-Content (Join-Path $plugin 'runtime.json') -Raw | ConvertFrom-Json
if ($manifest.name -ne $legacy.name -or $manifest.version -ne $legacy.version) { throw 'Manifest versions do not match.' }
if ($market.plugins[0].source.path -ne './plugins/codex-rpc') { throw 'Marketplace path mismatch.' }
if (-not (Test-Path (Join-Path $plugin 'skills/presence/SKILL.md'))) { throw 'Missing skill.' }
if ($pin.sha256 -notmatch '^[a-f0-9]{64}$' -or $pin.url -ne "https://github.com/$($pin.repository)/releases/download/v$($pin.version)/$($pin.asset)") { throw 'Invalid pinned runtime.' }
foreach ($file in Get-ChildItem $root -Filter '*.ps1' -Recurse -File) {
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) { throw ($errors | Out-String) }
}
& (Join-Path $root 'tests/lifecycle.ps1')
Write-Output "PASS: manifests, marketplace, pinned runtime, PowerShell syntax and offline lifecycle tests ($($manifest.version))."
