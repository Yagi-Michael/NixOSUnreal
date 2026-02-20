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

---

Warning: If you are using Wayland with the Unreal Engine, the Popup keyboard input may not work at all. To find more information and an unsecured but unavoidable workaround, run “kde-wayland-settings”.


---

Originally forked from [Adrastie/NixOSUnreal](https://github.com/Adrastie/NixOSUnreal).
