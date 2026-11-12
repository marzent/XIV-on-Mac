#!/bin/bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
buildDir="$root/build"
installDir="$buildDir/install"
jobs=${WINE_BUILD_JOBS:-${NIX_BUILD_CORES:-$(sysctl -n hw.ncpu)}}

# Apply the same compiler settings as the Nix build. nix-build.sh runs the
# Darwin/MinGW setup hook first so its exported flags reach this process.
eval "${preConfigure:-}"

export CCACHE_DIR=${CCACHE_DIR:-"$root/.ccache"}
export CCACHE_BASEDIR="$root"
export CCACHE_COMPILERCHECK=${CCACHE_COMPILERCHECK:-content}
export CCACHE_MAXSIZE=${CCACHE_MAXSIZE:-10G}
export CC="ccache ${CC:-clang}"
export x86_64_CC="ccache ${x86_64_CC:-x86_64-w64-mingw32-gcc}"

if [[ ! -f "$buildDir/config.status" ]]; then
    echo "note: Configuring Wine in $buildDir"
    mkdir -p "$buildDir"
    (
        cd "$buildDir"
        "../source/configure" ${configureFlags:-} --prefix="$out"
    )
fi

make -C "$buildDir" -j"$jobs"
make -C "$buildDir" install-lib DESTDIR=install -j"$jobs"
printf '%s\n' "$out" > "$installDir/.build-output"

revision=$(
    cd "$installDir$out"
    find . -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}'
)
printf '%s\n' "$revision" > "$installDir/.build-revision"
ln -sfn "$installDir" "$root/result"

echo "note: Wine is up to date. Compiler cache: $CCACHE_DIR"
