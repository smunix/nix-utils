{
  description = "nix utils";

  outputs = { self, nixpkgs, ... }@inputs:
    with nixpkgs.lib;
    let
      composeThen = f: g: x: f (g (x));
      composeMany = foldr composeThen (x: x);

      haskellSharedLibExe = h: rec {
        __functor = self: sharedLibExe;
        sharedLibExe =
          composeMany [
            h.lib.enableSharedExecutables
            h.lib.enableSharedLibraries
          ];
      };
      overlays = {
        default = _: _: {
          inherit haskellSharedLibExe;
        };
      };
      lib = rec {
        __functor = self: haskellSharedLibExe;
        inherit haskellSharedLibExe;
      };
    in {
      inherit overlays lib;
    };
}
