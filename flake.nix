{
  description = "nix utils";

  inputs.nix-filter.url = "github:numtide/nix-filter";

  outputs = { self, nixpkgs, nix-filter, ... }@inputs:
    with nixpkgs.lib;
    let
      thenEndo = f: g: x: f (g (x));
      manyEndo = foldr thenEndo (x: x);

      mkCabal = { packages, ghcVersion ? 924, mkVersion ? (x: x) }:
        { name, source, excludeFiles ? [ ("Setup.hs") ("stack.yaml") ]
        , excludeExtensions ? [ ], dependencies ? { }, configureFlags ? [ ]
        , extraLibraries ? [ ]
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
        ] (addExtraLibraries (appendConfigureFlags
          ((haskellPackages.callCabal2nix name (filter {
            root = source;
            exclude = (map matchName excludeFiles)
              ++ (map matchExt excludeExtensions);
          }) dependencies).overrideAttrs (old:
            (overrideAttrs old) // {
              version = mkVersion "${old.version}";
            })) configureFlags) extraLibraries);

      overlays = { default = _: _: { inherit thenEndo manyEndo mkCabal; }; };
      lib = { inherit thenEndo manyEndo mkCabal; };
    in { inherit overlays lib; };
}
