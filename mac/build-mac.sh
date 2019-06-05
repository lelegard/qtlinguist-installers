#!/bin/bash
#-----------------------------------------------------------------------------
#
#  Copyright (c) 2016-2018, Thierry Lelegard
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
#  Shell script to build the DMG package for Qt Linguist on Mac OS.
#
#-----------------------------------------------------------------------------

# This script:
SCRIPT=$(basename $BASH_SOURCE)
error() { echo >&2 "$SCRIPT: $*"; exit 1; }

# Uncompressed DMG size.
DMGSIZE=64m

# Get and verify Qt installation path
QTDIR=${1:-$QTDIR}
[[ -z "$QTDIR" ]] && error "Path to Qt installation must be given as parameter or via environment variable QTDIR"
QTBINDIR="$QTDIR/bin"
[[ ! -f "$QTBINDIR/qmake" ]] && error "Could not find qmake in $QTBINDIR"

# Various directories.
SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
ROOTDIR=$(dirname $SCRIPTDIR)
TMPDIR=$SCRIPTDIR/tmp

# Liguist is bundled in same directory as qmake.
LINGDIR="$QTBINDIR/Linguist.app"
[[ -x "$LINGDIR/Contents/MacOS/Linguist" ]] || error "Linguist not found in $LINGDIR"

# Get Qt version from qmake.
VERSION=$("$QTBINDIR/qmake" --version | grep -o '[Qq]t [Vv]ersion [0-9][0-9\.-]*' | sed -e 's/^[Qq]t [Vv]ersion //')
[[ -z "$VERSION" ]] && error "Could not determine Qt version"

echo "Using Qt $VERSION from $QTDIR"

# The DMG will be initially created into TMPDIR, later converted into installers.
DMGTMP="$TMPDIR/QtLinguist.dmg"
DMGFILE="$ROOTDIR/installers/QtLinguist-$VERSION.dmg"
VOLUME="Qt Linguist $VERSION"
VOLROOT="/Volumes/$VOLUME"
VOLAPP="$VOLROOT/Qt Linguist.app"

# Create DMG file.
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"
hdiutil create -size $DMGSIZE -fs HFS+ -volname "$VOLUME" "$DMGTMP"

# Mount the disk image
hdiutil attach "$DMGTMP"
DEVS=$(hdiutil attach "$DMGTMP" | cut -f 1)
DEV=$(echo $DEVS | cut -f 1 -d ' ')

# Copy Linguist into disk image
cp -rp "$LINGDIR" "$VOLAPP"

# Deploy Qt requirements in the bundle.
$QTBINDIR/macdeployqt "$VOLAPP" -verbose=1 -always-overwrite

# Install translations in the bundle.
APPTRANS="$VOLAPP/Contents/Resources/translations"
mkdir -p "$APPTRANS"
for app in linguist qt qtbase qtscript qtquick1 qtmultimedia qtxmlpatterns; do
    cp "$QTDIR"/translations/${app}_*.qm "$APPTRANS"
done
chmod 755 "$APPTRANS"
chmod 644 "$APPTRANS"/*

# Declare the translation directory in qt.conf.
# The file qt.conf shall have been created by macdeployqt.
QTCONF="$VOLAPP/Contents/Resources/qt.conf"
[[ -e "$QTCONF" ]] || error "$QTCONF not found"
echo "Translations = Resources/translations" >>"$QTCONF"

# Need to patch "cmd LC_RPATH" in "$VOLAPP/Contents/MacOS/Linguist"
# from @loader_path/../../../../lib
# to   @executable_path/../Frameworks
install_name_tool "$VOLAPP/Contents/MacOS/Linguist" -rpath @loader_path/../../../../lib @executable_path/../Frameworks 

# Create a symbolic link to /Applications to facilitate the drag & drop.
ln -sf /Applications "$VOLROOT/Applications"

# Add a drive icon
cp "$ROOTDIR/images/linguist-drive.icns" "$VOLROOT/.VolumeIcon.icns"
SetFile -c icnC "$VOLROOT/.VolumeIcon.icns"
SetFile -a C "$VOLROOT"

# Format the appearance of the DMG in Finder when opened.
mkdir -p "$VOLROOT/.background"
cp $ROOTDIR/images/dmg-background.png "$VOLROOT/.background/background.png"
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
           delay 5
           close
     end tell
   end tell
' | osascript

# Unmount the disk image
hdiutil detach $DEV

# Convert the disk image to read-only
rm -rf "$DMGFILE"
hdiutil convert "$DMGTMP" -format UDZO -o "$DMGFILE"
rm -rf "$TMPDIR"

# Export the binaries to a shared environment, if it exists.
# Define the environment variable DELIVERY to point to the shared export.
# Default value:
DELIVERY_DIR=${DELIVERY:-$HOME/devel}/qtlinguist-installers/installers
[[ -d "$DELIVERY_DIR" ]] && cp -v "$DMGFILE" "$DELIVERY_DIR"
