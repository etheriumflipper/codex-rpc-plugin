# Verification for 0.1.0

Verified on Windows on 2026-10-06:

- Codex CLI accepted the local Git marketplace and installed `codex-rpc@etheriumflipper-rpc`, version 0.1.0, into its plugin cache.
- Plugin manifests/marketplace paths parse correctly; all PowerShell scripts pass parser checks.
- Eight offline lifecycle assertions pass: read-only absent status, visibility defaults, settings preservation, corrupted runtime refusal and scoped uninstall.
- Downloaded upstream 0.5.1 portable EXE matches the pinned SHA-256 in runtime.json.
- Plugin-managed runtime launched, produced a fresh status file with `Discord: Connected`, `presence=live`, and detected `GPT-6.1-Sol - Low`.
- A repeated start kept the same PID. Another running installation caused an explicit refusal, without stopping it.
- Stop waits for actual process exit before reporting status. The pre-existing upstream installation was restored after the smoke test.

These checks prove packaging, lifecycle behavior and a live Discord RPC connection. They do **not** prove the card's exact visual appearance or another user's view; that requires looking at the Discord profile. No screenshot of the rendered card was captured. GitHub CI results and published release validation are recorded in release notes.
