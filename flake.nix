{
  description = "nix utils";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=master";
  inputs.nix-filter.url = "github:numtide/nix-filter";

  outputs = { self, nixpkgs, nix-filter, ... }@inputs:
    with nixpkgs.lib;
    let
      thenEndo = f: g: x: f (g (x));
      manyEndo = foldr thenEndo (x: x);

      mkCabal0 = { packages, ghcVersion ? 924, mkVersion ? (x: x) }:
        { name, source, excludeFiles ? [ ("Setup.hs") ("stack.yaml") ]
        , excludeExtensions ? [ ], dependencies ? { }, configureFlags ? [ ]
        , extraLibraries ? [ ], doHaddock ? packages.haskell.lib.doHaddock
        , doOptimization ? packages.haskell.lib.disableOptimization
        , doLibraryProfiling ? packages.haskell.lib.disableLibraryProfiling
        , doSharedExecutables ? packages.haskell.lib.enableSharedExecutables
        , doSharedLibraries ? packages.haskell.lib.enableSharedLibraries
        , doStaticLibraries ? packages.haskell.lib.disableStaticLibraries
        , overrideAttrs ? (x: x), haskellPackages ?
          packages.haskell.packages."ghc${toString ghcVersion}" }:
        with packages.lib;
        with packages.haskell.lib;
        with nix-filter.lib;
        manyEndo [
          doLibraryProfiling
          doStaticLibraries
          doSharedLibraries
          doSharedExecutables
          doHaddock
          doOptimization
        ] (addExtraLibraries (appendConfigureFlags
          ((haskellPackages.callCabal2nix name (filter {
            root = source;
            exclude = (map matchName excludeFiles)
              ++ (map matchExt excludeExtensions);
          }) dependencies).overrideAttrs (old:
            (overrideAttrs old) // {
              version = mkVersion "${old.version}";
            })) configureFlags) extraLibraries);

      mkCabal = { packages, ghcVersion ? 924, mkVersion ? (x: x) }:
        { name, source, excludeFiles ? [ ("Setup.hs") ("stack.yaml") ]
        , excludeExtensions ? [ ], dependencies ? { }, configureFlags ? [ ]
        , extraLibraries ? [ ], doHaddock ? packages.haskell.lib.doHaddock
        , doFailOnAllWarnings ? packages.haskell.lib.failOnAllWarnings
        , doLibraryProfiling ? packages.haskell.lib.disableLibraryProfiling
        , doSharedExecutables ? packages.haskell.lib.enableSharedExecutables
        , doSharedLibraries ? packages.haskell.lib.enableSharedLibraries
        , doStaticLibraries ? packages.haskell.lib.disableStaticLibraries
        , overrideAttrs ? (x: x), haskellPackages ?
          packages.haskell.packages."ghc${toString ghcVersion}" }:
        with packages.lib;
        with packages.haskell.lib;
        with nix-filter.lib;
        manyEndo [
          doLibraryProfiling
          doStaticLibraries
          doSharedLibraries
          doSharedExecutables
          doHaddock
          doFailOnAllWarnings
        ] (addExtraLibraries (appendConfigureFlags
          ((haskellPackages.callCabal2nix name (filter {
            root = source;
            exclude = (map matchName excludeFiles)
              ++ (map matchExt excludeExtensions);
          }) dependencies).overrideAttrs (old:
            (overrideAttrs old) // {
              version = mkVersion "${old.version}";
            })) configureFlags) extraLibraries);

      lib = { inherit thenEndo manyEndo mkCabal mkCabal0; };
      overlays = { default = _: _: lib; };
    in { inherit overlays lib; };
}
