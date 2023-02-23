#!/bin/bash

VOL=$(amixer -R | grep -A 4 Master | egrep -o '[0-9]+%' | egrep -o '[0-9]+')

if  [ "$(amixer -R | grep -A 4 Master | egrep -o '\[off\]')" ]; then
	echo ' Mute'

else
	if [ "$VOL -lt 40" ]; then
		echo " "$VOL"%"
	else
		echo " "$VOL"%"
	fi
fi
