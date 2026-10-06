# Changelog

## 0.1.1

- Removed the GitHub Actions workflow from the package so publishing main does not require additional OAuth workflow scope. Local checks remain available and pass.
- Verified Git-backed marketplace registration and release archive contents.

## 0.1.0

- Codex plugin manifests and Git-backed marketplace.
- Presence skill with install/start/status/stop/minimal/uninstall actions.
- Pinned upstream Codex RPC 0.5.1 with SHA-256 validation before installation and execution.
- Model/time preset with usage fields and buttons hidden, and automatic runtime update checks disabled for a new installation.
- Scoped lifecycle control that preserves other installations and user settings.
- Read-only status with freshness check; offline boundary tests.
- Windows x64 support. Upstream project-name visibility and recent-session model detection limitations documented.
