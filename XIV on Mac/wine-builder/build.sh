#!/bin/bash
#set -x

nix-build --max-jobs $(sysctl -n hw.ncpu)

sourceDir="result/nix/store"
targetDir="../wine"
overridesDir="overrides"

if [[ ! -d $sourceDir ]]; then
    echo "Nix build failed."
    exit 1
fi

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
        echo "-delete_rpath"
        echo "$rpath"
    done
}

process_dylib_dependecy() {
    local dylibPath=$1
    local dylibName=$(basename "$dylibPath")
    local changes=()

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
        changes+=("-id" "@rpath/$dylibName")
    fi

    local dependencies=$(extract_dependencies "$libDir/$dylibName")
    for dep in $dependencies; do
        local depName=$(basename "$dep")
        changes+=("-change" "$dep" "@rpath/$depName")
        process_dylib_dependecy "$dep"
    done

    local dylibRpaths=$(extract_rpaths "$libDir/$dylibName")
    while read -r rpath; do
        if [[ -d "$rpath" ]]; then
            for dep in "$rpath"/*.dylib; do
                if [[ -f "$dep" ]]; then
                    local depName=$(basename "$dep")
                    changes+=("-change" "$dep" "@rpath/$depName")
                    process_dylib_dependecy "$dep"
                fi
            done
        fi
    done <<< "$dylibRpaths"
    
    while IFS= read -r line; do
        changes+=("$line")
    done < <(remove_nix_rpaths "$binaryPath")
    
    install_name_tool "${changes[@]}" "$libDir/$dylibName" 2>/dev/null
}

process_binary() {
    local binaryPath=$1
    local binaryName=$(basename "$binaryPath")
    local changes=()
    
    if is_processed "$binaryName"; then
        return 0
    fi
    processedLibs+=("$binaryName")

    changes+=("-id" "$binaryName")

    local dependencies=$(extract_dependencies "$binaryPath")
    for dep in $dependencies; do
        local depName=$(basename "$dep")
        changes+=("-change" "$dep" "@rpath/$depName")
        process_dylib_dependecy "$dep"
    done

    local binaryRpaths=$(extract_rpaths "$binaryPath")
    while read -r rpath; do
        if [[ -d "$rpath" ]]; then
            for dep in "$rpath"/*.dylib; do
                if [[ -f "$dep" ]]; then
                    local depName=$(basename "$dep")
                    changes+=("-change" "$dep" "@rpath/$depName")
                    process_dylib_dependecy "$dep"
                fi
            done
        fi
    done <<< "$binaryRpaths"
    
    while IFS= read -r line; do
        changes+=("$line")
    done < <(remove_nix_rpaths "$binaryPath")

    changes+=("-add_rpath" "@executable_path/../lib")
    changes+=("-add_rpath" "@loader_path/../..")
    install_name_tool "${changes[@]}" "$binaryPath" 2>/dev/null
}

find "$targetDir" -type f | while read file; do
    if [[ "$file" == *".dylib" || "$file" == *".so" || -x "$file" ]]; then
        process_binary "$file"
    fi
done

