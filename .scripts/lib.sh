# colors
bash_lib_define_colors ()
{
	if [[ -z $NO_COLOR ]]; then
		RED='\033[0;31m'
		GREEN='\033[0;32m'
		YELLOW='\033[0;33m'
		BLUE='\033[0;34m'
		PURPLE='\033[0;35m'
		CYAN='\033[0;36m'
		WHITE='\033[0;37m'
		NC='\033[0m' # No Color
	else
		RED=''
		GREEN=''
		YELLOW=''
		BLUE=''
		PURPLE=''
		CYAN=''
		WHITE=''
		NC=''
	fi
	MSG_COLOR=$CYAN
	OK_COLOR=$GREEN
	ERROR_COLOR=$RED
	WARNING_COLOR=$YELLOW
}
bash_lib_define_colors

# Messages: print a message with a color to the tty and a colorless message to stdout (to be logged)

# @brief echo the given text as a message
# @param $1 the text to echo
echo_msg ()
{
	echo -e "[ ${MSG_COLOR}MSG${NC} ] $1" > /dev/tty
	echo -e "[ MSG ] $1"
}
echo_msg_tty ()
{
	echo -e "[ ${MSG_COLOR}MSG${NC} ] $1" > /dev/tty
}

# @brief echo the given text as an ok message
# @param $1 the text to echo
echo_ok_msg ()
{
	echo -e "[ ${OK_COLOR}OK${NC}  ] $1" > /dev/tty
	echo -e "[ OK  ] $1"
}
echo_ok_msg_tty ()
{
	echo -e "[ ${OK_COLOR}OK${NC}  ] $1" > /dev/tty
}

# @brief echo the given text as a warning message
# @param $1 the text to echo
echo_warning_msg ()
{
	echo -e "[ ${WARNING_COLOR}WAR${NC} ] $1" > /dev/tty
	echo -e "[ WAR ] $1"
}
echo_warning_msg_tty ()
{
	echo -e "[ ${WARNING_COLOR}WAR${NC} ] $1" > /dev/tty
}

# @brief echo the given text as an error message
# @param $1 the text to echo
echo_error_msg ()
{
	echo -e "[ ${ERROR_COLOR}ERR${NC} ] $1" > /dev/tty
	echo -e "[ ERR ] $1"
}
echo_error_msg_tty ()
{
	echo -e "[ ${ERROR_COLOR}ERR${NC} ] $1" > /dev/tty
}

# @brief waits until any key is pressed
# @usage wait_for_any_key_press
wait_for_any_key_press ()
{
	read -n 1 -s -r -p "$1"
	echo
}

# @brief prints the git branch name
# @usage branch=$(get_git_branch)
get_git_branch ()
{
	#git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
	local branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
	# check if branch is an empty string
	if [[ ! -z "$branch" ]]; then
		printf "$branch"
	fi
}

# @brief echo the full path of a given path
# @param $1 path to the file
get_full_path ()
{
	cd $(dirname $1)
	echo "$PWD/$(basename $1)"
	cd $OLDPWD
}

# @brief archive extraction
# @usage extract <file>
extract ()
{
	if [[ -f "$1" ]] ; then
		case $1 in
			*.tar.bz2)   tar xjf $1   ;;
			*.tar.gz)    tar xzf $1   ;;
			*.bz2)       bunzip2 $1   ;;
			*.rar)       unrar x $1   ;;
			*.gz)        gunzip $1    ;;
			*.tar)       tar xf $1    ;;
			*.tbz2)      tar xjf $1   ;;
			*.tgz)       tar xzf $1   ;;
			*.zip)       unzip $1     ;;
			*.Z)         uncompress $1;;
			*.7z)        7z x $1      ;;
			*.deb)       ar x $1      ;;
			*.tar.xz)    tar xf $1    ;;
			*.tar.zst)   unzstd $1    ;;
			*)           echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
	echo "'$1' is not a valid file"
	echo "usage: extract <file>"
	fi
}

