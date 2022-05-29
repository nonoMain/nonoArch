#!/usr/bin/env -S bash -e
# @file post-live-env
# @note this script along with all the others will get called by the main script into an evironment where
# @note all the setup variables are defined and the library is available

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                 Post setup the environment for the installation"
echo_msg "--------------------------------------------------------------------------------"

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                           Enabling Essential Services"
echo_msg "--------------------------------------------------------------------------------"

systemctl enable NetworkManager.service
if [[ "$system_desktop_environment" != 'server' ]]; then
	systemctl enable lightdm.service
fi

# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo_msg "--------------------------------------------------------------------------------"
echo_msg "                   Cleaning up the files copied to the system"
echo_msg "--------------------------------------------------------------------------------"

rm -r $HOME/.toInstall
rm -r /home/$admin_user_name/.toInstall
