   { pkgs, lib, utils }:

   let
     unrealFHSWrapper = import ./fhs-wrapper.nix { inherit pkgs lib utils; };
   in

   pkgs.writeScriptBin "run-rider" ''
     #!${pkgs.stdenv.shell}
     ${lib.banners.colorTheWorld}
     TOOLBOX_RIDER="$HOME/.local/share/JetBrains/Toolbox/apps/rider/bin/rider.sh"

     # UE stability flags for Rider debugging — add these to Rider's
     # Run/Debug Configuration > Program arguments
     export UE_DEBUG_FLAGS="-reducethreadusage -limitedmemorypool"
     print_warning "Reminder: Add these flags to Rider's Run/Debug Configuration > Program arguments:"
     print_warning "  $UE_DEBUG_FLAGS"

     if [ -f "$TOOLBOX_RIDER" ]; then
       ${unrealFHSWrapper}/bin/unreal-fhs "$TOOLBOX_RIDER $*"
     else
       ${unrealFHSWrapper}/bin/unreal-fhs "rider $*"
     fi
   ''
