{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";

    crate2nix.url = "github:kolloch/crate2nix";
    crate2nix.flake = false;

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, rust-overlay, crate2nix, ... }:
  let
    name = "raytracer";
  in
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlay
          (self: super: {
            rustc = self.rust-bin.stable.latest.default;
            cargo = self.rust-bin.stable.latest.default;
          })
        ];
      };
      inherit (import "${crate2nix}/tools.nix" { inherit pkgs; }) generatedCargoNix;
      project = pkgs.callPackage (generatedCargoNix {
        inherit name;
        src = ./.;
      }) {
        defaultCrateOverrides = pkgs.defaultCrateOverrides // {
          "${name}" = oldAttrs: {
            inherit buildInputs nativeBuildInputs;
          } // buildEnvVars;
        };
      };
      
      buildInputs = with pkgs; [ qemu ];
      nativeBuildInputs = with pkgs; [ nasm rustc cargo clippy pkgconfig nixpkgs-fmt ];
      buildEnvVars = {
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      };
    in
    rec {
      # packages.${name} = project.rootCrate.build;

      # defaultPackage = packages.${name};

      # apps.${name} = flake-utils.lib.mkApp {
      #   inherit name;
      #   drv = packages.${name};
      # };
      # defaultApp = apps.${name};

      devShell = pkgs.mkShell {
        inherit buildInputs nativeBuildInputs;
        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
        shellHook = ''
          alias m=make
          alias mr='m run'
          alias md='m debug'
        '';
      } // buildEnvVars;
    }
  );
}
