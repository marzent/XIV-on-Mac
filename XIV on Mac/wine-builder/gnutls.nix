{ pkgs, target_sdk, darwinMinVersionHook, addDarwinDepsRecursive, libiconv, gettext }:

let
  doCheck = false;
  libidn2 = pkgs.libidn2.overrideAttrs (oldAttrs: {
    buildInputs = builtins.filter (input: input != pkgs.libiconv) oldAttrs.buildInputs ++ [ libiconv ];
    preConfigure =''export CFLAGS="-O3 -march=native -mno-avx"'';
  });
in

pkgs.stdenv.mkDerivation rec {
  pname = "gnutls";
  version = "3.8.6";

  src = pkgs.fetchurl {
    url = "mirror://gnupg/gnutls/v${pkgs.lib.versions.majorMinor version}/gnutls-${version}.tar.xz";
    hash = "sha256-LhWIquU8sy1Dk38fTsoo/r2cDHqhc0/F3WGn6B4OvN0=";
  };

  outputs = [ "bin" "dev" "out" ];
  outputInfo = "devdoc";
  outputDoc  = "devdoc";

  patches = [
    (pkgs.fetchpatch2 {
      name = "revert-dlopen-compression.patch";
      url = "https://gitlab.com/gnutls/gnutls/-/commit/8584908d6b679cd4e7676de437117a793e18347c.diff";
      revert = true;
      hash = "sha256-r/+Gmwqy0Yc1LHL/PdPLXlErUBC5JxquLzCBAN3LuRM=";
    })
  ];

  preConfigure =''
    patchShebangs .
    export CFLAGS="-O3 -march=native -mno-avx -Wno-implicit-int"
  '';

  configureFlags = [
    "--disable-dependency-tracking"
    "--enable-fast-install"
    "--disable-libdane"
    "--without-p11-kit"
    "--disable-doc"
    "--disable-tests"
  ];

  enableParallelBuilding = true;

  dontAddExtraLibs = true;

  buildInputs = [ pkgs.lzo pkgs.lzip pkgs.libtasn1 pkgs.zlib pkgs.gmp pkgs.libunistring gettext libidn2 libiconv ];

  nativeBuildInputs = [ pkgs.perl pkgs.pkg-config pkgs.texinfo ] ++ [ pkgs.autoconf pkgs.automake ];

  propagatedBuildInputs = map addDarwinDepsRecursive [ pkgs.nettle ];

  inherit doCheck;

  meta = with pkgs.lib; {
    description = "The GNU Transport Layer Security Library";
    longDescription = ''
      GnuTLS is a project that aims to develop a library which
      provides a secure layer, over a reliable transport
      layer. Currently the GnuTLS library implements the proposed standards by
      the IETF's TLS working group.

      "The TLS protocol provides communications privacy over the
      Internet. The protocol allows client/server applications to
      communicate in a way that is designed to prevent eavesdropping,
      tampering, or message forgery."
    '';
    homepage = "https://gnutls.org/";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ vcunat ];
    platforms = platforms.all;
  };
}
