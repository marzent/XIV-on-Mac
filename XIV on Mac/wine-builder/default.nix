{ 
  pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/b6426c549d0994c662f0a26e1a2ad1663e865f9c.tar.gz";
    sha256 = "0xxxdzkd6a39528wsrizfmgwbz6rh2z485rwgh32ixixdvfqpw6s";
  }) {
    system = "x86_64-darwin";
  },
  pkgsCross ? pkgs.pkgsCross,
  darwinMinVersion ? "13.5"
}:

let
  mingwGccs = with pkgsCross; [ mingwW64.windows.crossThreadsStdenv.cc ]; # mingw32.windows.crossThreadsStdenv.cc ];
  setupHookDarwin = pkgs.makeSetupHook {
    name = "darwin-mingw-hook";
    substitutions = {
      darwinSuffixSalt = pkgs.stdenv.cc.suffixSalt;
      mingwGccsSuffixSalts = map (gcc: gcc.suffixSalt) mingwGccs;
    };
  } ./setup-hook-darwin.sh;
  target_sdk = pkgs.apple-sdk_15;
  darwinMinVersionHook = (pkgs.darwinMinVersionHook darwinMinVersion);
  addDarwinDepsRecursive = drv:
    if pkgs.lib.elem drv [ pkgs.darwinMinVersionHook target_sdk pkgs.stdenv pkgs.bash ] then
      drv
    else
      drv.overrideAttrs (oldAttrs: {
        buildInputs = let
          existingInputs = oldAttrs.buildInputs or [];
          containsAllDeps = pkgs.lib.all (dep: pkgs.lib.elem dep existingInputs) [ target_sdk darwinMinVersionHook ];
          modifiedInputs = if containsAllDeps
            then existingInputs
            else map addDarwinDepsRecursive existingInputs ++ [ target_sdk darwinMinVersionHook ];
        in
          modifiedInputs;
      });
  libiconv = (pkgs.libiconvReal
    .override {
      enableDarwinABICompat = true;
    })
    .overrideAttrs (oldAttrs: {
      buildInputs = [ target_sdk darwinMinVersionHook ];
      configureFlags = oldAttrs.configureFlags ++ [ "--enable-relocatable" ];
      preConfigure = ''
        export CFLAGS="-O3 -march=native -mno-avx"
      '';
    });
  gettext = pkgs.gettext.overrideAttrs (oldAttrs: {
    buildInputs = map addDarwinDepsRecursive (builtins.filter (input: input != pkgs.libiconv) oldAttrs.buildInputs) ++ [ target_sdk darwinMinVersionHook libiconv ];
    configureFlags = oldAttrs.configureFlags ++ [ "--enable-relocatable" ];
    patches = builtins.filter (patch: builtins.match ".*absolute-paths.diff" (toString patch) == null) oldAttrs.patches;
    preConfigure =''export CFLAGS="-O3 -march=native -mno-avx"'';
  });
  gnutls = import ./gnutls.nix {
    inherit pkgs target_sdk darwinMinVersionHook addDarwinDepsRecursive libiconv gettext;
  };
  SDL2 = pkgs.SDL2.overrideAttrs (oldAttrs: {
    buildInputs = [ target_sdk darwinMinVersionHook libiconv ];
    preConfigure =''export CFLAGS="-O3 -march=native -mno-avx"'';
  });
in
pkgs.stdenv.mkDerivation rec {
  pname = "ff-wine";
  version = "10.0.0 rc3";

  src = builtins.fetchGit {
    url = builtins.toString ./source;
  };

  strictDeps = true;

  dontAddExtraLibs = true;

  nativeBuildInputs = [
    pkgs.bison
    pkgs.flex
    pkgs.fontforge
    pkgs.pkg-config
    mingwGccs
    setupHookDarwin
  ];

  buildInputs = [
    target_sdk
    darwinMinVersionHook
    pkgs.darwin.moltenvk
    libiconv
    gettext
    SDL2
  ] ++ 
  map addDarwinDepsRecursive
  [
    pkgs.libinotify-kqueue
    pkgs.libpcap
    pkgs.freetype
    gnutls
    pkgs.libpng
  ];

  preConfigure = ''
    export CC="clang"
    export CFLAGS="-O3 -march=native -mno-avx -Wno-int-conversion"
    export CROSSCFLAGS="-s -O3 -march=native -mno-avx"
    export ac_cv_lib_soname_vulkan=""
    export ac_cv_lib_soname_MoltenVK="libMoltenVK.dylib"
    $CC --version
  '';


  NIX_LDFLAGS = toString (map (path: "-rpath " + path) (
      map (x: "${pkgs.lib.getLib x}/lib") (
        pkgs.lib.subtractLists [ target_sdk darwinMinVersionHook ] buildInputs)
    ));

  dontPatchELF = true;

  enableParallelBuilding = true;

  hardeningDisable = [ "all" ];

  configureFlags = [
    "--disable-option-checking"
    "--enable-win64" # "--enable-archs=x86_64,i386"
    "--disable-tests"
    "--without-alsa"
    "--without-capi"
    "--without-dbus"
    "--with-inotify"
    "--with-pcap"
    "--without-oss"
    "--without-pulse"
    "--without-udev"
    "--without-v4l2"
    "--without-gsm"
    "--with-mingw"
    "--with-png"
    "--with-sdl"
    "--without-krb5"
    "--with-vulkan"
    "--without-x"
    "--without-gstreamer"
  ];

  buildPhase = ''
    make -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    make install-lib DESTDIR=${placeholder "out"} -j$NIX_BUILD_CORES
  '';

  meta = {
    description = "ff-wine for macOS";
    homepage = "https://www.winehq.org/";
    license = pkgs.lib.licenses.lgpl21Plus;
    platforms = pkgs.lib.platforms.darwin;
  };
}

