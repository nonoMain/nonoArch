#!/usr/bin/env -S bash -e
# @file installer-live
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

##------------------------don't touch----------------------##

pacstrap_package ()
{
	local package=$1; shift
	printf "[ ${MSG_COLOR}MSG${NC} ] Pacstrapping P:%s\n" "$package" > /dev/tty
	printf "[ MSG ] Pacstrapping P:%s\n" "$package"
	( pacstrap /mnt "$package" ) && installed=true || installed=false
	if [ $installed == false ]; then
		echo_warning_msg "Failed to pacstrap package: $package, retrying..."
		( pacstrap /mnt "$package" ) && installed=true || installed=false
		if [ $installed == true ]; then
			echo_ok_msg "Successfully installed package: $package, on retry"
		else
			echo_error_msg "Failed to install package: $package, on retry"
		fi
	fi
}

##--------------------------code---------------------------##

if [[ "$parsed_info_has_home" == 'true' ]]; then
	if [[ "$disk_partitions_home_encrypted" == 'true' ]]; then
		echo_msg "--------------------------------------------------------------------------------"
		echo_msg "                         Encrypting the home partition"
		echo_msg "--------------------------------------------------------------------------------"

		echo -n $disk_partitions_home_passphrase | cryptsetup luksFormat $disk_partitions_home_partition
		echo -n $disk_partitions_home_passphrase | cryptsetup luksOpen $disk_partitions_home_partition 'home-enc'

		ORG_HOME_PARTITION=$disk_partitions_home_partition

		disk_partitions_home_partition="/dev/mapper/home-enc"
	fi
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                             Wiping the partitions"
echo_msg "--------------------------------------------------------------------------------"

wipefs -a -f $disk_partitions_root_partition
if [[ "$parsed_info_has_swap" == 'true' ]]; then
	wipefs -a -f $disk_partitions_swap_partition
fi
if [[ "$parsed_info_has_boot" == 'true' ]]; then
	wipefs -a -f $disk_partitions_boot_partition
fi
if [[ "$parsed_info_has_home" == 'true' ]]; then
	wipefs -a -f $disk_partitions_home_partition
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                              Setting filesystems"
echo_msg "--------------------------------------------------------------------------------"

mkfs.ext4 -L ROOT $disk_partitions_root_partition
[ $parsed_info_has_boot == 'true' ] && mkfs.vfat -F32 -n "EFIBOOT" $disk_partitions_boot_partition
[ $parsed_info_has_home == 'true' ] && mkfs.ext4 -L HOME $disk_partitions_home_partition

if [[ "$parsed_info_has_swap" == 'true' ]]; then
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                           Creating & activating swap"
	echo_msg "--------------------------------------------------------------------------------"

	mkswap $disk_partitions_swap_partition
	swapon $disk_partitions_swap_partition
fi

umount -A --recursive /mnt || true
echo_msg "--------------------------------------------------------------------------------"
echo_msg "                             Mounting the partitions"
echo_msg "--------------------------------------------------------------------------------"

mount $disk_partitions_root_partition /mnt
if [[ "$parsed_info_has_boot" == 'true' ]]; then
	mkdir -p /mnt/boot/efi
	mount $disk_partitions_boot_partition /mnt/boot/
fi
if [[ "$parsed_info_has_home" == 'true' ]]; then
	mkdir /mnt/home
	mount $disk_partitions_home_partition /mnt/home
fi

if ! grep -qs '/mnt' /proc/mounts; then
	echo_msg   "--------------------------------------------------------------------------------"
    echo_error_msg "                       Path /mnt Unmounted so can not continue"
	echo_msg   "--------------------------------------------------------------------------------"
	wait_for_any_key_press "Press any key to reboot"
    reboot
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                             Pacstrapping base system"
echo_msg "--------------------------------------------------------------------------------"
CPU_TYPE=$(grep vendor_id /proc/cpuinfo)
case "$CPU_TYPE" in
	GenuineIntel)
		microcode=intel-ucode
		echo_msg "Intel microcode is being installed"
		;;
	AuthenticAMD)
		microcode=amd-ucode
		echo_msg "AMD microcode is being installed"
		;;
esac

pacstrap_package "base"
pacstrap_package "base-devel"
pacstrap_package "$advenced_kernel"
pacstrap_package "$microcode"
pacstrap_package "linux-firmware"
pacstrap_package "grub"
pacstrap_package "sudo"
pacstrap_package "mtools"
pacstrap_package "os-prober"
pacstrap_package "dosfstools"
pacstrap_package "cryptsetup"
pacstrap_package "networkmanager"

if [[ $advenced_install_vm_utils == 'true' ]]; then
	hypervisor=$(systemd-detect-virt)
	if [[ "$hypervisor" =~ ^(kvm|vmware|oracle|microsoft)$ ]]; then
		echo_msg "--------------------------------------------------------------------------------"
		echo_msg "                    Pacstrapping & enabling $hypervisor utils"
		echo_msg "--------------------------------------------------------------------------------"
		case $hypervisor in
			kvm )
				pacstrap_package "qemu-guest-agent"
				systemctl enable qemu-guest-agent --root=/mnt
				;;
			vmware )
				pacstrap_package "open-vm-tools"
				systemctl enable vmtoolsd --root=/mnt
				systemctl enable vmware-vmblock-fuse --root=/mnt
				;;
			oracle )
				pacstrap_package "virtualbox-guest-utils"
				systemctl enable vboxservice --root=/mnt
				;;
			microsoft )
				pacstrap_package "hyperv"
				systemctl enable hv_fcopy_daemon --root=/mnt
				systemctl enable hv_kvp_daemon --root=/mnt
				systemctl enable hv_vss_daemon --root=/mnt
				;;
		esac
	fi
fi

if [[ "$parsed_info_has_boot" == 'true' ]]; then
	if [[ ! -d /sys/firmware/efi ]]; then
		echo_msg "--------------------------------------------------------------------------------"
		echo_msg "                            Installing BIOS bootloader"
		echo_msg "--------------------------------------------------------------------------------"
		pacman -S --noconfirm --needed grub
		grub-install --boot-directory=/mnt/boot/ $disk_path
	else
		pacstrap_package "efibootmgr"
	fi
fi

if [ "$parsed_info_has_home" == 'true' ] && [ "$disk_partitions_home_encrypted" == 'true' ]; then
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                             Setting decrypt on boot"
	echo_msg "--------------------------------------------------------------------------------"
	home_uuid=$(blkid -o value -s UUID $ORG_HOME_PARTITION)
	echo $home_uuid
	echo "home-enc	UUID="$home_uuid"	none	timeout=180s" >> /mnt/etc/crypttab
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                               Generating fstab"
echo_msg "--------------------------------------------------------------------------------"

genfstab -U /mnt
genfstab -U /mnt >> /mnt/etc/fstab

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                         Setting hostname and hosts file"
echo_msg "--------------------------------------------------------------------------------"
echo $system_hostname > /mnt/etc/hostname

cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $system_hostname.localdomain   $system_hostname
EOF
