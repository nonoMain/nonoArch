# nonoArch.git - Arch install script
This is a set of scripts meant to install an Arch machine with ease
<p align="center">
  <img src="https://img.shields.io/github/repo-size/nonomain/nonoArch?style=for-the-badge">
</p>

## Todo:
- add tests for disk and boolean answers
- clear out the parser messages and show the unprivate values
- add keeper configs
- add readme credits
- add more troubleshooting info

## The installation
### Create a live boot with the arch ISO
Download the [arch iso](https://archlinux.org/download/) and load it onto a USB stick (I recommend you use something like [Etcher](https://www.balena.io/etcher/))

### Pre-run steps
1. find the path to the disk you want to install on / the paths to the partitions you have already
> e.g: fdisk -l
2. set the EDITOR environment variable to your favorite terminal editor
> e.g: export EDITOR=vim
3. read the docs that at the beginning of the [setup file](./setup.yml)
> there are multiple options other then the default so read them

### Boot into the live boot and run:
```bash
# Make sure $EDITOR is a terminal editor you are comfortable with and is installed on the live boot
bash <(curl -sL bit.ly/nonoArchStepsSh)
```
Note: the above script is in [here](./.howto.sh)
and can be replaced by:
```bash
# make sure you have the needed tools installed
pacman -Sy --noconfirm --needed curl unzip $EDITOR

# shortend link (full link is https://github.com/nonoMain/nonoArch/archive/master.zip)
curl -sL 'bit.ly/nonoArchMasterZip' -o nonoArch.master.zip

# Unzip the project archive
unzip ./nonoArch.master.zip

cd nonoArch-master

# Edit the 'setup.yml' file using a terminal text editor
$EDITOR ./setup.yml

# Run the installer
./nonoArch.sh
```

## installation configuration
the script will install an entire system with a login manager and a desktop environment
with my favorite programs and tools which can all be edited and configured [here](./.toInstall/)
Note: the script has the option to restore a pre archived configuration
using [keeper](https://github.com/nonoMain/keeper)

## Troubleshooting
### Internet access
You need internet access in order to install a new system so make sure you have either Ethernet
or Wifi
#### No Wifi?

You can check if the WiFi is blocked by running `rfkill list`.
If it says **Soft blocked: yes**,
then run `rfkill unblock wifi`

After unblocking the WiFi, you can connect to it. Go through these 7 steps:

```bash
# Enter into the network manager
iwctl
# find your device name
device list
station [device name] scan
# find your network
station [device name] get-networks
station [device name] connect [network name]
# enter your password and exit
exit
# You can test if you have internet connection by running
ping google.com
```

### Script crashed
The script that runs is [nonoArch.sh](./nonoArch.sh) and it executes the other scripts in this order:
1. [setup-live-env.sh](./.scripts/setup-live-env.sh) - runs on the live environment as root
2. [partitioner.sh](./.scripts/partitioner.sh) - runs on the live environment as root (optional, if you want to fully partition a disk)
3. [installer-live.sh](./.scripts/installer-live.sh) - runs on the live environment as root
4. [installer-chroot.sh](./.scripts/installer-chroot.sh) - runs on the installed system as root
5. [user.sh](./.scripts/user.sh) - runs on the installed system as admin user (optional, if you have a user)

## Credits
the ASCII art is from [fsymbols](https://fsymbols.com/generators/carty/)
