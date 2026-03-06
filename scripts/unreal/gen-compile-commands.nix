{ pkgs, lib, utils }:

pkgs.writeScriptBin "gen-compile-commands" ''
  #!${pkgs.stdenv.shell}
  ${lib.banners.colorTheWorld}

  # Relative paths — expects to be run from UE/flake/
  UE_ROOT="$(cd .. && pwd)"
  UBT="$UE_ROOT/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll"
  OUTPUT_DIR="$UE_ROOT"

  if ! command -v dotnet &> /dev/null; then
    print_error "dotnet not found — run this inside unreal-fhs"
    exit 1
  fi

  if [ ! -f "$UBT" ]; then
    print_error "UnrealBuildTool not found: $UBT"
    print_error "Build the engine first (make -j1)"
    exit 1
  fi

  # Auto-detect .uproject file (find the first one that isn't in Engine/)
  PROJECT=$(find "$UE_ROOT" -maxdepth 2 -name "*.uproject" ! -path "*/Engine/*" 2>/dev/null | head -1)
  if [ -z "$PROJECT" ] || [ ! -f "$PROJECT" ]; then
    print_error "No .uproject file found under $UE_ROOT"
    exit 1
  fi

  PROJECT_NAME=$(basename "$PROJECT" .uproject)
  TARGET="''${PROJECT_NAME}Editor"

  print_banner "Generating compile_commands.json"
  print_info "Target: $TARGET (Development, Linux)"
  print_info "Project: $PROJECT"
  print_info "Output: $OUTPUT_DIR/compile_commands.json"
  echo ""

  cd "$UE_ROOT"
  dotnet "$UBT" \
    -Mode=GenerateClangDatabase \
    -Project="$PROJECT" \
    "$TARGET" \
    Linux \
    Development \
    -OutputDir="$OUTPUT_DIR"

  if [ -f "$OUTPUT_DIR/compile_commands.json" ]; then
    print_success "Generated compile_commands.json"
    print_info "clangd will use this for intellisense in Zed / any LSP-based editor"
  else
    print_error "compile_commands.json was not created"
    exit 1
  fi
''
