#!/usr/bin/env -S bash -e

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# export the libraray
set -a
source $SCRIPT_DIR/.scripts/lib.sh
set +a

clear
echo
echo_msg "      ███╗░░██╗░█████╗░███╗░░██╗░█████╗░░█████╗░██████╗░░█████╗░██╗░░██╗"
echo_msg "      ████╗░██║██╔══██╗████╗░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║░░██║"
echo_msg "      ██╔██╗██║██║░░██║██╔██╗██║██║░░██║███████║██████╔╝██║░░╚═╝███████║"
echo_msg "      ██║╚████║██║░░██║██║╚████║██║░░██║██╔══██║██╔══██╗██║░░██╗██╔══██║"
echo_msg "      ██║░╚███║╚█████╔╝██║░╚███║╚█████╔╝██║░░██║██║░░██║╚█████╔╝██║░░██║"
echo_msg "      ╚═╝░░╚══╝░╚════╝░╚═╝░░╚══╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝"
echo_msg "--------------------------------------------------------------------------------"
echo_msg "                         Easy | Quick |  Custom"
echo_msg "              Installer script for Arch Linux written by nonoMain"
echo_msg "--------------------------------------------------------------------------------"
echo
echo_msg "Note: this is what a message from this script looks like"
echo_warning_msg "Note: this is what a warning from this script looks like"
echo_error_msg "Note: this is what a error from this script looks like"
echo

echo_msg "Info loading (info from 'setup.yml') [This occures before the different scripts runs]"
parse_info
cat > $SCRIPT_DIR/setup.sh <<EOF
$(parse_yaml $SCRIPT_DIR/setup.yml)
parsed_info_has_swap=${parsed_info_has_swap@Q}
parsed_info_has_boot=${parsed_info_has_boot@Q}
parsed_info_has_home=${parsed_info_has_home@Q}
OUTPUTFILE=${OUTPUTFILE@Q}
EOF

echo
wait_for_any_key_press "If you are ready, press [any key] to start.. "
echo_msg "The installation will start now, please be patient"

# export the setup info for scripts that run in this shell
set -a
source $SCRIPT_DIR/setup.sh
set +a

$SCRIPT_DIR/.scripts/setup-live-env.sh

if [ $disk_auto_allocate == 'true' ]; then
	$SCRIPT_DIR/.scripts/partitioner.sh
fi

/bin/bash -e <<EOF
$(cat $SCRIPT_DIR/setup.sh)
$(cat $SCRIPT_DIR/.scripts/lib.sh)
$(cat $SCRIPT_DIR/.scripts/installer-live.sh)
EOF

# copy the .toInstall directory to the root of the new system
mkdir -p /mnt/root/
cp -r $SCRIPT_DIR/.toInstall/ /mnt/root/

arch-chroot /mnt /bin/bash -e <<EOF
$(cat $SCRIPT_DIR/setup.sh)
$(cat $SCRIPT_DIR/.scripts/lib.sh)
$(cat $SCRIPT_DIR/.scripts/installer-chroot.sh)
EOF

# copy the .toInstall directory to the home of the new user on the new system
mkdir -p /mnt/home/$admin_user_name/
cp -r $SCRIPT_DIR/.toInstall/ /mnt/home/$admin_user_name/

arch-chroot /mnt /usr/bin/runuser -u $admin_user_name -- /bin/bash -e <<EOF
$(cat $SCRIPT_DIR/setup.sh)
$(cat $SCRIPT_DIR/.scripts/lib.sh)
$(cat $SCRIPT_DIR/.scripts/user.sh)
EOF

arch-chroot /mnt /bin/bash -e <<EOF
$(cat $SCRIPT_DIR/setup.sh)
$(cat $SCRIPT_DIR/.scripts/lib.sh)
$(cat $SCRIPT_DIR/.scripts/post-live-env.sh)
EOF
