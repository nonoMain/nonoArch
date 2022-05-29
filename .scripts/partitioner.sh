#!/usr/bin/env -S bash -e
# @file partitioner
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

##------------------------don't touch----------------------##

# sgdisk typecodes:
LINUX_FILESYSTEM='8300'
LINUX_HOME='8302'
LINUX_SWAP='8200'
EFIBOOT='ef00'
BIOSBOOT='ef02'

drive=$disk_path;
pn=1;
boot_partition=''
swap_partition=''
root_partition=''
home_partition=''

##--------------------------code---------------------------##

sgdisk -Zo ${disk_path} # zap all on disk
sgdisk -a 2048 -o ${disk_path} # new gpt disk 2048 alignment

if [[ "${disk_path}" =~ "nvme" ]]; then
	delimiter='p'
else
	delimiter=''
fi

if [[ "$parsed_info_has_boot" == 'true' ]] ;then
	boot_size=$disk_partitions_boot_size;
	echo_msg "${pn}. Creating BIOS boot partition - ${drive}${pn}: +1M"
	sgdisk -n $pn::+1M --typecode=$pn:$BIOSBOOT --change-name=$pn:'BIOSBOOT' ${drive} # bios partition (boot)
	pn=$((pn+1))
	echo_msg "${pn}. Creating EFI boot partition - ${drive}${pn}: $boot_size"
	sgdisk -n $pn::$boot_size --typecode=$pn:$EFIBOOT --change-name=$pn:'EFIBOOT' ${drive} # uefi partition (boot)
	boot_partition=${disk_path}$delimiter$pn
	pn=$((pn+1))
	if [[ ! -d "/sys/firmware/efi" ]]; then
		sgdisk -A 1:set:2 ${drive} # set bootable flag on bios partition
	fi
fi

if [[ "$parsed_info_has_swap" == 'true' ]] ;then
	swap_size=$disk_partitions_swap_size;
	echo_msg "${pn}. Creating swap partition - ${drive}${pn}: $swap_size"
	sgdisk -n $pn::$swap_size --typecode=$pn:$LINUX_SWAP --change-name=$pn:'SWAP' ${drive} # swap partition
	swap_partition=${disk_path}$delimiter$pn
	pn=$((pn+1))
fi

root_size=$disk_partitions_root_size;
echo_msg "${pn}. Creating root partition - ${drive}${pn}: $root_size"
sgdisk -n $pn::$root_size --typecode=$pn:$LINUX_FILESYSTEM --change-name=$pn:'ROOT' ${drive} # root partition
root_partition=${disk_path}$delimiter$pn
pn=$((pn+1))

if [[ "$parsed_info_has_home" == 'true' ]]; then
	home_size=$disk_partitions_home_size;
	echo_msg "${pn}. Creating home partition - ${drive}${pn}: $home_size"
	sgdisk -n $pn::$home_size --typecode=$pn:$LINUX_HOME --change-name=$pn:'HOME' ${drive} # home partition
	home_partition=${disk_path}$delimiter$pn
	pn=$((pn+1))
fi

cat >> $SCRIPT_DIR/setup.sh <<EOF
## Injected by the Auto allocator (partitioner.sh) ##
disk_partitions_boot_partition='$boot_partition'
disk_partitions_swap_partition='$swap_partition'
disk_partitions_root_partition='$root_partition'
disk_partitions_home_partition='$home_partition'
EOF

# Reread partition table
partprobe ${disk_path}
