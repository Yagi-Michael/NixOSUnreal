{ pkgs, lib, utils }:

pkgs.writeScriptBin "toggle-engine-debug-symbols" ''
  #!${pkgs.stdenv.shell}
  ${lib.banners.colorTheWorld}

  ENGINE_BIN="/work/ascent/UE/Engine/Binaries/Linux"
  STASH_DIR="$ENGINE_BIN/debug-stash"

  if [ ! -d "$ENGINE_BIN" ]; then
    print_error "Engine binaries directory not found: $ENGINE_BIN"
    exit 1
  fi

  # Count files in each location
  ACTIVE_COUNT=$(find "$ENGINE_BIN" -maxdepth 1 -name "*.debug" 2>/dev/null | wc -l)
  STASHED_COUNT=$(find "$STASH_DIR" -maxdepth 1 -name "*.debug" 2>/dev/null | wc -l)

  if [ "$ACTIVE_COUNT" -gt 0 ]; then
    print_banner "Stashing $ACTIVE_COUNT engine .debug files"
    print_warning "LLDB will NOT load engine debug symbols (saves ~20GB RAM)"
    mkdir -p "$STASH_DIR"
    mv "$ENGINE_BIN"/*.debug "$STASH_DIR/"
    print_success "Moved $ACTIVE_COUNT .debug files to debug-stash/"
  elif [ "$STASHED_COUNT" -gt 0 ]; then
    print_banner "Restoring $STASHED_COUNT engine .debug files"
    print_warning "LLDB will load full engine debug symbols (uses ~20GB+ RAM)"
    mv "$STASH_DIR"/*.debug "$ENGINE_BIN/"
    print_success "Restored $STASHED_COUNT .debug files from debug-stash/"
  else
    print_error "No .debug files found in either location"
    print_info "Active: $ENGINE_BIN/"
    print_info "Stash:  $STASH_DIR/"
    exit 1
  fi

  # Show current state
  FINAL_ACTIVE=$(find "$ENGINE_BIN" -maxdepth 1 -name "*.debug" 2>/dev/null | wc -l)
  FINAL_STASHED=$(find "$STASH_DIR" -maxdepth 1 -name "*.debug" 2>/dev/null | wc -l)
  echo ""
  print_info "Active .debug files: $FINAL_ACTIVE"
  print_info "Stashed .debug files: $FINAL_STASHED"
''
