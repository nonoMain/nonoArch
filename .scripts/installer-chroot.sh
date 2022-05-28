#!/usr/bin/env -S bash -e
# @file installer-chroot
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

##------------------------don't touch----------------------##

timezone_link_data=$(curl -s https://ipapi.co/timezone)

download_packages_from_file ()
{
	local file_name="$1"
	local title=""
	cat "$file_name" | while read -r line; do
		if [[ "$line" =~ ^#.* ]]; then
			title="$line"
		elif [[ "$line" =~ ^$ ]]; then
			continue
		else
			echo_msg "Installing(pacman) F:$(basename $file_name)	$title	P:$line"
			sudo pacman -S --noconfirm --needed ${line} || echo_error_msg "Failed to download package: $line"
		fi
	done
}

##--------------------------code---------------------------##

echo_msg "--------------------------------------------------------------------------------"
echo_msg "        Setting up mirrors, keys and parallel Downloading for downloads"
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
echo_msg "                      Set timezone to $timezone_link_data"
echo_msg "--------------------------------------------------------------------------------"
ln -sf /usr/share/zoneinfo/$timezone_link_data /etc/localtime

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                           Setting up the clock"
echo_msg "--------------------------------------------------------------------------------"
# Setting up clock.
hwclock --systohc
echo_msg "--------------------------------------------------------------------------------"
echo_msg "                Generating and setting up language as US and locales"
echo_msg "--------------------------------------------------------------------------------"

echo_msg "set en_US locale"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
# sed -i 's/^#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
if [[ $(curl -s https://ifconfig.co/country-iso) == 'IL' ]]; then
	echo_msg "set he_IL locale"
	sed -i 's/^#he_IL.UTF-8 UTF-8/he_IL.UTF-8 UTF-8/' /etc/locale.gen
	# sed -i 's/^#he_IL ISO-8859-8/he_IL ISO-8859-8/' /etc/locale.gen
fi

locale-gen
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
localectl --no-ask-password set-keymap 'us'

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Installing grub
if [[ $parsed_info_has_boot == 'true' ]]; then
	# check if we have uefi or bios
	if [[ -d /sys/firmware/efi ]]; then
		echo_msg "--------------------------------------------------------------------------------"
		echo_msg "                          Installing UEFI bootloader"
		echo_msg "--------------------------------------------------------------------------------"
		pacman -S --noconfirm --needed grub efibootmgr
		grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=grub_uefi
		grub-mkconfig -o /boot/grub/grub.cfg
	else
		echo_msg "--------------------------------------------------------------------------------"
		echo_msg "                          Installing BIOS bootloader"
		echo_msg "--------------------------------------------------------------------------------"
		pacman -S --noconfirm --needed grub
		grub-install --target=i386-pc --boot-directory=/boot/
		grub-mkconfig -o /boot/grub/grub.cfg
	fi

	# Creating grub config file.
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                       Creating Bootloader config file"
	echo_msg "--------------------------------------------------------------------------------"
	grub-mkconfig -o /boot/grub/grub.cfg
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                         Adding user $admin_user_name as admin"
echo_msg "--------------------------------------------------------------------------------"
useradd -m $admin_user_name
usermod -aG wheel,tty $admin_user_name

echo "root:$root_user_password" | chpasswd
echo "$admin_user_name:$admin_user_password" | chpasswd

# Installation files
# desk.aurs.dev.txt
# desk.packages.creative.txt
# desk.packages.dev.txt
# desk.packages.gnome.txt
# desk.packages.kde.txt
# desk.packages.must.txt
# desk.packages.office.txt
# desk.packages.utils.txt
# desk.packages.xfce.txt
# term.aurs.dev.txt
# term.packages.dev.txt
# term.packages.must.txt
# term.packages.utils.txt

# Auto install must packages
# and install the rest based on the variables:
# to_install_term_utils='true'
# to_install_term_dev='true'
# to_install_desk_utils='true'
# to_install_desk_dev='true'
# to_install_desk_creative='true'
# to_install_desk_office='true'

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                         Installing terminal packages"
echo_msg "--------------------------------------------------------------------------------"
download_packages_from_file "$HOME/.toInstall/term.packages.must.txt"
[[ "$to_install_term_utils" == 'true' ]] && download_packages_from_file "$HOME/.toInstall/term.packages.utils.txt"
[[ "$to_install_term_dev" == 'true' ]] && download_packages_from_file "$HOME/.toInstall/term.packages.dev.txt"

if [[ "$system_desktop_environment" != 'server' ]]; then
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                 Installing desktop packages for $system_desktop_environment"
	echo_msg "--------------------------------------------------------------------------------"
	download_packages_from_file "$HOME/.toInstall/desk.packages.must.txt"
	[[ "$to_install_desk_utils" == 'true' ]] && download_packages_from_file "$HOME/.toInstall/desk.packages.utils.txt"
	[[ "$to_install_desk_dev" == 'true' ]] && download_packages_from_file "$HOME/.toInstall/desk.packages.dev.txt"
	[[ "$to_install_desk_creative" == 'true' ]] && download_packages_from_file "$HOME/.toInstall/desk.packages.creative.txt"
	[[ "$to_install_desk_office" == 'true' ]] && download_packages_from_file "$HOME/.toInstall/desk.packages.office.txt"

	if [[ "$system_desktop_environment" == 'kde' ]]; then
		download_packages_from_file "$HOME/.toInstall/desk.packages.kde.txt"
	elif [[ "$system_desktop_environment" == 'gnome' ]]; then
		download_packages_from_file "$HOME/.toInstall/desk.packages.gnome.txt"
	elif [[ "$system_desktop_environment" == 'xfce' ]]; then
		download_packages_from_file "$HOME/.toInstall/desk.packages.xfce.txt"
	fi
fi

# Lighdm 
sed -i 's/^#logind-check-graphical=true/logind-check-graphical=true/' /etc/lightdm/lightdm.conf
