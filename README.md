# gUbGuuB NixOS Unreal Dev Env


---

NixOS FHS flake/develop env for Unreal Engine.

---


# Usage:

## Build Unreal Engine from sources:
1. You must have access to Ascent Perforce (Unreal Engine source is included in the depot)
2. Pull from Ascent Perforce. If following along with your own depot, you can use `git clone git@github.com:EpicGames/UnrealEngine.git --branch release --single-branch`
3. Inside the `UE/` folder, run `git clone git@github.com:Yagi-Michael/NixOSUnreal.git flake`
4. `cd flake && nix develop`
5. `unreal-fhs`
6. `cd ..`
   - **Note:** Perforce doesn't preserve Unix execute permissions. You may need to run:
     `chmod +x Setup.sh GenerateProjectFiles.sh Engine/Binaries/DotNET/GitDependencies/linux-x64/GitDependencies`
7. `./Setup.sh`
8. `./GenerateProjectFiles.sh`
   - **Note:** You may need to fix permissions on engine build scripts first:
     `find Engine/Build -name "*.sh" -exec chmod +x {} +`
9. `make -j1` we must use `-j1`
10. Once compiled you will find the binary at `Engine/Binaries/Linux/UnrealEditor`

#### Example structure:
```
UE
├── AscentRivals       (game project)
├── Engine             (engine source)
├── flake <---|        Put flake here
├── Setup.sh
└── GenerateProjectFiles.sh
```

## Daily Workflow

```bash
cd UE/flake && nix develop   # enter nix shell (sets up PATH, env vars)
unreal-fhs                   # enter FHS sandbox (GPU, Vulkan, libs)
run-unreal                   # launch UnrealEditor (auto-detects Vulkan/OpenGL)
```

### Available Commands

| Command | Description |
|---------|-------------|
| `unreal-fhs` | Enter the FHS environment with all system deps |
| `run-unreal [path] [args]` | Launch UnrealEditor (defaults to `../Engine/Binaries/Linux/UnrealEditor`) |
| `run-rider` | Launch Rider IDE inside the FHS environment |
| `vulkan-test` | Quick Vulkan sanity check |
| `vulkan-diag` | Detailed Vulkan diagnostics |
| `kill-unreal` | Kill running Unreal processes |
| `kde-wayland-settings` | Wayland keyboard input workaround info |
| `refresh-env` | Re-detect GPU and refresh environment variables |
| `toggle-engine-debug-symbols` | Move engine `.debug` files in/out of `debug-stash/` to control LLDB memory usage |
| `gen-compile-commands` | Generate `compile_commands.json` from UBT for clangd intellisense |
| `run-zed` | Launch Zed editor inside the FHS environment |

## Perforce on NixOS

The `p4` CLI is included in the FHS environment, so it's available inside `unreal-fhs` without any extra setup.

