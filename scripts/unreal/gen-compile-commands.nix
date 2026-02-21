{ pkgs, lib, utils }:

pkgs.writeScriptBin "gen-compile-commands" ''
  #!${pkgs.stdenv.shell}
  ${lib.banners.colorTheWorld}

  PROJECT="/work/ascent/UE/AscentRivals/AscentRivals.uproject"
  UBT="/work/ascent/UE/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll"
  OUTPUT_DIR="/work/ascent/UE"

  if [ ! -f "$UBT" ]; then
    print_error "UnrealBuildTool not found: $UBT"
    print_error "Build the engine first (make -j1)"
    exit 1
  fi

  if [ ! -f "$PROJECT" ]; then
    print_error "Project file not found: $PROJECT"
    exit 1
  fi

  print_banner "Generating compile_commands.json"
  print_info "Target: AscentRivalsEditor (Development, Linux)"
  print_info "Output: $OUTPUT_DIR/compile_commands.json"
  echo ""

  cd /work/ascent/UE
  dotnet "$UBT" \
    -Mode=GenerateClangDatabase \
    -TargetName=AscentRivalsEditor \
    -Platform=Linux \
    -Configuration=Development \
    -Project="$PROJECT" \
    -OutputDir="$OUTPUT_DIR"

  if [ -f "$OUTPUT_DIR/compile_commands.json" ]; then
    print_success "Generated compile_commands.json"
    print_info "clangd will use this for intellisense in Zed / any LSP-based editor"
  else
    print_error "compile_commands.json was not created"
    exit 1
  fi
''
