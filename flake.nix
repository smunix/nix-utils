{
  description = "nix utils";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=haskell-updates";
  inputs.nix-filter.url = "github:numtide/nix-filter";

  outputs = { self, nixpkgs, nix-filter, ... }@inputs:
    with nixpkgs.lib;
    let
      # endo :: [drv -> drv] -> drv -> drv
      endoL = foldr (fn: r: x: fn (r x)) id;

      # applyS :: (drv -> drv') -> {f:drv,...} -> {f:drv'}
      applyS = fn: attrsets.mapAttrs (_: drv: fn drv);

      # build :: { globalExt } -> hpkgs -> specs -> hpkgs
      build = { globalExt }:
        hpkgs: specs:
        let
          localExts = composeManyExtensions (map (spec:
            (hf: hp:
              applyS (endoL (spec.modifiers or [ ])) (spec.extension hf hp)))
            specs);
        in hpkgs.override ({
          overrides = composeExtensions globalExt localExts;
        });

      # slow :: hpkgs -> specs -> hpkgs
      slow = build { globalExt = hf: hp: { }; };

      # fast :: hpkgs -> specs -> hpkgs
      fast = build {
        globalExt = hf: hp: {
          mkDerivation = args:
            hp.mkDerivation (args // {
              doCheck = false;
              doHaddock = false;
              enableLibraryProfiling = false;
              enableExecutableProfiling = false;
              jailbreak = true;
            });
        };
      };

      thenEndo = f: g: x: f (g (x));
      manyEndo = foldr thenEndo (x: x);

      mkCabal0 = { packages, ghcVersion ? 924, mkVersion ? (x: x) }:
        { name, source, excludeFiles ? [ ("Setup.hs") ("stack.yaml") ]
        , excludeExtensions ? [ ], dependencies ? { }, configureFlags ? [ ]
        , extraLibraries ? [ ], doHaddock ? packages.haskell.lib.dontHaddock
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

      lib = { inherit slow fast thenEndo manyEndo mkCabal mkCabal0; };
      overlays = { default = _: _: lib; };
    in { inherit overlays lib; };
}
