{
    description = "Krita Next Nightly";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils }:
        flake-utils.lib.eachDefaultSystem(system:
            let
                pkgs = import nixpkgs { inherit system; };
                version = "unstable-2025-10-30-113ee7c896";
                pname = "krita-next";
            in {
                packages.krita-next = pkgs.appimageTools.wrapType2 rec {
                    inherit pname;
                    inherit version;

                    src = pkgs.fetchurl {
                        name = "krita-next-${version}.AppImage";
                        url =
                            "https://cdn.kde.org/ci-builds/graphics/krita/master/linux/krita-5.3.0-prealpha-113ee7c896-x86_64.AppImage";
                        sha256 = "sha256-ldPCa8HrredCQx7te8TlcP5ex3eXUmcAffwFC9MEY2c=";
                    };

                    extraPkgs = pkgs: [];

                    extraInstallCommands = ''
                        wrapProgram $out/bin/${pname} \
                            --set QT_QPA_PLATFORM "wayland"
                    '';
                };

                packages.default = self.packages.${system}.krita-next;
            }
        );
}
