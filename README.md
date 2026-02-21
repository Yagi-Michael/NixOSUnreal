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

### Zed / Other IDEs

Any IDE or tool that launches UnrealEditor directly will need these same flags passed as program arguments. Consult your IDE's run/debug configuration for where to set them.

### Memory Limits

A cgroup memory limit wrapper is available in `scripts/unreal/run.nix` (commented out) if NixOS earlyoom/OOM isn't catching runaway memory fast enough.

## Known Issues

- **Wayland:** Popup keyboard input may not work. Run `kde-wayland-settings` for workaround info.
- **X11 forced:** The FHS env sets `GDK_BACKEND=x11`, `QT_QPA_PLATFORM=xcb`, `SDL_VIDEODRIVER=x11`.
- **Perforce permissions:** P4 doesn't preserve Unix execute bits. See chmod notes in build steps above.

---

Originally forked from [Adrastie/NixOSUnreal](https://github.com/Adrastie/NixOSUnreal).
