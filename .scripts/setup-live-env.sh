#!/usr/bin/env -S bash -e
# @file setup-live-env
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

echo_msg "--------------------------------------------------------------------------------"
echo_msg "              Setup the environment for the installation                        "
echo_msg "--------------------------------------------------------------------------------"

echo_msg "--------------------------------------------------------------------------------"
echo_msg "        Setup mirrors, keys and parallel download for downloading packages"
echo_msg "--------------------------------------------------------------------------------"

timedatectl set-ntp true

# setup the mirror list
pacman -S --noconfirm --needed pacman-contrib curl
pacman -S --noconfirm --needed reflector rsync grub arch-install-scripts git
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
# update keyring
pacman -S --noconfirm archlinux-keyring
pacman -S --noconfirm --needed pacman-contrib
setup_mirrors_using_reflector

sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

echo_msg "--------------------------------------------------------------------------------"
echo_msg "       Installing utils needed for the rest of the script (in this env)"
echo_msg "--------------------------------------------------------------------------------"

pacman -S --noconfirm --needed gptfdisk glibc

echo_msg "--------------------------------------------------------------------------------"
echo_msg "               Unmounting everything before the installation"
echo_msg "--------------------------------------------------------------------------------"

umount -A --recursive /mnt || true
