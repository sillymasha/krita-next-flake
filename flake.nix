{
  description = "Standalone flake for Krita (Qt6, master branch build)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    rev = "cc018c6cda5442708188203143e44c0f971784cf";
    version = "master-${rev}";
    forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f system);
  in
  {
    packages = forEachSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        kritaSrc = pkgs.fetchgit {
          url = "https://invent.kde.org/graphics/krita.git";
          inherit rev;
          hash = "sha256-W40GrUnodhbl2BUKMrWkgzlCdgeUel1nfzUQkCCzFWQ=";
        };

        krita-unwrapped = pkgs.stdenv.mkDerivation rec {
          pname = "krita-unwrapped";
          inherit version;

          src = kritaSrc;

          nativeBuildInputs = with pkgs; [
            cmake
            extra-cmake-modules
            pkg-config
            python3Packages.sip
            kdePackages.wrapQtAppsHook
          ];

          buildInputs = with pkgs; [
            kdePackages.qttools
            kdePackages.karchive
            kdePackages.kconfig
            kdePackages.kwidgetsaddons
            kdePackages.kcompletion
            kdePackages.kcoreaddons
            kdePackages.kguiaddons
            kdePackages.ki18n
            kdePackages.kitemmodels
            kdePackages.kitemviews
            kdePackages.kwindowsystem
            kdePackages.kio
            kdePackages.kcrash
            kdePackages.breeze-icons
            boost
            libraw
            fftw
            eigen
            exiv2
            fribidi
            lcms2
            gsl
            openexr
            lager
            libaom
            libheif
            kdePackages.libkdcraw
            giflib
            libjxl
            mlt
            openjpeg
            opencolorio
            xsimd
            poppler
            curl
            ilmbase
            immer
            kseexpr
            libmypaint
            libunibreak
            libwebp
            qt6.qtbase
            qt6.qtmultimedia
            kdePackages.quazip
            SDL2
            zug
            python3Packages.pyqt6
          ];

          env.NIX_CFLAGS_COMPILE =
            toString (lib.optional pkgs.stdenv.cc.isGNU "-Wno-deprecated-copy");

          postPatch =
            let
              pythonPath = pkgs.python3Packages.makePythonPath (with pkgs.python3Packages; [
                sip
                setuptools
              ]);
            in
            ''
              substituteInPlace cmake/modules/FindSIP.cmake \
                --replace 'PYTHONPATH=''${_sip_python_path}' 'PYTHONPATH=${pythonPath}'
              substituteInPlace cmake/modules/SIPMacros.cmake \
                --replace 'PYTHONPATH=''${_krita_python_path}' 'PYTHONPATH=${pythonPath}'

              substituteInPlace plugins/impex/jp2/jp2_converter.cc \
                --replace '<openjpeg.h>' '<${pkgs.openjpeg.dev}/include/openjpeg-2.5/openjpeg.h>'
            '';

          postFixup = 
            let
              pyRuntimePath = pkgs.python3Packages.makePythonPath (with pkgs.python3Packages; [
                pyqt6
                sip
              ]);
            in
              ''
                wrapQtApp "$out/bin/krita" \
                  --prefix PYTHONPATH : "${pyRuntimePath}" \
                  --set KRITA_PLUGIN_PATH "$out/lib/kritaplugins" \
                  --set QT_QPA_PLATFORM "wayland"
              '';

          cmakeBuildType = "RelWithDebInfo";

          cmakeFlags = let
            sp = pkgs.python3Packages.python.sitePackages;
            p6 = pkgs.python3Packages.pyqt6;
          in [
            "-DBUILD_WITH_QT6=ON"
            "-DQT_MAJOR_VERSION=6"
            "-DPYQT6_SIP_DIR=${p6}/${sp}/PyQt6/bindings"
            "-DPYQT_SIP_DIR_OVERRIDE=${p6}/${sp}/PyQt6/bindings"
            "-DBUILD_KRITA_QT_DESIGNER_PLUGINS=ON"
          ];

          meta = with lib; {
            description  = "Krita painting application built from master branch (Qt6)";
            homepage     = "https://krita.org/";
            mainProgram  = "krita";
            platforms    = platforms.linux;
            license      = licenses.gpl3Only;
          };
        };
      in
      {
        default = krita-unwrapped;
        krita-unwrapped = krita-unwrapped;
      }
    );

    apps = forEachSystem (system: let pkg = self.packages.${system}.krita-unwrapped; in {
      default = {
        type = "app";
        program = "${pkg}/bin/krita";
      };
      krita = {
        type = "app";
        program = "${pkg}/bin/krita";
      };
    });

    devShells = forEachSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            cmake
            extra-cmake-modules
            pkg-config
            python3Packages.sip
          ];
          buildInputs = with pkgs; [
            python3Packages.pyqt6
          ];
        };
      }
    );
  };
}