# @brief prints the content of a yaml file in a way that eval can use it
# @brief to use it, just eval the output of this function
# @param $1 the path to the yaml file
# @param $2 a prefix to add to the variable names (optional)
# @example
# ```yaml
# catagory:
#   key: value
# ```
# will set:
# $catagory_key = value
# @usage eval $(parse_yaml $file)
parse_yaml ()
{
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s='\'%s\''\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

parsed_check_system ()
{
	if [[ -z "$system_hostname" ]]; then
		echo_error_msg_tty "Hostname didn't detected"
		to_exit='true'
	else
		echo_ok_msg_tty "Hostname: $system_hostname"
	fi
	if [[ -z "$system_desktop_environment" ]]; then
		echo_error_msg_tty "Desktop environment didn't detected"
		to_exit='true'
	elif [[ "$system_desktop_environment" =~ ^(kde|gnome|xfce)$ ]]; then
		echo_ok_msg_tty "Desktop environment: $system_desktop_environment"
	elif [[ "$system_desktop_environment" =~ ^server$ ]]; then
		echo_ok_msg_tty "It's a server, no desktop packages/aurs will be installed"
	else
		echo_error_msg_tty "Desktop environment detected but not supported or invalid"
		to_exit='true'
	fi
}
parsed_check_root ()
{
	if [[ -z $root_user_password ]]; then
		echo_error_msg_tty "Root user password didn't detected"
		to_exit='true'
	fi
}
parsed_check_admin ()
{
	if [[ -z $admin_user_name ]]; then
		echo_error_msg_tty "Admin username didn't detected"
		to_exit='true'
	elif [[ !( "$admin_user_name" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ) ]]; then
		echo_error_msg_tty "Admin username isn't valid (only lowercase, numbers, '-' and '_' are allowed)"
		to_exit='true'
	fi
	if [[ -z $admin_user_password ]]; then
		echo_error_msg_tty "Admin user password didn't detected"
		to_exit='true'
	fi
}
parsed_check_disk ()
{
	if [[ -z $disk_path ]]; then
		echo_error_msg_tty "Disk path didn't detected"
		to_exit='true'
	else
		if [[ -e "$disk_path"  ]] && [[ ! -z $(lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_path" )") ]]; then
			echo_ok_msg_tty "Script will install on $disk_path [$( lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_path" )" | awk '{print $2}' )]"
		else
			echo_error_msg_tty "Disk path doesn't exist or isn't a disk"
			to_exit='true'
		fi
	fi
	if [[ -z $disk_auto_allocate ]]; then
		echo_error_msg_tty "Disk auto allocate didn't detected"
		to_exit='true'
	elif [[ "$disk_auto_allocate" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "Disk auto allocate: $disk_auto_allocate"
		if [[ "$disk_auto_allocate" == 'true' ]]; then
			echo_warning_msg_tty "Auto allocate will take over all of the disk, make sure that $disk_path is empty or unimportant"
			# Boot partition check [optional partion]
			if [[ -z $disk_partitions_boot_size ]]; then
				echo_warning_msg_tty "Disk partitions boot size didn't detected, make sure you have a way to boot your system"
				parsed_info_has_boot='false'
			else
				echo_ok_msg_tty "Disk partitions boot size: $disk_partitions_boot_size"
				parsed_info_has_boot='true'
			fi
			# Swap partition check [optional partion]
			if [[ -z $disk_partitions_swap_size ]]; then
				echo_warning_msg_tty "Disk partitions swap size didn't detected, the system won't have swap"
				parsed_info_has_swap='false'
			else
				echo_ok_msg_tty "Disk partitions swap size: $disk_partitions_swap_size"
				parsed_info_has_swap='true'
			fi
			# Root partition check [required partion]
			if [[ -z $disk_partitions_root_size ]]; then
				echo_error_msg_tty "Disk partitions root size didn't detected"
				to_exit='true'
			else
				echo_ok_msg_tty "Disk partitions root size: $disk_partitions_root_size"
			fi
			# Home partition check [optional partion]
			if [[ -z $disk_partitions_home_size ]]; then
				echo_warning_msg_tty "Disk partitions home size didn't detected, the system won't have home partition"
				parsed_info_has_home='false'
			else
				echo_ok_msg_tty "Disk partitions home size: $disk_partitions_home_size"
				parsed_info_has_home='true'
			fi
		else # Auto allocate == true
			# Boot partition check [optional partion]
			if [[ -z $disk_partitions_boot_partition ]]; then
				echo_warning_msg_tty "Disk partitions boot partition didn't detected, make sure you have a way to boot your system"
				parsed_info_has_boot='false'
			else
				# Check if the boot partition exists
				if [[ -e "$disk_partitions_boot_partition"  ]] && [[ ! -z $(lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_partitions_boot_partition" )") ]]; then
					echo_ok_msg_tty "Disk partitions boot partition: $disk_partitions_boot_partition [$( lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_partitions_boot_partition" )" | awk '{print $2}' )] (exists)"
					parsed_info_has_boot='true'
				else
					echo_error_msg_tty "Disk partitions boot partition: $disk_partitions_boot_partition doesn't exist or isn't a disk"
					to_exit='true'
				fi
			fi
			# Swap partition check [optional partion]
			if [[ -z $disk_partitions_swap_partition ]]; then
				echo_warning_msg_tty "Disk partitions swap partition didn't detected, the system won't have swap"
				parsed_info_has_swap='false'
			else
				# Check if the swap partition exists
				if [[ -e "$disk_partitions_swap_partition"  ]] && [[ ! -z $(lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_partitions_swap_partition" )") ]]; then
					echo_ok_msg_tty "Disk partitions swap partition: $disk_partitions_swap_partition [$( lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_partitions_swap_partition" )" | awk '{print $2}' )] (exists)"
					parsed_info_has_swap='true'
				else
					echo_error_msg_tty "Disk partitions swap partition: $disk_partitions_swap_partition doesn't exist or isn't a disk"
					to_exit='true'
				fi
			fi
			# Root partition check [required partion]
			if [[ -z $disk_partitions_root_partition ]]; then
				echo_error_msg_tty "Disk partitions root partition didn't detected"
				to_exit='true'
			else
				# Check if the root partition exists
				if [[ -e "$disk_partitions_root_partition"  ]] && [[ ! -z $(lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_partitions_root_partition" )") ]]; then
					echo_ok_msg_tty "Disk partitions root partition: $disk_partitions_root_partition [$( lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_partitions_root_partition" )" | awk '{print $2}' )] (exists)"
				else
					echo_error_msg_tty "Disk partitions root partition: $disk_partitions_root_partition doesn't exist or isn't a disk"
					to_exit='true'
				fi
			fi
			# Home partition check [optional partion]
			if [[ -z $disk_partitions_home_partition ]]; then
				echo_warning_msg_tty "Disk partitions home partition didn't detected, the system won't have home partition"
				parsed_info_has_home='false'
			else
				# Check if the home partition exists
				if [[ -e "$disk_partitions_home_partition"  ]] && [[ ! -z $(lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_partitions_home_partition" )") ]]; then
					echo_ok_msg_tty "Disk partitions home partition: $disk_partitions_home_partition [$( lsblk -n -o NAME,SIZE | grep -w "$( basename "$disk_partitions_home_partition" )" | awk '{print $2}' )] (exists)"
					parsed_info_has_home='true'
				else
					echo_error_msg_tty "Disk partitions home partition: $disk_partitions_home_partition doesn't exist or isn't a disk"
					to_exit='true'
				fi
			fi
		fi
		if [[ "$parsed_info_has_home" == 'true' ]]; then
			if [[ -z $disk_partitions_home_encrypted ]]; then
				disk_partitions_home_encrypted='false'
				echo_ok_msg_tty "Disk partitions home encrypted: $disk_partitions_home_encrypted [D]"
			elif [[ "$disk_partitions_home_encrypted" =~ ^(true|false)$ ]]; then
				echo_ok_msg_tty "Disk partitions home encrypted: $disk_partitions_home_encrypted [S]"
				if [[ "$disk_partitions_home_encrypted" == 'true' ]]; then
					if [[ -z $disk_partitions_home_passphrase ]]; then
						echo_error_msg_tty "Disk partitions home passphrase didn't detected"
						to_exit='true'
					fi
				fi
			else
				echo_error_msg_tty "Disk partitions home encrypted detected but invalid (only true or false allowed)"
				to_exit='true'
			fi
		fi
	else
		echo_error_msg_tty "Disk auto allocate detected but invalid (only 'true' or 'false' are allowed)"
		to_exit='true'
	fi
}
parsed_check_to_install ()
{
	local term_install_kinds="must [M]"
	local desk_install_kinds="must [M]"
	# term utils
	if [[ -z $to_install_term_utils ]]; then # default value
		term_install_kinds="$term_install_kinds, utils [D]"
		to_install_term_utils='true'
	else # specified value
		if [[ "$to_install_term_utils" =~ ^(true|false)$ ]]; then
			if [[ "$to_install_term_utils" == 'true' ]]; then
				term_install_kinds="$term_install_kinds, utils [S]"
			fi
		else
			echo_error_msg_tty "To install term utils detected but invalid (only 'true' or 'false' are allowed)"
			to_exit='true'
		fi
	fi
	# term dev
	if [[ -z $to_install_term_dev ]]; then # default value
		term_install_kinds="$term_install_kinds, dev [D]"
		to_install_term_dev='true'
	else # specified value
		if [[ "$to_install_term_dev" =~ ^(true|false)$ ]]; then
			if [[ "$to_install_term_dev" == 'true' ]]; then
				term_install_kinds="$term_install_kinds, dev [S]"
			fi
		else
			echo_error_msg_tty "To install term dev detected but invalid (only 'true' or 'false' are allowed)"
			to_exit='true'
		fi
	fi
	# desk utils
	if [[ -z $to_install_desk_utils ]]; then # default value
		desk_install_kinds="$desk_install_kinds, utils [D]"
		to_install_desk_utils='true'
	else # specified value
		if [[ "$to_install_desk_utils" =~ ^(true|false)$ ]]; then
			if [[ "$to_install_desk_utils" == 'true' ]]; then
				desk_install_kinds="$desk_install_kinds, utils [S]"
			fi
		else
			echo_error_msg_tty "To install desk utils detected but invalid (only 'true' or 'false' are allowed)"
			to_exit='true'
		fi
	fi
	# desk dev
	if [[ -z $to_install_desk_dev ]]; then # default value
		desk_install_kinds="$desk_install_kinds, dev [D]"
		to_install_desk_dev='true'
	else # specified value
		if [[ "$to_install_desk_dev" =~ ^(true|false)$ ]]; then
			if [[ "$to_install_desk_dev" == 'true' ]]; then
				desk_install_kinds="$desk_install_kinds, dev [S]"
			fi
		else
			echo_error_msg_tty "To install desk dev detected but invalid (only 'true' or 'false' are allowed)"
			to_exit='true'
		fi
	fi
	# desk creative
	if [[ -z $to_install_desk_creative ]]; then # default value
		desk_install_kinds="$desk_install_kinds, creative [D]"
		to_install_desk_creative='true'
	else # specified value
		if [[ "$to_install_desk_creative" =~ ^(true|false)$ ]]; then
			if [[ "$to_install_desk_creative" == 'true' ]]; then
				desk_install_kinds="$desk_install_kinds, creative [S]"
			fi
		else
			echo_error_msg_tty "To install desk creative detected but invalid (only 'true' or 'false' are allowed)"
			to_exit='true'
		fi
	fi
	# desk office
	if [[ -z $to_install_desk_office ]]; then # default value
		desk_install_kinds="$desk_install_kinds, office [D]"
		to_install_desk_office='true'
	else # specified value
		if [[ "$to_install_desk_office" =~ ^(true|false)$ ]]; then
			if [[ "$to_install_desk_office" == 'true' ]]; then
				desk_install_kinds="$desk_install_kinds, office [S]"
			fi
		else
			echo_error_msg_tty "To install desk office detected but invalid (only 'true' or 'false' are allowed)"
			to_exit='true'
		fi
	fi
	echo_ok_msg_tty "Terminal packages to install: $term_install_kinds"
	echo_ok_msg_tty "Desktop packages to install: $desk_install_kinds"
}
parsed_check_advenced ()
{
	# advenced kernel
	if [[ -z $advenced_kernel ]]; then
		advenced_kernel='linux'
		echo_ok_msg_tty "kernel: $advenced_kernel [D]"
	elif [[ "$advenced_kernel" =~ ^(linux|linux-lts)$ ]]; then
		echo_ok_msg_tty "kernel: $advenced_kernel [S]"
	else
		echo_error_msg_tty "Advenced kernel detected but invalid (only 'linux' or 'linux-lts' are allowed)"
		to_exit='true'
	fi
	# advenced copy log to machine
	if [[ -z $advenced_copy_log_to_machine ]]; then
		advenced_copy_log_to_machine='true'
		echo_ok_msg_tty "Copy log to machine: $advenced_copy_log_to_machine [D]"
	elif [[ "$advenced_copy_log_to_machine" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "Copy log to machine: $advenced_copy_log_to_machine [S]"
	else
		echo_error_msg_tty "Advenced copy log to machine detected but invalid (only 'true' or 'false' are allowed)"
		to_exit='true'
	fi
	# advenced detect and install vm utils
	if [[ -z $advenced_detect_and_install_vm_utils ]]; then
		advenced_detect_and_install_vm_utils='true'
		echo_ok_msg_tty "Detect and install vm utils: $advenced_detect_and_install_vm_utils [D]"
	elif [[ "$advenced_detect_and_install_vm_utils" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "Detect and install vm utils: $advenced_detect_and_install_vm_utils [S]"
	else
		echo_error_msg_tty "Advenced detect and install vm utils detected but invalid (only 'true' or 'false' are allowed)"
		to_exit='true'
	fi
}
parse_info ()
{
	eval $( parse_yaml $SCRIPT_DIR/setup.yml )
	local to_exit='false'
	echo_msg_tty "Signs: [M] - mandatory, [D] - default value, [S] -specified value"

	# call the check functions
	echo -e "[${MSG_COLOR}System info:${NC}]" > /dev/tty
	parsed_check_system
	parsed_check_root
	parsed_check_admin
	echo -e "[${MSG_COLOR}Disk info:${NC}]" > /dev/tty
	parsed_check_disk
	echo -e "[${MSG_COLOR}Install info:${NC}]" > /dev/tty
	parsed_check_to_install
	echo -e "[${MSG_COLOR}Advenced info:${NC}]" > /dev/tty
	parsed_check_advenced

	if [[ $to_exit == 'true' ]]; then
		echo -e "[${MSG_COLOR}Instructions:${NC}]" > /dev/tty
		echo_warning_msg_tty "Exiting..."
		echo_warning_msg_tty "just edit the setup.yml file and run the script again"
		echo_msg_tty "edit the script by running: $EDITOR $SCRIPT_DIR/setup.yml"
		echo_msg_tty "run the script by running: $SCRIPT_DIR/nonoArch.sh"
		exit
	fi
}

generate_info_bash_file()
{
cat > $SCRIPT_DIR/setup.sh <<EOF
system_hostname='$system_hostname'
system_desktop_environment='$system_desktop_environment'
root_user_password='$root_user_password'
admin_user_name='$admin_user_name'
admin_user_password='$admin_user_password'
disk_auto_allocate='$disk_auto_allocate'
disk_path='$disk_path'
disk_partitions_boot_size='$disk_partitions_boot_size'
disk_partitions_swap_size='$disk_partitions_swap_size'
disk_partitions_root_size='$disk_partitions_root_size'
disk_partitions_home_size='$disk_partitions_home_size'
disk_partitions_home_encrypted='$disk_partitions_home_encrypted'
disk_partitions_home_passphrase='$disk_partitions_home_passphrase'
to_install_term_utils='$to_install_term_utils'
to_install_term_dev='$to_install_term_dev'
to_install_desk_utils='$to_install_desk_utils'
to_install_desk_dev='$to_install_desk_dev'
to_install_desk_creative='$to_install_desk_creative'
to_install_desk_office='$to_install_desk_office'
advenced_kernel='$advenced_kernel'
advenced_copy_log_to_machine='$advenced_copy_log_to_machine'
advenced_detect_and_install_vm_utils='$advenced_detect_and_install_vm_utils'
parsed_info_has_swap='$parsed_info_has_swap'
parsed_info_has_boot='$parsed_info_has_boot'
parsed_info_has_home='$parsed_info_has_home'
disk_partitions_boot_partition='$disk_partitions_boot_partition'
disk_partitions_swap_partition='$disk_partitions_swap_partition'
disk_partitions_root_partition='$disk_partitions_root_partition'
disk_partitions_home_partition='$disk_partitions_home_partition'
EOF
}

setup_mirrors_using_reflector ()
{
	reflector -a 48 -c $(curl -s https://ifconfig.co/country-iso) -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
}
