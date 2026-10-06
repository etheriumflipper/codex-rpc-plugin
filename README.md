# Codex RPC plugin

Show the Codex logo, detected model and elapsed time in Discord, managed from a Codex plugin. **Windows x64 / Discord Desktop.** No API key, Discord token or Developer Portal setup needed.

This community plugin wraps [Inerthel's Codex RPC](https://github.com/inerthel-agi/codex-rpc) **v0.5.1**. The upstream tray app does model detection and Discord IPC; this repository supplies plugin packaging, a skill, verified installation and lifecycle controls. It is not an OpenAI or Discord product.

## Install in Codex

Open the plugin directory, choose **Add plugin marketplace**, and enter:

```text
etheriumflipper/codex-rpc-plugin
```

Install **Codex RPC** from that marketplace. In a new chat, select the plugin and say:

> Enable Codex RPC in Discord with model and time.

The agent downloads the pinned 9.9 MB portable runtime, checks SHA-256 and starts it in the tray. Existing RPC preferences are retained. For a clean model/time card, ask: **Apply minimal Codex RPC settings**. Click the tray icon for the upstream settings GUI. Installing a plugin alone does not start a background process.

For CLI marketplace registration:

```powershell
codex plugin marketplace add etheriumflipper/codex-rpc-plugin
```

Then install the plugin from the Codex plugin directory. See [OpenAI plugin packaging documentation](https://developers.openai.com/plugins/build/plugins) for marketplace support by surface.

## Commands

Ask the plugin to **start**, **check status**, **stop**, **apply minimal settings**, or **uninstall the RPC runtime**. Scripts can also run directly from a cloned/extracted package:

```powershell
& './plugins/codex-rpc/scripts/rpc.ps1' -Action start
& './plugins/codex-rpc/scripts/rpc.ps1' -Action status
& './plugins/codex-rpc/scripts/rpc.ps1' -Action stop
```

Available actions: `install`, `start`, `status`, `stop`, `minimal`, `uninstall`. `install` only downloads. `status` is read-only. `stop` targets only the exact executable installed by this plugin; another copy is never killed. If another copy is running, quit it first. `uninstall` preserves settings and other installs. Disable autostart in the upstream GUI if you enabled it, and stop the tray app before removing the plugin.

## What is shared

Fresh-install defaults show model/time, hide usage/credits/plan/effort/Fast mode and remove buttons. **Upstream v0.5.1 can still display the current project folder name in the details line.** It cannot be hidden by the minimal preset. Do not use this runtime if that name must remain private.

The upstream runtime reads local Codex configuration and session records to determine activity, and sends presence fields through Discord's local IPC. This wrapper does not read Codex auth or sessions, does not request credentials, and contacts GitHub only to download a pinned release. It does not modify Codex configuration or host permissions. Runtime preferences live in `%LOCALAPPDATA%\codex-rich-presence`; the pinned executable lives in `%LOCALAPPDATA%\codex-rpc-plugin\runtime\0.5.1`.

## Limitations and verification

- Model detection follows the most recently active local session; it is not guaranteed to match the focused chat when several sessions run.
- Before a new turn, upstream may use model defaults from config.toml.
- The status report distinguishes a process from a fresh runtime connection report. Discord connection is not visual proof that another user sees the correct card.
- Discord Desktop must be open with activity sharing enabled. A manual registered-game activity may compete with RPC; disable that entry if necessary.
- WebView2 is required by the tray GUI. The wrapper does not install system runtimes or bypass PowerShell policy.
- Runtime autostart is opt-in in its GUI. Plugin uninstall cannot automatically stop an independent tray process.
- First release supports Windows x64 only; macOS/Linux are not implemented in this wrapper.

Run checks with PowerShell:

```powershell
& './scripts/check.ps1'
```

The offline suite checks read-only status, visibility defaults, settings preservation, corrupt binary rejection and scoped uninstall. A release check also downloads and verifies the upstream binary. Live Discord acceptance must be recorded separately.

## License

MIT for the plugin wrapper. The downloaded runtime remains copyright **2026 Inerthel**, MIT; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Binaries are downloaded from the upstream tagged release rather than bundled or rebranded.
