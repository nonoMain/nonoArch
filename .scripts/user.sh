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
			echo_msg "Installing(paru[AUR]) F:$(basename $file_name)	$title	P:$line"
			$aur_helper_name -S --noconfirm --needed ${line} || echo_error_msg "Failed to download AUR: $line"
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
echo_msg "                           Installing AUR helper"
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

download_aurs_from_file "$HOME/.toInstall/desk.aurs.must.txt"
[[ "$to_install_term_dev" == 'true' ]] && download_aurs_from_file "$HOME/.toInstall/term.aurs.dev.txt"
if [[ "$system_desktop_environment" != 'server' ]]; then
	[[ "$to_install_desk_dev" == 'true' ]] && download_aurs_from_file "$HOME/.toInstall/desk.aurs.dev.txt"
	[[ "$to_install_desk_utils" == 'true' ]] && download_aurs_from_file "$HOME/.toInstall/desk.packages.utils.txt"
	[[ "$to_install_desk_office" == 'true' ]] && download_aurs_from_file "$HOME/.toInstall/desk.packages.office.txt"
fi

#pip install neovim || (echo_error_msg "Failed to install neovim"; wait_for_any_key_press "Press any key to continue" )
#pip install scapy || (echo_error_msg "Failed to install scapy"; wait_for_any_key_press "Press any key to continue" )
