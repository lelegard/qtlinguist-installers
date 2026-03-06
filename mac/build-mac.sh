#!/bin/bash
#-----------------------------------------------------------------------------
#
#  Copyright (c) 2016-2026, Thierry Lelegard
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
#  THE POSSIBILITY OF SUCH DAMAGE.
#
#-----------------------------------------------------------------------------
#
#  Shell script to build the DMG package for Qt Linguist on macOS.
#
#-----------------------------------------------------------------------------

SCRIPT=$(basename $BASH_SOURCE)
error() { echo >&2 "$SCRIPT: $*"; exit 1; }
warning() { echo >&2 "warning: $*"; }

# Uncompressed DMG size.
DMGSIZE=128m

# Required Qt plugins and translations.
PLUGINS=(iconengines imageformats networkinformation platforms sqldrivers styles tls)
TRANSLATIONS=(linguist assistant qt qt_help qtbase qtmultimedia)
DOCS=(qtlinguist qtassistant)

# Various directories in this project.
SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
ROOTDIR=$(dirname $SCRIPTDIR)
TMPDIR=$SCRIPTDIR/tmp

# The DMG will be initially created into TMPDIR, later converted into installers.
DMGTMP="$TMPDIR/QtLinguist.dmg"

# Find Xcode tools.
find_xcode_tool() {
    local cmd=$1
    local file=$(xcrun -find $cmd 2>/dev/null)
    [[ -z "$file" ]] && error "$cmd command not found, install Xcode command line tools"
    echo "$file"
}

LIPO=$(find_xcode_tool lipo)
OTOOL=$(find_xcode_tool otool)

# On macOS, Qt is installed in user's account.
# Search for a Linguist.app directory in a path containing a version number.
LINGDIR=$(find $HOME/[Qq]* -type d -name Linguist.app 2>/dev/null | grep '[0-9]\.[0-9]' | sort | tail -1)
[[ -z "$LINGDIR" ]] && error "no Qt installation found in $HOME"
LINGUIST="$LINGDIR/Contents/MacOS/Linguist"
[[ -x "$LINGUIST" ]] || error "Linguist not found in $LINGDIR"
QTBINDIR=$(dirname "$LINGDIR")
QTDIR=$(dirname "$QTBINDIR")

# Supported architectures for Linguist.
ARCHITECTURES=($("$LIPO" -archs "$LINGUIST"))

# Get Qt version from the Qt path.
VERSION=$(tr <<<$QTBINDIR / '\n'  | grep -e '^[Qq][Tt][0-9][0-9\.-]*$' -e '^[0-9][0-9\.-]*$' | sed -e 's/^[Qq][Tt]//' | head -1)
[[ -z "$VERSION" ]] && error "Qt version not found from $QTBINDIR"

# Get documentation directory. Unfortunately, it is not defined in the same tree as the rest.
# Find the location in the configuration file of Qt Assistant.
ASSCONF="$QTBINDIR/Assistant.app/Contents/Resources/qt.conf"
[[ -e "$ASSCONF" ]] || error "not found: $ASSCONF"
QTDOCDIR=$(sed -e '/Documentation=/!d' -e 's/.*Documentation= *//' -e 's/ *$//' "$ASSCONF" | tail -1)
[[ -z "$QTDOCDIR" ]] && error "no 'Documentation' field in $ASSCONF"
QTDOCDIR="$QTDIR/$QTDOCDIR"
[[ -d "$QTDOCDIR" ]] || error "doc directory not found: $QTDOCDIR"
QTDOCDIR=$(cd "$QTDOCDIR"; pwd)

echo "Qt version: $VERSION"
echo "Qt root: $QTDIR"
echo "Qt docs: $QTDOCDIR"

