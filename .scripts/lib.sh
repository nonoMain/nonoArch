# colors
bash_lib_define_colors ()
{
	if [[ -z $NO_COLOR ]] || [[ $NO_COLOR == 0 ]]; then
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

parse_info ()
{
eval $( parse_yaml $SCRIPT_DIR/setup.yml )
local to_exit='false'
# System hostname check
	if [[ -z "$system_hostname" ]]; then
		echo_error_msg_tty "system hostname didn't detected"
		to_exit='true'
	else
		echo_ok_msg_tty "system hostname detected"
	fi
# System desktop environment check
	if [[ -z "$system_desktop_environment" ]]; then
		echo_error_msg_tty "system desktop environment didn't detected"
		to_exit='true'
	elif [[ $system_desktop_environment =~ ^(kde|gnome|xfce|server)$ ]]; then
		echo_ok_msg_tty "system desktop environment detected and valid"
	else
		echo_error_msg_tty "system desktop environment detected but not valid"
		to_exit='true'
	fi
# Root password check
	if [[ -z $root_user_password ]]; then
		echo_error_msg_tty "root user password didn't detected"
		to_exit='true'
	else
		echo_ok_msg_tty "root user password detected"
		#root_user_password=$(sed -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/' <<< $root_user_password)
	fi
# Admin name check
	if [[ -z "$admin_user_name" ]]; then
		echo_error_msg_tty "admin username didn't detected"
		to_exit='true'
	else
		echo_ok_msg_tty "admin username detected"
		if [[ !( "$admin_user_name" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ) ]]; then
			echo_error_msg_tty "admin username isn't valid (only lowercase, numbers, '-' and '_' are allowed)"
			to_exit='true'
		else
			echo_ok_msg_tty "admin username is valid"
		fi
	fi
# Admin password check
	if [[ -z "$admin_user_password" ]]; then
		echo_error_msg_tty "admin user password didn't detected"
		to_exit='true'
	else
		echo_ok_msg_tty "admin user password detected"
		#admin_user_password=$(sed -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/' <<< $admin_user_password)
	fi
	if [[ -z $disk_path ]]; then
		echo_error_msg_tty "disk path didn't detected"
		to_exit='true'
	else
		echo_ok_msg_tty "disk path detected"
	fi
# Partitions check (boot, swap, root, home) #
	if [[ "$disk_auto_allocate" == 'false' ]]; then
	# Boot partition check
		if [[ -z "$disk_partitions_boot_partition" ]]; then
			echo_warning_msg_tty "boot partition didn't detected, make sure you have a way to boot your system"
			parsed_info_has_boot='false'
		else
			echo_ok_msg_tty "boot partition detected"
			parsed_info_has_boot='true'
		fi
	# Swap partition check
		if [[ -z "$disk_partitions_swap_partition" ]]; then
			echo_warning_msg_tty "swap partition didn't detected, the system won't have swap"
			parsed_info_has_swap='false'
		else
			echo_ok_msg_tty "swap partition detected"
			parsed_info_has_swap='true'
		fi
	# Root partition check
		if [[ -z "$disk_partitions_root_partition" ]]; then
			echo_error_msg_tty "root partition didn't detected"
			to_exit='true'
		else
			echo_ok_msg_tty "root partition detected"
		fi
	# Home partition check
		if [[ -z "$disk_partitions_home_partition" ]]; then
			echo_warning_msg_tty "home partition didn't detected, '/home' will be a part of the root"
			parsed_info_has_home='false'
		else
			echo_ok_msg_tty "home partition detected"
			parsed_info_has_home='true'
			if [[ -z "$disk_partitions_home_encrypted" ]]; then
				echo_error_msg_tty "home encryption didn't detected"
				to_exit='true'
			else
				if [[ "$disk_partitions_home_encrypted" == 'true' ]]; then
					echo_ok_msg_tty "home encryption detected, will encrypt home partition"
					if [[ -z "$disk_partitions_home_passphrase" ]]; then
						echo_error_msg_tty "home passphrase didn't detected"
						to_exit='true'
					else
						echo_ok_msg_tty "home passphrase detected"
					fi
				else
					echo_ok_msg_tty "home encryption detected, will not encrypt home partition"
				fi
			fi
		fi
	elif [[ "$disk_auto_allocate" == 'true' ]]; then
		echo_ok_msg_tty "auto-allocate disk detected"
		echo_warning_msg_tty "auto allocate will take over all of the disk, make sure that $disk_path is empty or unimportant"
	# Boot partition check
		if [[ -z "$disk_partitions_boot_size" ]]; then
			echo_warning_msg_tty "boot partition & size didn't detected, make sure you have a way to boot your system"
			parsed_info_has_boot='false'
		else
			echo_ok_msg_tty "boot partition & size detected"
			parsed_info_has_boot='true'
		fi
	# Swap partition check
		if [[ -z "$disk_partitions_swap_size" ]]; then
			echo_warning_msg_tty "swap partition & size didn't detected, the system won't have swap"
			parsed_info_has_swap='false'
		else
			echo_ok_msg_tty "swap partition & size detected"
			parsed_info_has_swap='true'
		fi
	# Root partition check
		if [[ -z "$disk_partitions_root_size" ]]; then
			echo_error_msg_tty "root partition & size didn't detected"
			to_exit='true'
		else
			echo_ok_msg_tty "root partition & size detected"
		fi
	# Home partition check
		if [[ -z "$disk_partitions_home_size" ]]; then
			echo_warning_msg_tty "home partition & size didn't detected, '/home' will be a part of the root"
			parsed_info_has_home='false'
		else
			echo_ok_msg_tty "home partition & size detected"
			parsed_info_has_home='true'
			if [[ -z "$disk_partitions_home_encrypted" ]]; then
				echo_error_msg_tty "home encryption didn't detected"
				to_exit='true'
			else
				if [[ "$disk_partitions_home_encrypted" == 'true' ]]; then
					echo_ok_msg_tty "home encryption detected: $disk_partitions_home_encrypted"
					if [[ -z $disk_partitions_home_passphrase ]]; then
						echo_error_msg_tty "home passphrase didn't detected"
						to_exit='true'
					else
						echo_ok_msg_tty "home passphrase detected"
					fi
				else
					echo_ok_msg_tty "home encryption detected: $disk_partitions_home_encrypted"
				fi
			fi
		fi
	else
		echo_error_msg_tty "auto-allocate disk didn't detected"
		to_exit='true'
	fi
# To be installed check #
	if [[ "$to_install_term_utils" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "to install term utils detected: $to_install_term_utils"
	else
		echo_warning_msg_tty "to_install_term_utils didn't detected, will install term-utils"
		to_install_term_utils='true'
	fi
	if [[ "$to_install_term_dev" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "to install term dev detected: $to_install_term_dev"
	else
		echo_warning_msg_tty "to_install_term_dev didn't detected, will install term-dev"
		to_install_term_dev='true'
	fi
	if [[ "$to_install_desk_utils" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "to install desk utils detected: $to_install_desk_utils"
	else
		echo_warning_msg_tty "to_install_desk_utils didn't detected, will install desk-utils"
		to_install_desk_utils='true'
	fi
	if [[ "$to_install_desk_dev" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "to install desk dev detected: $to_install_desk_dev"
	else
		echo_warning_msg_tty "to_install_desk_dev didn't detected, will install desk-dev"
		to_install_desk_dev='true'
	fi
	if [[ "$to_install_desk_creative" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "to install desk creative detected: $to_install_desk_creative"
	else
		echo_warning_msg_tty "to_install_desk_creative didn't detected, will install desk-creative"
		to_install_desk_creative='true'
	fi
	if [[ "$to_install_desk_office" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "to install desk office detected: $to_install_desk_office"
	else
		echo_warning_msg_tty "to_install_desk_office didn't detected, will install desk-office"
		to_install_desk_office='true'
	fi
# Advanced check #
	if [[ "$advenced_kernel" =~ ^(linux|linux-lts)$ ]]; then
		echo_ok_msg_tty "kernel detected: $advenced_kernel"
	else
		echo_ok_msg_tty "kernel didn't detected, will use linux"
		advenced_kernel='linux'
	fi
	if [[ "$advenced_copy_log_to_machine" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "copy log to machine detected: $advenced_copy_log_to_machine"
	else
		echo_ok_msg_tty "copy log to machine didn't detected, will copy log to machine"
		advenced_copy_log_to_machine='true'
	fi
	if [[ "$advenced_detect_and_install_vm_utils" =~ ^(true|false)$ ]]; then
		echo_ok_msg_tty "detect and install vm utils detected: $advenced_detect_and_install_vm_utils"
	else
		echo_ok_msg_tty "detect and install vm utils didn't detected, will detect and install vm utils"
		advenced_detect_and_install_vm_utils='true'
	fi


	if [[ $to_exit == 'true' ]]; then
		false
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
