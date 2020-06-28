let
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/22a81aa5fc15b2d41b12f7160a71cd4a9f3c3fa1";
    sha256 = "14gx5fsqibdn2cxp7gymfrz2vcnwiwwjnxqlnysczz8dqihnrpa7";
  };

  all-hies = ../..;

  # Use this version for your project instead
  /*
  all-hies = fetchTarball {
	  # Insert the desired all-hies commit here
    url = "https://github.com/input-output-hk/haskell.nix/tarball/000000000000000000000000000000000000000";
		# Insert the correct hash after the first evaluation
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };
  */

  pkgs = import nixpkgs {
    config = {};
    overlays = [
      (import all-hies {}).overlay
    ];
  };
  inherit (pkgs) lib;

  set = pkgs.haskell.packages.ghc883.override (old: {
    overrides = lib.composeExtensions old.overrides (hself: hsuper: {
      all-hies-template = hself.callCabal2nix "all-hies-template" (lib.sourceByRegex ./. [
        "^.*\\.hs$"
        "^.*\\.cabal$"
      ]) {
        Cabal = hself.Cabal_3_2_0_0;
      };
    });
  });

in pkgs.haskell.lib.justStaticExecutables set.all-hies-template // {
  env = set.shellFor {
    packages = p: [ p.all-hies-template ];
    nativeBuildInputs = [
      set.cabal-install
      set.hie
    ];
    withHoogle = true;
    shellHook = ''
      export HIE_HOOGLE_DATABASE=$(realpath "$(dirname "$(realpath "$(which hoogle)")")/../share/doc/hoogle/default.hoo")
    '';
  };
  inherit set;
}