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
echo_msg_tty "                 (default user: admin, default password: 1234)"
echo_msg_tty "--------------------------------------------------------------------------------"
echo

echo_msg_tty "Info loading (info from 'setup.yml') [This occures before the different scripts runs]"
parse_info
# write the info into a setup.sh file for the different scripts to use
generate_info_bash_file
echo
wait_for_any_key_press "If you are ready, press [any key] to start.. "
echo_msg_tty "The installation will start now, please be patient"

# export the setup info for scripts that run in this shell
set -a
source $SCRIPT_DIR/setup.sh
set +a

mkdir -p $SCRIPT_DIR/logs

$SCRIPT_DIR/.scripts/setup-live-env.sh &> $SCRIPT_DIR/logs/setup-live-env.log && worked="true" || worked="false"
if [ "$worked" == "true" ]; then
	echo_ok_msg_tty "The setup-live-env.sh script ran successfully"
else
	echo_error_msg_tty "The setup-live-env.sh script failed"
	echo_warning_msg_tty "This is a fatal error, the installation will not continue"
	echo_msg_tty "Please check the log file: $SCRIPT_DIR/logs/setup-live-env.log"
	exit 1
fi

if [ $disk_auto_allocate == 'true' ]; then
	$SCRIPT_DIR/.scripts/partitioner.sh &> $SCRIPT_DIR/logs/partitioner.log && worked="true" || worked="false"
	if [ "$worked" == "true" ]; then
		echo_ok_msg_tty "The partitioner script ran successfully"
	else
		echo_error_msg_tty "The partitioner script failed"
		echo_warning_msg_tty "This is a fatal error, the installation will not continue"
		echo_msg_tty "Please check the log file: $SCRIPT_DIR/logs/partitioner.log"
		exit 1
	fi
fi

/bin/bash -e <<EOF &> $SCRIPT_DIR/logs/installer-live.log && worked="true" || worked="false"
	$(cat $SCRIPT_DIR/setup.sh)
	$(cat $SCRIPT_DIR/.scripts/lib.sh)
	$(cat $SCRIPT_DIR/.scripts/installer-live.sh)
EOF
if [ "$worked" == "true" ]; then
	echo_ok_msg_tty "The installer-live.sh script ran successfully"
else
	echo_error_msg_tty "The installer-live.sh script failed"
	echo_warning_msg_tty "This is a fatal error, the installation will not continue"
	echo_msg_tty "Please check the log file: $SCRIPT_DIR/logs/installer-live.log"
	exit 1
fi

# copy the .toInstall directory to the root of the new system
mkdir -p /mnt/root/
cp -r $SCRIPT_DIR/.toInstall/ /mnt/root/

arch-chroot /mnt /bin/bash -e <<EOF &> $SCRIPT_DIR/logs/installer-chroot.log && worked="true" || worked="false"
	$(cat $SCRIPT_DIR/setup.sh)
	$(cat $SCRIPT_DIR/.scripts/lib.sh)
	$(cat $SCRIPT_DIR/.scripts/installer-chroot.sh)
EOF
if [ "$worked" == "true" ]; then
	echo_ok_msg_tty "The installer-chroot.sh script ran successfully"
else
	echo_error_msg_tty "The installer-chroot.sh script failed"
	echo_warning_msg_tty "This is a fatal error, the installation will not continue"
	echo_msg_tty "Please check the log file: $SCRIPT_DIR/logs/installer-chroot.log"
	exit 1
fi

# copy the .toInstall directory to the home of the new user on the new system
mkdir -p /mnt/home/$admin_user_name/
cp -r $SCRIPT_DIR/.toInstall/ /mnt/home/$admin_user_name/

arch-chroot /mnt /usr/bin/runuser -u $admin_user_name -- /bin/bash -e <<EOF &> $SCRIPT_DIR/logs/user.log && worked="true" || worked="false"
	$(cat $SCRIPT_DIR/setup.sh)
	$(cat $SCRIPT_DIR/.scripts/lib.sh)
	$(cat $SCRIPT_DIR/.scripts/user.sh)
EOF
if [ "$worked" == "true" ]; then
	echo_ok_msg_tty "The user.sh script ran successfully"
else
	echo_error_msg_tty "The user.sh script failed"
	echo_msg_tty "Please check the log file: $SCRIPT_DIR/logs/user.log"
	echo_warning_msg_tty "This is not a fatal error, the installation will continue (if you want to)"
	wait_for_any_key_press "Press [any key] to continue.. [or Ctrl+C to break]"
fi

arch-chroot /mnt /bin/bash -e <<EOF &> $SCRIPT_DIR/logs/post-live-env.log && worked="true" || worked="false"
	$(cat $SCRIPT_DIR/setup.sh)
	$(cat $SCRIPT_DIR/.scripts/lib.sh)
	$(cat $SCRIPT_DIR/.scripts/post-live-env.sh)
EOF
if [ "$worked" == "true" ]; then
	echo_ok_msg_tty "The post-live-env.sh script ran successfully"
else
	echo_error_msg_tty "The post-live-env.sh script failed"
	echo_msg_tty "Please check the log file: $SCRIPT_DIR/logs/post-live-env.log"
	echo_warning_msg_tty "This is a fatal error, the installation finished. I'd recommend to run the post-live-env.sh script manually"
fi

if [[ "$advenced_copy_log_to_machine" == 'true' ]]; then
	mkdir -p /mnt/root/nonoArch.logs/
	cp -r $SCRIPT_DIR/logs/* /mnt/root/nonoArch.logs/
	cp $SCRIPT_DIR/setup.sh /mnt/root/nonoArch.logs/
fi

echo_msg_tty "--------------------------------------------------------------------------------"
echo_msg_tty ""
echo_msg_tty "                       ██████╗░░█████╗░███╗░░██╗███████╗"
echo_msg_tty "                       ██╔══██╗██╔══██╗████╗░██║██╔════╝"
echo_msg_tty "                       ██║░░██║██║░░██║██╔██╗██║█████╗░░"
echo_msg_tty "                       ██║░░██║██║░░██║██║╚████║██╔══╝░░"
echo_msg_tty "                       ██████╔╝╚█████╔╝██║░╚███║███████╗"
echo_msg_tty "                       ╚═════╝░░╚════╝░╚═╝░░╚══╝╚══════╝"
echo_msg_tty ""
echo_msg_tty "                            Installation finished"
echo_msg_tty "                 Please eject the installation media and reboot"
echo_msg_tty "--------------------------------------------------------------------------------"
if [[ "$advenced_copy_log_to_machine" == 'true' ]]; then
	echo_msg_tty "           Logs are available at /root/nonoArch.logs on the new system"
	echo_msg_tty "            and also in $SCRIPT_DIR/logs on the live system"
else
	echo_msg_tty "         Logs are available in $SCRIPT_DIR/logs on the live system"
fi
