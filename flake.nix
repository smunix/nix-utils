{
  description = "nix utils";

  inputs.nix-filter.url = "github:numtide/nix-filter";

  outputs = { self, nixpkgs, nix-filter, ... }@inputs:
    with nixpkgs.lib;
    let
      composeThen = f: g: x: f (g (x));
      composeMany = foldr composeThen (x: x);

      haskellSharedLibExe = pkgs:
        with pkgs.haskell.lib; rec {
          __functor = self: sharedLibExe;
          sharedLibExe = composeMany [
            enableSharedExecutables
            enableSharedLibraries
            disableStaticLibraries
            disableLibraryProfiling
          ];
        };

      mkCabal = { packages, ghcVersion ? 924, mkVersion ? (x: x) }:
        { name, source, exclude ? [ ("Setup.hs") ("stack.yaml") ]
        , dependencies ? { }, configureFlags ? [ ], extraLibraries ? [ ]
        , doLibraryProfiling ? packages.haskell.lib.disableLibraryProfiling
        , overrideAttrs ? (x: x), haskellPackages ?
          packages.haskell.packages."ghc${toString ghcVersion}" }:
        with packages.lib;
        with packages.haskell.lib;
        with nix-filter.lib;
        addExtraLibraries (appendConfigureFlags (doLibraryProfiling
          (disableStaticLibraries (enableSharedLibraries
            (enableSharedExecutables ((haskellPackages.callCabal2nix name
              (filter {
                root = source;
                inherit exclude;
              }) dependencies).overrideAttrs (old:
                {
                  version = mkVersion "${old.version}";
                } // (overrideAttrs old))))))) configureFlags) extraLibraries;

      overlays = { default = _: _: { inherit haskellSharedLibExe mkCabal; }; };
      lib = rec {
        __functor = self: haskellSharedLibExe;
        inherit haskellSharedLibExe mkCabal;
      };
    in { inherit overlays lib; };
}
