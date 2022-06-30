#!/usr/bin/env bash

THEMEDIRECTORY=$(cd `dirname $0` && cd .. && pwd)
FIREFOXFOLDER=$HOME/.mozilla/firefox
PROFILENAME=""
THEME=yaru
COLOR=orange

# Get options.
while getopts 'f:p:c:h' flag; do
	case "${flag}" in
	f) FIREFOXFOLDER="${OPTARG}" ;;
	p) PROFILENAME="${OPTARG}" ;;
	c) COLOR="${OPTARG}" ;;
	h)
		echo "Gnome Theme Install Script:"
		echo "  -f <firefox_folder_path>. Set custom Firefox folder path."
		echo "  -p <profile_name>. Set custom profile name."
		echo "  -c <color_name>. Specify yaru accent color variant [orange|bark|sage|olive|viridian|prussiangreen|blue|purple|magenta|red]"
		echo "  -h to show this message."
		exit 0
		;;
	esac
done

function saveProfile(){
	local PROFILE_PATH="$1"

	cd "$FIREFOXFOLDER/$PROFILE_PATH"
	echo "Installing $COLOR Firefox theme in $PWD"
	# Create a chrome directory if it doesn't exist.
	mkdir -p chrome
	cd chrome

	# Copy theme repo inside
	cp -fR "$THEMEDIRECTORY" "$PWD"

	# Set accent color
	sed -i "/\$accent_color:/s/orange/${COLOR}/" ${PWD}/dg-firefox-theme/theme/colors/sass/_accent-colors.scss

	# Generate CSS
	sassc -M -t expanded "${PWD}/dg-firefox-theme/theme/colors/sass/dark-yaru.scss"  "${PWD}/dg-firefox-theme/theme/colors/dark-yaru.css"
	sassc -M -t expanded "${PWD}/dg-firefox-theme/theme/colors/sass/light-yaru.scss" "${PWD}/dg-firefox-theme/theme/colors/light-yaru.css"

	# Remove Sass directory
	rm -rf "${PWD}/dg-firefox-theme/theme/colors/sass"

	# Create single-line user CSS files if non-existent or empty.
	if [ -s userChrome.css ]; then
		# Remove older theme imports
		sed 's/@import "dg-firefox-theme.*.//g' userChrome.css | sed '/^\s*$/d' > userChrome.css
		echo >> userChrome.css
	else
		echo >> userChrome.css
	fi

	# Import this theme at the beginning of the CSS files.
	sed -i '1s/^/@import "dg-firefox-theme\/userChrome.css";\n/' userChrome.css

	if [ $THEME = "yaru" ]; then
		echo "@import \"dg-firefox-theme\/theme/colors/light-$THEME.css\";" >> userChrome.css
		echo "@import \"dg-firefox-theme\/theme/colors/dark-$THEME.css\";" >> userChrome.css
	fi

	# Create single-line user content CSS files if non-existent or empty.
	if [ -s userContent.css ]; then
		# Remove older theme imports
		sed 's/@import "dg-firefox-theme.*.//g' userContent.css | sed '/^\s*$/d' > userContent.css
		echo >> userContent.css
	else
		echo >> userContent.css
	fi

	# Import this theme at the beginning of the CSS files.
	sed -i '1s/^/@import "dg-firefox-theme\/userContent.css";\n/' userContent.css

	if [ $THEME = "yaru" ]; then
		echo "@import \"dg-firefox-theme\/theme/colors/light-$THEME.css\";" >> userContent.css
		echo "@import \"dg-firefox-theme\/theme/colors/dark-$THEME.css\";" >> userContent.css
	fi

	cd ..

	# Symlink user.js to dg-firefox-theme one.
	ln -fs chrome/dg-firefox-theme/configuration/user.js user.js

	cd ..
}

PROFILES_FILE="${FIREFOXFOLDER}/profiles.ini"
if [ ! -f "${PROFILES_FILE}" ]; then
	>&2 echo "failed, lease check Firefox installation, unable to find profiles.ini at ${FIREFOXFOLDER}"
	exit 1
fi

PROFILES_PATHS=($(grep -E "^Path=" "${PROFILES_FILE}" | tr -d '\n' | sed -e 's/\s\+/SPACECHARACTER/g' | sed 's/Path=/::/g' )) 
PROFILES_PATHS+=::

PROFILES_ARRAY=()
if [ "${PROFILENAME}" != "" ];
	then
		echo "Using ${PROFILENAME} theme"
		PROFILES_ARRAY+=${PROFILENAME}
else
	while [[ $PROFILES_PATHS ]]; do
		PROFILES_ARRAY+=( "${PROFILES_PATHS%%::*}" )
		PROFILES_PATHS=${PROFILES_PATHS#*::}
	done
fi



if [ ${#PROFILES_ARRAY[@]} -eq 0 ]; then
	echo No Profiles found on $PROFILES_FILE;

else
	for i in "${PROFILES_ARRAY[@]}"
	do
		if [[ ! -z "$i" ]];
		then
			saveProfile "$(sed 's/SPACECHARACTER/ /g' <<< $i)"
		fi;
	
	done
fi
