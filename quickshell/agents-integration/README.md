# Ukishima with native Agents

Ukishima is installed and running on Hyprland. The Agents icon, card and toasts
are native Quickshell/QML. Lost Island's GTK application is not installed.

CLI hook settings are **not yet installed**: user approval was requested and is
pending. Claude Code and Copilot are absent from PATH; installing their current
official binaries also awaits approval. Codex CLI 0.169.0 is installed.

## Use

- Meta+I opens/closes the Agents card. The Agents icon also opens it in the
  collapsed and expanded pill.
- One common icon aggregates all sessions: waiting (amber `!`) takes priority
  over working (spinning `◌`), then done (green check). Idle means no sessions.
- The Agents card lists CLI, project, state and current action. Click the session
  text to focus its terminal and close the card.
- Launch Claude, Codex or Copilot from the card, or run
  `island-agent claude`, `island-agent codex`, or `island-agent copilot` in an
  existing terminal. CLI arguments may follow, e.g. `island-agent codex resume`.
- Missing binaries produce a clear notification rather than opening a broken
  terminal. Launching does not install a CLI or sign in.

## The settings change awaiting approval

Review the exact generated additions:

- `~/.local/share/quickshell/ukishima/agents/proposed/claude-hooks.json`
  merges hooks into `~/.claude/settings.json`.
- `~/.local/share/quickshell/ukishima/agents/proposed/codex-hooks.json`
  merges hooks into `~/.codex/hooks.json`.
- `~/.local/share/quickshell/ukishima/agents/proposed/copilot-hooks.json`
  becomes `~/.copilot/hooks/ukishima-agents.json`.

Existing values, authentication, permission policies and other hooks are
preserved. The installer backs up each target immediately before writing it.
A status-only option keeps PermissionRequest observation but never offers
approval buttons or waits for a decision.

After explicit approval, the prepared command is:

```bash
python ~/.local/share/quickshell/ukishima/agents/configure-hooks.py --apply
```

For status only, append `--status-only`. This command has **not** been run.
Codex separately requires you to review and trust these exact hooks with
`/hooks`. The integration does not trust hooks for you. Restart the CLIs after
installation/trust so their startup configuration loads the new hooks.

## Permission behavior

A synchronous PermissionRequest hook reports the request. If the Quickshell UI
is connected, the card offers Deny and Allow once for up to 20 seconds. Full tool
arguments are scrollable in the card before you decide. Only the Allow/Deny
button's `onClicked` handler sends a decision. There is no approval CLI command,
no automatic allow rule, and no timer that grants approval.

The broker verifies the UI helper is a direct child of Quickshell, the hook is
still alive, the request id matches, and the request has not expired or already
been answered. An ordinary hook/socket client cannot send a decision.

No click, expired request, hook cancellation, UI disconnection, stopped broker,
or transport failure returns no decision. Normal CLI permission handling then
continues. This can delay the ordinary prompt by at most 20 seconds. Existing
CLI policies still apply: commands already allowed by a CLI's own configuration
will not acquire new prompts simply because status hooks were installed.

For Claude and Codex the response uses `hookSpecificOutput.decision`; for
Copilot it uses its native top-level `behavior`. Deny does not save permanent
rules, and Allow is for the current request only.

## Current-doc capability matrix and limits

| CLI | Status hooks | Pill approvals | Limits |
| --- | --- | --- | --- |
| Claude Code | SessionStart/End, UserPromptSubmit, Pre/PostToolUse, Notification, Stop/Failure, PreCompact | PermissionRequest | Sandboxed network prompts may only produce a Notification; use the terminal for those. Questions and plan confirmation stay in the terminal. |
| Codex CLI 0.169.0 | SessionStart/End, UserPromptSubmit, Pre/PostToolUse, Stop, Interrupt, PreCompact | PermissionRequest | `/hooks` trust required. Hosted/specialized tools may not emit local tool hooks. Shared or remote servers do not expose terminal identity in hook payloads. |
| GitHub Copilot CLI | sessionStart/End, userPromptSubmitted, pre/postToolUse, agentStop, notification, errorOccurred | permissionRequest | This event fires before the CLI checks its own permission rules, so it can appear for requests the CLI would otherwise allow. Sandbox-bypass requests must still be confirmed in the terminal; no pill decision is offered for them. Sandboxing may prevent user hooks from reaching the local socket. |

All three current official docs have hooks, so no terminal-output scraping or
idle-time guessing is used as a status source. Older CLI versions with fewer
hooks may omit states; their ordinary terminal prompts remain usable. The
actual Claude/Copilot version and real authenticated operations cannot be
verified until installation is approved and the tools are available.

Codex's shared app-server is detached from the terminal. The pill launcher and
`island-agent codex` start a dedicated local Unix-socket server under that
terminal, then attach the TUI with `--remote`. The private endpoint and server
are removed when the TUI exits. This uses experimental documented app-server
CLI interfaces and was startup-tested against installed 0.169.0. It makes PID
ancestry deterministic without changing Codex settings or the existing daemon.
For a Codex launched directly into a shared/remote daemon, or a detached tmux /
SSH terminal, status can work while terminal focus cannot be resolved reliably.
The card reports that limitation rather than guessing another terminal.

Only sessions started after hook installation/trust are observed; restarting
the shell/broker clears its in-memory list until the next hook event. SessionEnd
removes a row; dead owner processes are also pruned. Existing sessions are not
attached by reading their transcripts. A remote/hosted CLI cannot talk to this
machine's local UI without an additional transport, which is not installed.

## Common session format

The Python standard-library broker normalizes a small adapter per CLI into:

