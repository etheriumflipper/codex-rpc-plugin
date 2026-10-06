param([string]$Ref = 'HEAD')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $root 'scripts/check.ps1')
$version = (Get-Content (Join-Path $root 'plugins/codex-rpc/plugin.json') -Raw | ConvertFrom-Json).version
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$zip = Join-Path $dist "codex-rpc-plugin-$version.zip"
git -C $root archive --format=zip "--output=$zip" $Ref
if ($LASTEXITCODE -ne 0) { throw 'git archive failed.' }
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $dist 'SHA256SUMS'), "$hash  $(Split-Path $zip -Leaf)`n", [Text.UTF8Encoding]::new($false))
Write-Output "Release archive: $zip"
Write-Output "SHA256: $hash"
