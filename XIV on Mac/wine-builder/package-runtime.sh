#!/bin/bash

nixResult="result"
sourceDir="$nixResult/nix/store"
targetDir="../wine"
overridesDir="overrides"
receipt="packaged-nix-output"

if [[ ! -d $sourceDir ]]; then
    echo "warning: Nix build did not succeed. No runtime to package."
    cd "$PROJECT_DIR"/XIV\ on\ Mac/
    [ -d "wine" ] && exit 0
    echo "note: No prexisting wine package. Attempting archive download..."
    curl -LO https://github.com/marzent/winecx/releases/download/ff-wine-9.12.1/wine.tar.xz
    tar -xf wine.tar.xz
    rm wine.tar.xz
    exit 0
fi

if [[ ! -L "$nixResult" ]]; then
  echo "error: Nix build failed."
  exit 1
fi

nixResultTarget=$(readlink "$nixResult")

if [[ -e "$receipt" && -d "$targetDir" ]]; then
  current_content=$(<"$receipt")
  if [[ "$current_content" == "$nixResultTarget" ]]; then
    echo "note: The last built wine package matches the current one. No changes made."
    exit 0
  fi
fi

echo "$nixResultTarget" > "$receipt"
echo "note: Updated receipt $receipt with Nix store result: $nixResultTarget"
echo "note: Packaging wine..."

subDir=$(find $sourceDir -type d -mindepth 1 -maxdepth 1 | head -n 1)

rm -rf $targetDir
mkdir -p $targetDir
cp -R "$subDir/"* $targetDir
chmod -R u+w $targetDir
rsync -a "$overridesDir/lib" $targetDir

libDir="$targetDir/lib"
mkdir -p "$libDir"
processedLibs=("libMoltenVK.dylib")

is_processed() {
    local libName=$1
    for processedLib in "${processedLibs[@]}"; do
        if [[ "$processedLib" == "$libName" ]]; then
            return 0
        fi
    done
    return 1
}

extract_rpaths() {
    local file=$1
    otool -l "$file" | awk '/cmd LC_RPATH/ { getline; getline; if($2 ~ /\/nix\/store/) print $2 }'
}

extract_dependencies() {
    local dylib=$1
    otool -l "$dylib" | awk '/cmd LC_LOAD_DYLIB/ { getline; getline; if($2 ~ /\/nix\/store/ && $2 ~ /\.dylib$/) print $2 }'
}

resolve_symlink_path() {
    local symlinkPath=$1
    local symlinkDir=$(dirname "$symlinkPath")
    local symlinkBaseName=$(basename "$(readlink "$symlinkPath")")
    echo "$(cd "$symlinkDir" && pwd -P)/$symlinkBaseName"
}

remove_nix_rpaths() {
    local file=$1
    local rpaths_to_remove=$(otool -l "$file" | awk '/cmd LC_RPATH/ { getline; getline; if($2 ~ /\/nix\/store/) print $2 }')

    for rpath in $rpaths_to_remove; do
        install_name_tool -delete_rpath "$rpath" "$file"
    done
}

process_dylib_dependecy() {
    local dylibPath=$1
    local dylibName=$(basename "$dylibPath")

    if is_processed "$dylibName"; then
        return 0
    fi
    processedLibs+=("$dylibName")

    if [[ -L "$dylibPath" ]]; then
        local targetName=$(readlink "$dylibPath")
        ln -s "$targetName" "$libDir/$dylibName"
        process_dylib_dependecy "$(resolve_symlink_path "$dylibPath")"
        return
    else
        cp "$dylibPath" "$libDir"
        chmod +w "$libDir/$dylibName"
        install_name_tool -id "@rpath/$dylibName" "$libDir/$dylibName"
    fi

    local dependencies=$(extract_dependencies "$libDir/$dylibName")
    for dep in $dependencies; do
        local depName=$(basename "$dep")
        install_name_tool -change "$dep" "@rpath/$depName" "$libDir/$dylibName"
        process_dylib_dependecy "$dep"
    done

    local dylibRpaths=$(extract_rpaths "$libDir/$dylibName")
    while read -r rpath; do
        if [[ -d "$rpath" ]]; then
            for dep in "$rpath"/*.dylib; do
                if [[ -f "$dep" ]]; then
                    local depName=$(basename "$dep")
                    install_name_tool -change "$dep" "@rpath/$depName" "$libDir/$dylibName"
                    process_dylib_dependecy "$dep"
                fi
            done
        fi
    done <<< "$dylibRpaths"
    
    remove_nix_rpaths "$libDir/$dylibName"
}

process_binary() {
    local binaryPath=$1
    local binaryName=$(basename "$binaryPath")

    install_name_tool -id "$binaryName" "$binaryPath"

    local dependencies=$(extract_dependencies "$binaryPath")
    for dep in $dependencies; do
        local depName=$(basename "$dep")
        install_name_tool -change "$dep" "@rpath/$depName" "$binaryPath"
        process_dylib_dependecy "$dep"
    done

    local binaryRpaths=$(extract_rpaths "$binaryPath")
    while read -r rpath; do
        if [[ -d "$rpath" ]]; then
            for dep in "$rpath"/*.dylib; do
                if [[ -f "$dep" ]]; then
                    local depName=$(basename "$dep")
                    install_name_tool -change "$dep" "@rpath/$depName" "$binaryPath"
                    process_dylib_dependecy "$dep"
                fi
            done
        fi
    done <<< "$binaryRpaths"
    
    remove_nix_rpaths "$binaryPath"

    install_name_tool -add_rpath "@executable_path/../lib" "$binaryPath"
    install_name_tool -add_rpath "@loader_path/../.." "$binaryPath"
}

find "$targetDir" -type f | while read file; do
    if [[ -d "$file" ]]; then
        continue
    fi
    if [[ "$file" == *".dylib" || "$file" == *".so" || -x "$file" ]]; then
        process_binary "$file"
    fi
done