```json
{
  "id": "codex:<session_id>",
  "cli": "codex",
  "name": "Codex CLI",
  "project": "my-project",
  "cwd": "/path/to/my-project",
  "status": "working",
  "action": "Run tests",
  "pid": 1234,
  "pid_start": "linux-process-start-ticks",
  "updated": 1794680000.0,
  "permission": null
}
```

`status` is working/waiting/done; SessionEnd removes the record. A live permission
adds `{id, expires, detail}` to `permission`. The aggregate snapshot is
`{schema: 1, revision, status, sessions, toasts}`. CLI namespaced ids prevent
collisions; processes are checked by PID plus start time to avoid PID reuse.
The socket lives under `$XDG_RUNTIME_DIR/ukishima-agents/` (directory 0700,
socket 0600) and checks the caller UID. State and request arguments stay in
memory; prompts and transcripts are not copied into a new history file.

## Installed files and startup

- Application: `~/.local/share/quickshell/ukishima`, upstream commit
  `d04d8e1575bf0f7fc42922df7dca1ee9ac3a4027`, with a local Agents customization.
- New QML: `Singletons/Agents.qml`, `components/AgentChip.qml`,
  `surfaces/AgentsSurface.qml`; small registry/IPC additions in Pill.qml,
  Singletons/qmldir and shell.qml.
- Broker, adapters, launchers, proposed hooks and tests: application `agents/`.
- User units: `~/.config/systemd/user/ukishima{,-agents,-wallpaper}.service`.
  The Hyprland startup script imports the current compositor environment and
  starts the shell once. These services are not enabled for all desktop sessions.
- Hyprland: `~/.config/hypr/session-start.sh` gets that startup line;
  `hyprland.lua` gets Meta+I. Meta+T and Meta+W remain terminal/browser.
- `~/.local/bin/island-agent` points to the terminal launcher.
- `~/.local/state/ukishima/` and `~/.cache/ukishima/` hold normal shell state/cache.
- awww runs alongside the shell and uses the original Sonoma wallpaper. swaybg
  remains underneath as the original fallback. Neither is a second pill UI.
- Installed system packages: quickshell 0.3.2-1, awww 0.12.1-1; pacman also added
  cpptrace and libdwarf dependencies. Other required base dependencies already
  existed. Optional mpvpaper, matugen and hyprlock were not installed.

The modified checkout is protected from the upstream updater: it is kept on a
local branch with local changes/commits. Do not force an upstream installer or
uninstaller over it. Update by reviewing and merging upstream while retaining
the Agents patch. `.config` only allowlists the three specific new service files.

## Tests completed

- 22 isolated unit tests: all three adapters, state precedence and namespacing,
  questions/notifications, decision response contracts, status-only mode,
  concurrent requests, wrong ids, replay, timeout, dead/disconnected hook,
  no UI, rejection of forged UI/decision connections, and settings merging with
  preservation of existing hooks and the original recovery copy.
- Live QML: empty card and three fixture sessions, scrollable request details,
  Allow/Deny controls and countdown. Fixtures were removed afterwards; they did
  not call a model or execute tools.
- A native notification toast was visually checked on this desktop.
- Live Hyprland terminal focus by process ancestry passed; previous focus restored.
- Codex dedicated endpoint startup/help and endpoint/process cleanup passed.
- Ukishima dependency check passed for required tools; shell/broker lifecycle
  startup and shutdown were checked. User systemd units and Hyprland Lua parse.
- CLI settings are unchanged. Real authenticated runs and an actual human click
  resolving a CLI prompt remain pending; no real approval was generated by tests.
- Only the internal monitor is connected; multi-monitor behavior is untested.

Logs:

```bash
journalctl --user -u ukishima -u ukishima-agents -u ukishima-wallpaper -n 60
```

Repeat unit tests:

```bash
python -m unittest discover -s ~/.local/share/quickshell/ukishima/agents/tests -v
```

## Backups and undo

Before changes, original files were copied and verified under:

`/home/azhaar/.local/state/ukishima-agents-backups/20261115-021322`

This private directory includes the exact originals, an existence manifest,
starting Git commit, the changed-path list and an undo script. The CLI installer
would additionally back up the current CLI targets immediately before changes,
only if you approve installation.

Preview recovery without changing anything:

```bash
bash ~/.config/quickshell/agents-integration/undo.sh --check
```

Undo the integration (keeps your terminals and Hyprland session open):

```bash
bash ~/.config/quickshell/agents-integration/undo.sh
```

The script stops the three shell services, moves this setup aside in the private
backup directory, restores only the recorded originals, reloads systemd and
Hyprland, and restores CLI files only if our hook installer actually changed
them. Displaced current files are retained, including any later edits. Packages
and Git history are retained. If you also want to remove the two newly installed
applications, use `sudo pacman -R quickshell awww` after undoing their startup.
Research source checkouts under `~/.local/share/hypr-agents-sources` are retained
as reference copies; they do not start any service.

## Credits and current sources

Ukishima by amanhex is the base; its MIT license and Ricelin/Gakuseei and
Chaldea/Aleph1-9012 credits remain intact. The event-to-state mapping and
PID-ancestry approach were adapted from Lost Island for Archcraft Sway by
byte4day, based on Lost Island by Marco Zorn. Its complete MIT notice is kept in
`agents/LICENSE-Lost-Island` (2026 Marco Zorn; 2026 byte4day modifications).
Reference Lost Island commit: `aaa8cbafa8fa05e4448de6d05814c8a301097289`.
No external GTK island or automatic tool-approval component is running.

- https://github.com/amanhex/Ukishima
- https://github.com/byte4day/lost-island-archcraft-sway
- https://code.claude.com/docs/en/hooks
- https://learn.chatgpt.com/docs/hooks
- https://docs.github.com/en/copilot/reference/hooks-reference
- Installed `codex --help`, `codex app-server --help`, and `codex features list`
  were checked against the actual 0.169.0 binary.
