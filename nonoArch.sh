#!/usr/bin/env -S bash -e

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# export the libraray
set -a
source $SCRIPT_DIR/.scripts/lib.sh
set +a

clear
echo
echo_msg_tty "      ███╗░░██╗░█████╗░███╗░░██╗░█████╗░░█████╗░██████╗░░█████╗░██╗░░██╗"
echo_msg_tty "      ████╗░██║██╔══██╗████╗░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║░░██║"
echo_msg_tty "      ██╔██╗██║██║░░██║██╔██╗██║██║░░██║███████║██████╔╝██║░░╚═╝███████║"
echo_msg_tty "      ██║╚████║██║░░██║██║╚████║██║░░██║██╔══██║██╔══██╗██║░░██╗██╔══██║"
echo_msg_tty "      ██║░╚███║╚█████╔╝██║░╚███║╚█████╔╝██║░░██║██║░░██║╚█████╔╝██║░░██║"
echo_msg_tty "      ╚═╝░░╚══╝░╚════╝░╚═╝░░╚══╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝"
echo_msg_tty "--------------------------------------------------------------------------------"
echo_msg_tty "                         Easy | Quick |  Custom"
echo_msg_tty "              Installer script for Arch Linux written by nonoMain"
echo_msg_tty "--------------------------------------------------------------------------------"
echo
echo_msg_tty "Note: this is what a message from this script looks like"
echo_warning_msg_tty "Note: this is what a warning from this script looks like"
echo_error_msg_tty "Note: this is what a error from this script looks like"
echo

echo_msg_tty "Info loading (info from 'setup.yml') [This occures before the different scripts runs]"
parse_info &> /dev/null
cat > $SCRIPT_DIR/setup.sh <<EOF
system_hostname="$system_hostname"
system_desktop_environment="$system_desktop_environment"
root_user_password="$root_user_password"
admin_user_name="$admin_user_name"
admin_user_password="$admin_user_password"
disk_auto_allocate="$disk_auto_allocate"
disk_path="$disk_path"
disk_partitions_boot_size="$disk_partitions_boot_size"
disk_partitions_swap_size="$disk_partitions_swap_size"
disk_partitions_root_size="$disk_partitions_root_size"
disk_partitions_home_size="$disk_partitions_home_size"
disk_partitions_home_encrypted="$disk_partitions_home_encrypted"
disk_partitions_home_passphrase="$disk_partitions_home_passphrase"
to_install_term_utils="$to_install_term_utils"
to_install_term_dev="$to_install_term_dev"
to_install_desk_utils="$to_install_desk_utils"
to_install_desk_dev="$to_install_desk_dev"
to_install_desk_creative="$to_install_desk_creative"
to_install_desk_office="$to_install_desk_office"
advenced_kernel="$advenced_kernel"
advenced_copy_log_to_machine="$advenced_copy_log_to_machine"
advenced_detect_and_install_vm_utils="$advenced_detect_and_install_vm_utils"
parsed_info_has_swap=$parsed_info_has_swap
parsed_info_has_boot=$parsed_info_has_boot
parsed_info_has_home=$parsed_info_has_home
OUTPUTFILE=${OUTPUTFILE@Q}
EOF

echo
wait_for_any_key_press "If you are ready, press [any key] to start.. "
echo_msg_tty "The installation will start now, please be patient"

# export the setup info for scripts that run in this shell
set -a
source $SCRIPT_DIR/setup.sh
set +a

mkdir -p $SCRIPT_DIR/logs

$SCRIPT_DIR/.scripts/setup-live-env.sh &> $SCRIPT_DIR/logs/setup-live-env.log

if [ $disk_auto_allocate == 'true' ]; then
	$SCRIPT_DIR/.scripts/partitioner.sh &> $SCRIPT_DIR/logs/partitioner.log
fi

/bin/bash -e <<EOF &> $SCRIPT_DIR/logs/installer-live.log
$(cat $SCRIPT_DIR/setup.sh)
$(cat $SCRIPT_DIR/.scripts/lib.sh)
$(cat $SCRIPT_DIR/.scripts/installer-live.sh)
EOF

# copy the .toInstall directory to the root of the new system
mkdir -p /mnt/root/
cp -r $SCRIPT_DIR/.toInstall/ /mnt/root/

arch-chroot /mnt /bin/bash -e <<EOF &> $SCRIPT_DIR/logs/installer-chroot.log
$(cat $SCRIPT_DIR/setup.sh)
$(cat $SCRIPT_DIR/.scripts/lib.sh)
$(cat $SCRIPT_DIR/.scripts/installer-chroot.sh)
EOF

# copy the .toInstall directory to the home of the new user on the new system
mkdir -p /mnt/home/$admin_user_name/
cp -r $SCRIPT_DIR/.toInstall/ /mnt/home/$admin_user_name/

arch-chroot /mnt /usr/bin/runuser -u $admin_user_name -- /bin/bash -e <<EOF &> $SCRIPT_DIR/logs/user.log
$(cat $SCRIPT_DIR/setup.sh)
$(cat $SCRIPT_DIR/.scripts/lib.sh)
$(cat $SCRIPT_DIR/.scripts/user.sh)
EOF

arch-chroot /mnt /bin/bash -e <<EOF &> $SCRIPT_DIR/logs/post-live-env.log
$(cat $SCRIPT_DIR/setup.sh)
$(cat $SCRIPT_DIR/.scripts/lib.sh)
$(cat $SCRIPT_DIR/.scripts/post-live-env.sh)
EOF

if [[ "$advenced_copy_log_to_machine" == 'true' ]]; then
	mkdir -p /mnt/nonoArch.logs/
	cp -r $SCRIPT_DIR/logs/* /mnt/root/nonoArch.logs/
	cp $SCRIPT_DIR/setup.sh /mnt/root/nonoArch.logs/
fi

echo
echo_msg_tty "--------------------------------------------------------------------------------"
echo_msg_tty "                            Installation finished"
echo_msg_tty "                 Please eject the installation media and reboot"
if [[ "$advenced_copy_log_to_machine" == 'true' ]]; then
	echo_msg_tty "            Logs are available at /root/nonoArch.logs on the new system"
	echo_msg_tty "                   and also in $SCRIPT_DIR/logs"
else
	echo_msg_tty "                 Logs are available in $SCRIPT_DIR/logs"
fi
echo_msg_tty "--------------------------------------------------------------------------------"
