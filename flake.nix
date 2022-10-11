{
  description = "nix utils";

  outputs = { self, nixpkgs, ... }@inputs:
    with nixpkgs.lib;
    let
      composeThen = f: g: x: f (g (x));
      composeMany = foldr composeThen (x: x);

      haskellSharedLibExe = pkgs:
        with pkgs.haskell.lib;
        rec {
          __functor = self: sharedLibExe;
          sharedLibExe =
            composeMany [
              enableSharedExecutables
              enableSharedLibraries
              disableStaticLibraries
              disableLibraryProfiling
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