For Rider's Perforce integration to work, you also need `p4` installed at the **NixOS system level**, since Rider runs outside the FHS sandbox. Add it to your `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  p4
];
```

After every Perforce sync, you'll need to fix execute permissions since P4 doesn't preserve Unix file modes:

```bash
chmod +x Setup.sh GenerateProjectFiles.sh Engine/Binaries/DotNET/GitDependencies/linux-x64/GitDependencies
find Engine/Build -name "*.sh" -exec chmod +x {} +
```

## Rider IDE Setup

When using JetBrains Rider on Linux, it may auto-detect the `.git` directory and default the VCS integration to Git. If your project uses Perforce:

1. Go to **Settings > Version Control > Directory Mappings**
2. Change the VCS for your project root (e.g. `/work/ascent`) from **Git** to **Perforce**
3. Go to **Settings > Version Control > Perforce** and set:
   - **Server (Port):** `ssl:genun.helixcore.io:1666`
   - **User:** your Perforce username
   - **Workspace (Client):** your Linux workspace name
   - **Path to P4 executable:** `/etc/profiles/per-user/<your-user>/bin/p4`
4. Click **Test Connection** to verify

## Debugging Stability

`run-unreal` automatically applies these flags: `-ansimalloc -reducethreadusage -limitedmemorypool`

These prevent mimalloc-related crashes and reduce memory pressure during debugging. However, IDEs launch their own UE process, so you must add the flags there too.

### Rider

1. **Run > Edit Configurations...**
2. Select your Uproject configuration (e.g. **AscentRivals**)
3. In the **Optional arguments** field, add: `-ansimalloc -reducethreadusage -limitedmemorypool`
4. Click **Apply**

### Zed

Debug flags are configured in `.zed/debug.json` (launch config `args` field). The existing launch config already includes the project path — add the stability flags there:

```json
"args": ["/work/ascent/UE/AscentRivals/AscentRivals.uproject", "-ansimalloc", "-reducethreadusage", "-limitedmemorypool"]
```

### Other IDEs

Any IDE or tool that launches UnrealEditor directly will need these same flags passed as program arguments. Consult your IDE's run/debug configuration for where to set them.

### Memory Limits

A cgroup memory limit wrapper is available in `scripts/unreal/run.nix` (commented out) if NixOS earlyoom/OOM isn't catching runaway memory fast enough.

## Zed IDE Setup (WIP)

Zed uses clangd for C++ intellisense, which needs a `compile_commands.json` generated from UnrealBuildTool.

### First-Time Setup

```bash
cd UE/flake && nix develop
unreal-fhs
gen-compile-commands    # generates UE/compile_commands.json (takes a few minutes)
```

Then launch with:

```bash
run-zed                 # launches Zed inside FHS so clangd resolves all paths
```

Project-level settings live in `.zed/settings.json` (already configured to point clangd at `UE/compile_commands.json`). Debug configs are in `.zed/debug.json` with CodeLLDB attach/launch targets and LLDB lazy symbol loading enabled.

Re-run `gen-compile-commands` after adding new source files or modules so clangd picks them up.

### Zed vs Rider — When to Use Which

| | Zed | Rider |
|---|---|---|
| **Strengths** | Fast startup, low RAM (~500MB vs Rider's 4-8GB), responsive on large codebases, native Linux feel, keyboard-driven workflow | Full UE integration (Blueprints, asset browser, UBT build), mature debugger UI, Perforce UI, refactoring tools |
| **Best for** | C++ editing & navigation, quick code changes, lightweight debugging sessions, working alongside UE editor | Full project work (code + assets + Blueprints), heavy debugging with watch/conditional breakpoints, Perforce operations |
| **Weaknesses** | No Blueprint support, no UE asset integration, clangd can be slow on initial index, less polished debugger UI | Heavy RAM usage (4-8GB+), slow startup, can feel sluggish with large engine codebase |
| **Debugging** | CodeLLDB (DAP) — functional but minimal UI | Full LLDB integration with inline values, conditional breakpoints, memory views |
| **Intellisense** | clangd (needs `gen-compile-commands` first, re-run when adding files) | Built-in via ReSharper C++ (works automatically with `.uproject`) |

**Recommendation:** Use Zed for day-to-day C++ editing when you mostly need fast navigation and quick edits. Switch to Rider for debugging sessions that need conditional breakpoints, Blueprint work, or Perforce operations.

### Claude Code Integration

A PostToolUse hook (`.claude/hooks/open-in-zed.sh`) automatically opens files in Zed as Claude Code edits them. Configured in `.claude/settings.local.json` (not committed — local machine preference).

**Workflow:**
1. `run-zed` to launch Zed
2. Split the editor right (`Ctrl+K, Ctrl+\`), click in the right pane
3. `Alt+C` to spawn Claude Code in the bottom terminal panel
4. As Claude edits files, they open in the last-focused editor pane

**Limitation:** Zed's CLI (`zeditor -a`) has no `--pane` flag to target a specific split pane. Files open in whichever pane was last focused. Click the right pane to redirect. Zed is open source (MIT, Rust) — adding a `--pane` flag is a future contribution opportunity. Relevant code: `crates/cli/src/main.rs`, `crates/workspace/src/pane.rs`, `crates/zed/src/open_listener.rs`.

**Zed tasks** (`.zed/tasks.json`): `Alt+C` runs Claude Code, "Enter FHS" available from command palette.

## Known Issues

- **Wayland:** Popup keyboard input may not work. Run `kde-wayland-settings` for workaround info.
- **X11 forced:** The FHS env sets `GDK_BACKEND=x11`, `QT_QPA_PLATFORM=xcb`, `SDL_VIDEODRIVER=x11`.
- **Perforce permissions:** P4 doesn't preserve Unix execute bits. See chmod notes in build steps above.

---

Originally forked from [Adrastie/NixOSUnreal](https://github.com/Adrastie/NixOSUnreal).
