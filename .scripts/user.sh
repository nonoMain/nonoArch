#!/usr/bin/env -S bash -e
# @file user
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

##------------------------don't touch----------------------##

# paru
aur_helper_url='https://aur.archlinux.org/paru.git'
aur_helper_name='paru'

install_aurs_from_file ()
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
			( $aur_helper_name -S --noconfirm --needed ${line} ) && installed=true || installed=false
			if [ $installed == false ]; then
				echo_warning_msg "Failed to install package: $line, retrying..."
				( $aur_helper_name -S --noconfirm --needed ${line} ) && installed=true || installed=false
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


if [[ "$(curl -s https://ifconfig.co/country-iso)" == 'IL' ]]; then
# toggle langs using Super(WinKey) + space (set to english 'us' and hebrew 'il')
cat > ~/.profile << EOF
# toggle langs using alt+shift (set to english 'us' and hebrew 'il')
setxkbmap -option grp:win_space_toggle us,il
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


echo_msg "--------------------------------------------------------------------------------"
echo_msg "                             Installing pip packages"
echo_msg "--------------------------------------------------------------------------------"

[[ "$to_install_term_dev" == 'true' ]] && ( pip install neovim || echo_error_msg "Failed to install neovim" )

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                             Installing Aur packages"
echo_msg "--------------------------------------------------------------------------------"

install_aurs_from_file "$HOME/.toInstall/term.aurs.dev.txt"
if [[ "$system_desktop_environment" != 'server' ]]; then
	install_aurs_from_file "$HOME/.toInstall/desk.aurs.must.txt"
	[[ "$to_install_desk_utils" == 'true' ]] && ( install_aurs_from_file "$HOME/.toInstall/desk.aurs.utils.txt" || echo_warning_msg "Skipping desk.aurs.utils.txt" )
	[[ "$to_install_desk_dev" == 'true' ]] && ( install_aurs_from_file "$HOME/.toInstall/desk.aurs.dev.txt" || echo_warning_msg "Skipping desk.aurs.dev.txt" )
	[[ "$to_install_desk_office" == 'true' ]] && ( install_aurs_from_file "$HOME/.toInstall/desk.aurs.office.txt" || echo_warning_msg "Skipping desk.aurs.office.txt" )
fi
if [[ "$system_desktop_environment" == 'kde' ]]; then
	echo_msg "--------------------------------------------------------------------------------"
	echo_msg "                            Installing KDE Aur packages"
	echo_msg "--------------------------------------------------------------------------------"
	( install_aurs_from_file "$HOME/.toInstall/desk.aurs.kde.txt" || echo_warning_msg "Skipping desk.aurs.kde.txt" )
fi