# Set an icon to a file or folder.
# Syntax: set_icon icon-file destination-file
set_icon() {
    local icon="$1"
    local dest="$2"
    local name=$(basename "$icon")
    local tmpdir=/tmp/$$
    mkdir $tmpdir

    # Add icon to a copy of the icon file, meaning use itself as the icon.
    cp "$icon" "$tmpdir/$name"
    sips -i "$tmpdir/$name"

    # Put that icon into a resource file.
    DeRez -only icns "$tmpdir/$name" >"$tmpdir/rsrc"

    # Say that the destination file has a custom icon (attribute C).
    SetFile -a C "$dest"
    if [[ -f $iconDestination ]]; then
        # Destination is a file.
        Rez -append "$tmpdir/rsrc" -o "$dest"
    elif [ -d $iconDestination ]; then
        # Destination is a directory: create file Icon\r.
        touch "$dest"/Icon$'\r'
        Rez -append "$tmpdir/rsrc" -o "$dest"/Icon$'\r'
        # Set Icon\r file as invisible for the Finder.
        SetFile -a V "$dest"/Icon$'\r'
    fi

    rm -rf $tmpdir
}

# Strip a universal binary. Keep only one architecture.
# Syntax: remove_other_arch arch file...
remove_other_arch() {
    local arch="$1"
    shift
    for file in "$@"; do
        for a in $("$LIPO" -archs "$file" 2>/dev/null); do
            if [[ $a != $arch ]]; then
                "$LIPO" -remove $a "$file" -output "$file"
            fi
        done
    done
}

# Process a binary, remove other architecture, grab dependencies.
# Syntax: process_binary arch dest-root file
process_binary() {
    local arch="$1"
    local root="$2"
    local file="$3"
    remove_other_arch "$arch" "$file"

    # Analyze and copy dependencies.
    for dep in $("$OTOOL" -L "$file" | grep @rpath/ | sed -e 's/ (.*//' -e 's/@rpath\///'); do
        if [[ ! -e "$QTDIR/lib/$dep" ]]; then
            echo >&2 "error: not found: $QTDIR/lib/$dep"
        elif [[ ! -e "$root/lib/$dep" ]]; then
            dir=$(dirname $dep)
            if [[ $dir == . ]]; then
                # Simple file.
                cp "$QTDIR/lib/$dep" "$root/lib/$dep"
            else
                # Directory, probably a framework.
                tar cf - --exclude Headers --no-mac-metadata -C "$QTDIR/lib" "$dir" | tar xf - -C "$root/lib"
            fi
            process_binary "$arch" "$root" "$root/lib/$dep"
        fi
    done
}

