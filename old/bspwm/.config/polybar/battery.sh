#!/bin/bash

VAR=$(acpi | egrep -o '[0-9]+%' | egrep -o '[0-9]+')
DIS=$(acpi | egrep -o 'Discharging')

if [ "$DIS" != "Discharging" ]; then
	echo " "$VAR"%"
elif [ $VAR -gt 80 ]; then
	echo " "$VAR"%"
elif [ $VAR -gt 60 ]; then
	echo " "$VAR"%"
elif [ $VAR -gt 40 ]; then
	echo " "$VAR"%"
elif [ $VAR -gt 20 ]; then
	echo " "$VAR"%"
else
	echo " "$VAR"%"
fi
