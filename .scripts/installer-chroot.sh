#!/usr/bin/env -S bash -e
# @file installer-chroot
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

##------------------------don't touch----------------------##

timezone_link_data=$(curl -s https://ipapi.co/timezone)

install_packages_from_file ()
{
	local file_name="$1"
	local title=""
	cat "$file_name" | while read -r line; do
		if [[ "$line" =~ ^#.* ]]; then
			title="$line"
		elif [[ "$line" =~ ^$ ]]; then
			continue
		else
			printf "[ ${MSG_COLOR}MSG${NC} ] Installing F:%-30s %-25s P:%-25s\n" "$(basename $file_name)" "$title" "$line" > /dev/tty
			printf "[ MSG ] Installing F:%-30s %-25s P:%-25s\n" "$(basename $file_name)" "$title" "$line"
			sudo pacman -S --noconfirm --needed ${line} && installed=true || installed=false
			if [ $installed == false ]; then
				echo_warning_msg "Failed to install package: $line, retrying..."
				sudo pacman -S --noconfirm --needed ${line} && installed=true || installed=false
				if [ $installed == true ]; then
					echo_ok_msg "Successfully installed package: $line, on retry"
				else
					echo_error_msg "Failed to install package: $line, on retry"
				fi
			fi
		fi
	done
}

##--------------------------code---------------------------##

echo_msg "--------------------------------------------------------------------------------"
echo_msg "           Setting up mirrors, keys and parallel Downloading for downloads"
echo_msg "--------------------------------------------------------------------------------"

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
echo_msg "                          Set timezone to $timezone_link_data"
echo_msg "--------------------------------------------------------------------------------"
ln -sf /usr/share/zoneinfo/$timezone_link_data /etc/localtime

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                              Setting up the clock"
echo_msg "--------------------------------------------------------------------------------"
# Setting up clock.
hwclock --systohc

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                Generating and setting up language as US and locales"
echo_msg "--------------------------------------------------------------------------------"

echo_msg "uncommenting en_US locale"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
# sed -i 's/^#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
if [[ $(curl -s https://ifconfig.co/country-iso) == 'IL' ]]; then
	echo_msg "uncommenting he_IL locale"
	sed -i 's/^#he_IL.UTF-8 UTF-8/he_IL.UTF-8 UTF-8/' /etc/locale.gen
	# sed -i 's/^#he_IL ISO-8859-8/he_IL ISO-8859-8/' /etc/locale.gen
fi

echo "LC_ALL=en_US.UTF-8" > /etc/environment
cat > /etc/locale.conf <<EOF
LANG="en_US.UTF-8"
EOF

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                           Setting up XDG ENV Variables"
echo_msg "--------------------------------------------------------------------------------"

cat > /etc/profile.d/0000-xdg-dirs.sh  << EOF
#!/bin/sh

export XDG_CONFIG_HOME="\${HOME}/.config"
export XDG_CACHE_HOME="\${HOME}/.cache"
export XDG_DATA_HOME="\${HOME}/.local/share"
export XDG_STATE_HOME="\${HOME}/.local/state"
EOF

locale-gen

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Installing grub
if [[ $parsed_info_has_boot == 'true' ]]; then
	# check if we have uefi or bios
	if [[ -d /sys/firmware/efi ]]; then
		echo_msg "--------------------------------------------------------------------------------"
		echo_msg "                            Installing UEFI bootloader"
		echo_msg "--------------------------------------------------------------------------------"
		pacman -S --noconfirm --needed grub efibootmgr
		grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=grub_uefi
	fi

	# Creating grub config file.
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                          Creating Bootloader config file"
	echo_msg "--------------------------------------------------------------------------------"
	grub-mkconfig -o /boot/grub/grub.cfg
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                           Adding user $admin_user_name as admin"
echo_msg "--------------------------------------------------------------------------------"
useradd -m $admin_user_name
usermod -aG wheel,tty $admin_user_name

echo "root:$root_user_password" | chpasswd
echo "$admin_user_name:$admin_user_password" | chpasswd

if lspci | grep -E 'NVIDIA|GeForce'; then
	graphics_title='Nvidia graphics'
elif lspci | grep -E 'Radeon'; then
	graphics_title='Radeon graphics'
elif lspci | grep -E 'Integrated Graphics Controller'; then
	graphics_title='Integrated graphics'
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                        Installs & configures $graphics_title"
echo_msg "--------------------------------------------------------------------------------"

if [[ $graphics_title == 'Nvidia graphics' ]]; then
	install_packages_from_file "$HOME/.toInstall/graphics.packages.nvidia.txt"
	nvidia-xconfig
elif [[ $graphics_title == 'Radeon graphics' ]]; then
	install_packages_from_file "$HOME/.toInstall/graphics.packages.radeon.txt"
elif [[ $graphics_title == 'Integrated graphics' ]]; then
	install_packages_from_file "$HOME/.toInstall/graphics.packages.integrated.txt"
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                           Installing terminal packages"
echo_msg "--------------------------------------------------------------------------------"
install_packages_from_file "$HOME/.toInstall/term.packages.must.txt"
[[ "$to_install_term_utils" == 'true' ]] && install_packages_from_file "$HOME/.toInstall/term.packages.utils.txt"
[[ "$to_install_term_dev" == 'true' ]] && install_packages_from_file "$HOME/.toInstall/term.packages.dev.txt"

if [[ "$system_desktop_environment" != 'none' ]]; then
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                        Installing desktop packages [$system_desktop_environment]"
	echo_msg "--------------------------------------------------------------------------------"
	install_packages_from_file "$HOME/.toInstall/desk.packages.must.txt"
	if [[ "$system_desktop_environment" == 'kde' ]]; then
		install_packages_from_file "$HOME/.toInstall/desk.packages.kde.txt"
	elif [[ "$system_desktop_environment" == 'gnome' ]]; then
		install_packages_from_file "$HOME/.toInstall/desk.packages.gnome.txt"
	elif [[ "$system_desktop_environment" == 'xfce' ]]; then
		install_packages_from_file "$HOME/.toInstall/desk.packages.xfce.txt"
	fi

	[[ "$to_install_desk_utils" == 'true' ]] && install_packages_from_file "$HOME/.toInstall/desk.packages.utils.txt"
	[[ "$to_install_desk_dev" == 'true' ]] && install_packages_from_file "$HOME/.toInstall/desk.packages.dev.txt"
	[[ "$to_install_desk_creative" == 'true' ]] && install_packages_from_file "$HOME/.toInstall/desk.packages.creative.txt"
	[[ "$to_install_desk_office" == 'true' ]] && install_packages_from_file "$HOME/.toInstall/desk.packages.office.txt"

	# Lighdm 
	sed -i 's/^#logind-check-graphical=true/logind-check-graphical=true/' /etc/lightdm/lightdm.conf
fi