# Build an installer for one architecture.
# Syntax: build_dmg arch
build_dmg() {
    ARCH="$1"
    echo "Building installer for $ARCH ..."

    DMGFILE="$ROOTDIR/installers/QtLinguist-$ARCH-$VERSION.dmg"
    VOLUME="Qt Linguist $VERSION ($ARCH)"
    VOLROOT="/Volumes/$VOLUME"
    DESTNAME="Qt Linguist"
    DESTAPP="$VOLROOT/$DESTNAME.app"
    DESTRES="$DESTAPP/Contents/Resources"

    # Create the content of the DMG file.
    rm -rf "$TMPDIR"
    mkdir -p "$TMPDIR"
    hdiutil create -size $DMGSIZE -fs HFS+ -volname "$VOLUME" "$DMGTMP"

    # Mount the disk image
    hdiutil attach "$DMGTMP"
    DEVS=$(hdiutil attach "$DMGTMP" | cut -f 1)
    DEV=$(echo $DEVS | cut -f 1 -d ' ')

    # Build a custom bundle with a subset of Qt structure in Resources.
    mkdir -p "$DESTAPP/Contents/MacOS" "$DESTRES/bin" "$DESTRES/lib" "$DESTRES/plugins" "$DESTRES/translations" "$DESTRES/docs"

    # Copy application bundles.
    cp -r "$QTBINDIR/Linguist.app" "$QTBINDIR/Assistant.app" "$DESTRES/bin"

    for exe in "$DESTRES/bin/Linguist.app/Contents/MacOS/"* "$DESTRES/bin/Assistant.app/Contents/MacOS/"*; do
        process_binary $ARCH "$DESTRES" "$exe"
    done

    # Copy plugins.
    for f in ${PLUGINS[*]}; do
        cp -r "$QTDIR/plugins/$f" "$DESTRES/plugins/$f"
    done

    # Copy translation files.
    for f in ${TRANSLATIONS[*]}; do
        cp "$QTDIR/translations/"${f}_*.qm "$DESTRES/translations"
    done

    # Copy documentation files.
    for f in ${DOCS[*]}; do
        cp "$QTDOCDIR/$f.qch" "$DESTRES/docs"
    done

    # Adjust architecture on shared libraries. Take care of spaces in file paths.
    find "$DESTAPP" -name '*.dylib' | while IFS= read file; do
        remove_other_arch $ARCH "$file"
    done

    # Adjust configuration to documentation files.
    QTCONF="$DESTRES/bin/Assistant.app/Contents/Resources/qt.conf"
    sed -e 's/Documentation=.*/Documentation=docs/' "$QTCONF" >"$QTCONF.new"
    mv "$QTCONF.new" "$QTCONF"

    # Adjust protections.
    find "$DESTAPP" \( -type d -o -name '*.dylib' \) -exec chmod 755 {} \;
    find "$DESTAPP" \( -name '*.qm' -o -name '*.qch' -o -name '*.conf' \) -exec chmod 644 {} \;

    # Cleanup Apple attributes. So far, com.apple.provenance cannot be deleted from userspace because of SIP.
    for attr in com.apple.provenance com.apple.quarantine; do
        xattr -dr $attr "$VOLROOT"
    done

    # The global app is a script running Linguist.
    APPSCRIPT="$DESTAPP/Contents/MacOS/$DESTNAME"
    echo '#!/bin/sh' >"$APPSCRIPT"
    echo 'dir=$(dirname "$0")' >>"$APPSCRIPT"
    echo 'exec "$dir/../Resources/bin/Linguist.app/Contents/MacOS/Linguist"' >>"$APPSCRIPT"
    chmod 755 "$APPSCRIPT"

    # The Finder cannot determine the architecture from a shell script.
    # On arm64 system, it requires Rosetta to be installed, even if the application is fully arm64.
    # Force the architecture so that the Finder stops asking.
    cat >"$DESTAPP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>LSArchitecturePriority</key>
<array>
<string>$ARCH</string>
</array>
</dict>
</plist>
EOF

    # Set the icon for the outer Linguist bundle.
    set_icon "$QTBINDIR/Linguist.app/Contents/Resources/linguist.icns" "$DESTAPP"

    # Create a symbolic link to /Applications to facilitate the drag & drop.
    ln -sf /Applications "$VOLROOT/Applications"

    # Format the appearance of the DMG in Finder when opened.
    mkdir -p "$VOLROOT/.background"
    cp $ROOTDIR/images/dmg-background.png "$VOLROOT/.background/background.png"
    SetFile -a V "$VOLROOT/.background"
    echo '
       tell application "Finder"
         tell disk "'${VOLUME}'"
               open
               set current view of container window to icon view
               set toolbar visible of container window to false
               set statusbar visible of container window to false
               set the bounds of container window to {400, 100, 900, 450}
               set theViewOptions to the icon view options of container window
               set arrangement of theViewOptions to not arranged
               set icon size of theViewOptions to 128
               set background picture of theViewOptions to file ".background:background.png"
               set position of item "Qt Linguist" of container window to {100, 100}
               set position of item "Applications" of container window to {375, 100}
               update without registering applications
               delay 3
               close
         end tell
       end tell
    ' | osascript

    # Add a drive icon.
    cp "$ROOTDIR/images/linguist-drive.icns" "$VOLROOT/.VolumeIcon.icns"
    SetFile -a C "$VOLROOT"
    SetFile -a V "$VOLROOT/.VolumeIcon.icns"

    # Unmount the disk image
    hdiutil detach $DEV

    # Convert the disk image to read-only
    rm -rf "$DMGFILE"
    hdiutil convert "$DMGTMP" -format UDZO -o "$DMGFILE"
    rm -rf "$TMPDIR"
}

# Create one installer per architecture.
for a in ${ARCHITECTURES[*]}; do
    build_dmg $a
done
