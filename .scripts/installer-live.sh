#!/usr/bin/env -S bash -e
# @file installer-live
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

##------------------------don't touch----------------------##

kernel=$advenced_kernel

encrypt_partition()
{
	local passphrase=$1; shift
	local partition=$1; shift
	local name_of_enc_partition=$1; shift

	echo -n $passphrase | cryptsetup luksFormat $partition
	echo -n $passphrase | cryptsetup luksOpen $partition $name_of_enc_partition
}

##--------------------------code---------------------------##

if [[ "$parsed_info_has_home" == 'true' ]]; then
	if [[ "$disk_partitions_home_encrypted" == 'true' ]]; then
		echo_msg "--------------------------------------------------------------------------------"
		echo_msg "                    encrypting the home partition"
		echo_msg "--------------------------------------------------------------------------------"

		encrypt_partition $disk_partitions_home_passphrase $disk_partitions_home_partition $disk_partitions_home_name_after_decryption

		ORG_HOME_PARTITION=$disk_partitions_home_partition

		disk_partitions_home_partition="/dev/mapper/$disk_partitions_home_name_after_decryption"
	fi
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                          wiping the partitions"
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
echo_msg "                            setting filesystems"
echo_msg "--------------------------------------------------------------------------------"

mkfs.ext4 -L ROOT $disk_partitions_root_partition
[ $parsed_info_has_boot == 'true' ] && mkfs.vfat -F32 -n "EFIBOOT" $disk_partitions_boot_partition
[ $parsed_info_has_home == 'true' ] && mkfs.ext4 -L HOME $disk_partitions_home_partition

if [[ "$parsed_info_has_swap" == 'true' ]]; then
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                       Creating & Activating swap"
	echo_msg "--------------------------------------------------------------------------------"

	mkswap $disk_partitions_swap_partition
	swapon $disk_partitions_swap_partition
fi

umount -A --recursive /mnt || true
echo_msg "--------------------------------------------------------------------------------"
echo_msg "                         Mounting the partitions"
echo_msg "--------------------------------------------------------------------------------"

mount $disk_partitions_root_partition /mnt
if [[ "$parsed_info_has_boot" == 'true' ]]; then
	mkdir -p /mnt/boot/
	mount $disk_partitions_boot_partition /mnt/boot/
fi
if [[ "$parsed_info_has_home" == 'true' ]]; then
	mkdir /mnt/home
	mount $disk_partitions_home_partition /mnt/home
fi

if ! grep -qs '/mnt' /proc/mounts; then
	echo_msg   "--------------------------------------------------------------------------------"
    echo_error_msg "                    Path /mnt Unmounted so can not continue"
	echo_msg   "--------------------------------------------------------------------------------"
	wait_for_any_key_press "Press any key to reboot"
    reboot
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                         Installing base system"
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

pacstrap /mnt base base-devel $kernel $microcode linux-firmware \
 grub efibootmgr sudo \
 mtools os-prober dosfstools cryptsetup networkmanager

if [ "$parsed_info_has_home" == 'true' ] && [ "$disk_partitions_home_encrypted" == 'true' ] && [ "$disk_partitions_home_decrypt_on_boot" == 'true' ]; then
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                       Setting decrypt on boot"
	echo_msg "--------------------------------------------------------------------------------"
	home_uuid=$(blkid -o value -s UUID $ORG_HOME_PARTITION)
	echo $home_uuid
	echo "$disk_partitions_home_name_after_decryption	UUID="$home_uuid"	none	timeout=180s" >> /mnt/etc/crypttab
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                         Installs & configures graphics"
echo_msg "--------------------------------------------------------------------------------"
if lspci | grep -E "NVIDIA|GeForce"; then
	echo_msg "Nvidia graphics"
	pacstrap /mnt nvidia nvidia-settings
	nvidia-xconfig
elif lspci | grep -E "Radeon"; then
	echo_msg "Radeon"
	pacstrap /mnt xf86-video-amdgpu
elif lspci | grep -E "Integrated Graphics Controller"; then
	echo_msg "Integrated graphics"
	pacstrap /mnt libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                            Generating fstab"
echo_msg "--------------------------------------------------------------------------------"

genfstab -U /mnt
genfstab -U /mnt >> /mnt/etc/fstab


echo_msg "--------------------------------------------------------------------------------"
echo_msg "                     Setting hostname and hosts file"
echo_msg "--------------------------------------------------------------------------------"
echo $system_hostname > /mnt/etc/hostname

cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $system_hostname.localdomain   $system_hostname
EOF
