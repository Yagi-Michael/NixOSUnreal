{ pkgs, lib, utils }:

let
  unrealFHSWrapper = import ./fhs-wrapper.nix { inherit pkgs lib utils; };
in

pkgs.writeScriptBin "run-zed" ''
  #!${pkgs.stdenv.shell}
  ${lib.banners.colorTheWorld}

  # UE stability flags — add these to Zed's debug launch config args
  export UE_DEBUG_FLAGS="-reducethreadusage -limitedmemorypool"
  print_warning "Reminder: Add these flags to Zed debug launch args if launching UE from debugger:"
  print_warning "  $UE_DEBUG_FLAGS"

  ${unrealFHSWrapper}/bin/unreal-fhs "zeditor /work/ascent $*"
''
