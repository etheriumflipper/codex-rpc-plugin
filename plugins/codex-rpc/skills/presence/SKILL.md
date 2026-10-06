---
name: presence
description: Install, start, stop or check Codex Discord Rich Presence on Windows when the user asks to show their Codex model, logo or elapsed time in Discord.
---

# Codex RPC

Use this workflow only for Codex Discord activity. Resolve the installed plugin root as two directories above this SKILL.md (skills/presence -> plugin root). Use its scripts/rpc.ps1 by absolute path. Windows x64 and Discord Desktop are required. This is a community wrapper around Inerthel's Codex RPC 0.5.1.

Installing the plugin does not download or start the runtime. When the user asks to enable it, run `rpc.ps1 -Action start`; this installs the pinned runtime if absent, checks its SHA-256 and launches it hidden in the tray. No Discord token, OpenAI key or Developer Portal application is needed.

Commands, from PowerShell:

```powershell
& '<PLUGIN_ROOT>/scripts/rpc.ps1' -Action start
& '<PLUGIN_ROOT>/scripts/rpc.ps1' -Action status
& '<PLUGIN_ROOT>/scripts/rpc.ps1' -Action stop
& '<PLUGIN_ROOT>/scripts/rpc.ps1' -Action install
& '<PLUGIN_ROOT>/scripts/rpc.ps1' -Action minimal
& '<PLUGIN_ROOT>/scripts/rpc.ps1' -Action uninstall
```

Only `start` launches the app. `install` downloads only; `minimal` applies logo/model/time defaults, preserving unrelated settings; `status` is read-only. `stop` stops only the exact plugin-managed executable. `uninstall` removes that pinned executable and its empty version folder, preserving upstream settings and other installs. Do not remove the user's Codex files.

Report the JSON result. After start, allow at least 10 seconds and check status. `running` proves only a process exists. `discord` and `presence` come from the runtime's local status file; never claim visible delivery from a launch alone. Stale status is not live evidence. If Discord is disconnected, ask the user to open Discord Desktop and enable activity sharing, then recheck. Do not read auth.json, send session transcripts or request user tokens.

Defaults show the model and elapsed time; usage, credits, plan, effort and Fast mode are hidden. Buttons are disabled. Upstream v0.5.1 can include the project folder name in its details line; minimal settings do not remove it. Tell the user this before first start. Existing upstream settings are preserved on install; use minimal only when requested. To customize other fields, the user opens the tray settings. Autostart is opt-in through the upstream tray GUI, never enabled silently. Disabling/removing the plugin does not automatically stop a separately running tray app; stop it first.

The upstream runtime detects the most recently active local session, not necessarily the chat currently focused. It may fall back to config.toml before a new turn. Do not promise exact focused-chat tracking.
