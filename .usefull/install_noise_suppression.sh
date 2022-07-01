#!/usr/bin/env -S bash -e
# @note run as user

# the AUR helper that you use
aur_helper='paru'

# make sure this path exists or find yours (run 'tree -a -f / | grep librnnoise_ladspa_path' to find it)
librnnoise_ladspa_path='/usr/lib/ladspa/librnnoise_ladspa.so'

# choose the input device using 'pactl list sources short'
input_device='<insert input device>'

# install the needed AUR
$aur_helper -S noise-suppression-for-voice

# configure pulseaudio
cat > $HOME/.config/pulse/default.pa <<EOF
.include /etc/pulse/default.pa

load-module module-null-sink sink_name=mic_denoised_out rate=48000
load-module module-ladspa-sink sink_name=mic_raw_in sink_master=mic_denoised_out label=noise_suppressor_mono plugin=$librnnoise_ladspa_path control=50
load-module module-loopback source=$input_device sink=mic_raw_in channels=1 source_dont_move=true sink_dont_move=true latency_msec=1

load-module module-remap-source source_name=denoised master=mic_denoised_out.monitor channels=1

set-default-source denoised
EOF
