#!/usr/bin/env -S bash -e

# make sure you have the needed tools installed
pacman -Sy --noconfirm --needed curl unzip

# shortend link (full link is https://github.com/nonoMain/nonoArch/archive/master.zip)
curl -sL 'bit.ly/nonoArchMasterZip' -o nonoArch.master.zip

# Unzip the project archive
unzip ./nonoArch.master.zip

cd nonoArch-master

# Edit the 'setup.yml' file using a terminal text editor
$EDITOR ./setup.yml

# Run the installer
./nonoArch.sh
