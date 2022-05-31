# nonoArch.git - Arch install script
This is a set of bash scripts meant to install an Arch machine with ease
<p align="center">
  <img src="https://img.shields.io/github/repo-size/nonomain/nonoArch?style=for-the-badge">
</p>

## Installation
### Create a live boot with the arch ISO
Download the [arch iso](https://archlinux.org/download/) and load it onto a USB stick (I recommend you use something like [Etcher](https://www.balena.io/etcher/))

### Pre-run steps
1. find the path to the disk you want to install arch on or the paths to the partitions you already have
> e.g: fdisk -l
2. set the EDITOR environment variable to your favorite terminal editor
> e.g: export EDITOR=vim (vim is default, nano is good for beginners)
3. read the docs that at the beginning of the [setup file](./setup.yml)
> there are multiple options other then the default so read all of it

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

### Install configurations
The script will install an entire system with a login manager and a desktop environment
with my favorite programs and tools which can all be edited and configured [here](./.toInstall/)
Note: the script has the option to restore a pre archived configuration
using [keeper](https://github.com/nonoMain/keeper)

## Troubleshooting
### Internet access

```bash
# You can test if you have internet connection by running
ping google.com
```

You need internet access in order to install a new system so make sure you have either Ethernet
or wifi

If Ethernet isn't an option you can connect to wifi (if your machine has that ability) . Go through these 7 steps:
```bash
# No WIFI?!?!
# You can check if the wifi is blocked by running:
rfkill list
# If it says Soft blocked: yes then run
rfkill unblock wifi
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
```

### Information sources
1. [Arch wiki](https://wiki.archlinux.org/title/Installation_guide)
2. [Nice install guide](https://github.com/rickellis/Arch-Linux-Install-Guide)

### Redo the installation
If the script crashed and the logs don't help you that much so I'd recommend to rerun the installation (not so time consuming)
in order to rerun the script just run:
```bash
# You can see the disk you chose in the 'setup.yml' file
sgdisk -Zo <path/to/the/disk>
# reboot the live system (it will lose all the installation files)
reboot
# now just rerun the installation command that specified at the beginning of this README.md
```

### Scripts by order
The script that runs is [nonoArch.sh](./nonoArch.sh) and it executes the other scripts in this order:
1. [setup-live-env.sh](./.scripts/setup-live-env.sh) - runs on the live environment as root
2. [partitioner.sh](./.scripts/partitioner.sh) - runs on the live environment as root (optional, if you want to fully partition a disk)
3. [installer-live.sh](./.scripts/installer-live.sh) - runs on the live environment as root
4. [installer-chroot.sh](./.scripts/installer-chroot.sh) - runs on the installed system as root
5. [user.sh](./.scripts/user.sh) - runs on the installed system as admin user
6. [post-live-env.sh](./.scripts/post-live-env.sh) - runs on the live environment as root

## Notes
This script is a reupload of an old Arch install script of mine.
The script is installing arch in a way that I think is good and if you are not me this will very likely won't
be well suited for you so I'd recommend looking at the way I did it and fork it to be just like you want it,
I recommend building of my repository and not others simply because how light it is compared to other scripts that
does the same stuff.

### Credits
the ASCII art is from [fsymbols](https://fsymbols.com/generators/carty/)
the project that my first arch installer was based upon was [easy-arch](https://github.com/classy-giraffe/easy-arch)
a project that I took nice design ideas (the bios grub support, the logs, the different desktop environments) from was [ArchTitus](https://github.com/ChrisTitusTech/ArchTitus)

### Alternatives
there are two ways you can look at it, if you want more minimal script that works great then defintley take a look at [easy-arch](https://github.com/classy-giraffe/easy-arch)
if you were looking to somethings even more comfortable and easy then use [ArchTitus](https://github.com/ChrisTitusTech/ArchTitus)
