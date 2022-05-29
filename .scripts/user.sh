#!/usr/bin/env -S bash -e
# @file user
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

##------------------------don't touch----------------------##

aur_helper_url='https://aur.archlinux.org/paru.git'
aur_helper_name='paru'

download_aurs_from_file ()
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
			$aur_helper_name -S --noconfirm --needed ${line} && installed=true || installed=false
			if [ $installed == false ]; then
				echo_warning_msg "Failed to download package: $line, retrying..."
				$aur_helper_name -S --noconfirm --needed ${line} && installed=true || installed=false
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

# toggle langs using Super(WinKey) + space (set to english 'us' and hebrew 'il')

if [[ "$(curl -s https://ifconfig.co/country-iso)" == 'IL' ]]; then
cat > ~/.profile << EOF
echo "# toggle langs using alt+shift (set to english 'us' and hebrew 'il')"
echo "setxkbmap -option grp:win_space_toggle us,il"
EOF
fi

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                              Installing AUR helper"
echo_msg "--------------------------------------------------------------------------------"

sudo pacman --noconfirm -S --needed base-devel git
TMPDIR="$(mktemp -d)"
cd "${TMPDIR}" || return 1
git clone $aur_helper_url
cd $aur_helper_name
makepkg -si --noconfirm
cd ../..
rm -rf $TMPDIR
$aur_helper_name

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                             Installing Aur packages"
echo_msg "--------------------------------------------------------------------------------"


download_aurs_from_file "$HOME/.toInstall/term.aurs.dev.txt"
if [[ "$system_desktop_environment" != 'server' ]]; then
	download_aurs_from_file "$HOME/.toInstall/desk.aurs.must.txt"
	[[ "$to_install_desk_dev" == 'true' ]] && download_aurs_from_file "$HOME/.toInstall/desk.aurs.dev.txt"
	pip install neovim || echo_error_msg "Failed to install neovim"
	[[ "$to_install_desk_utils" == 'true' ]] && download_aurs_from_file "$HOME/.toInstall/desk.aurs.utils.txt"
	[[ "$to_install_desk_office" == 'true' ]] && download_aurs_from_file "$HOME/.toInstall/desk.aurs.office.txt"
fi
