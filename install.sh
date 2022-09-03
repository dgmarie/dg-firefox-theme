#!/usr/bin/env bash
dir="$(dirname -- "$0")"
themedirectory="$(realpath "${dir}")"
profilename=""
theme=yaru
nc='\033[0m'
bold='\033[1m'
red='\033[0;31m'
green='\033[0;32m'

# Get options.
while getopts 'f:p:c:h' flag; do
  case "${flag}" in
  f) firefoxfolder="${OPTARG}" ;;
  p) profilename="${OPTARG}" ;;
  c) color="${OPTARG}" ;;
  h)
    echo "OPTIONS:"
    echo "  -f <firefox_folder_path>. Set custom Firefox folder path."
    echo "  -p <profile_name>. Set custom profile name."
    echo "  -c <color_name>. Specify yaru accent color variant [orange|bark|sage|olive|viridian|prussiangreen|blue|purple|magenta|red]"
    echo "  -h to show this message."
    exit 0
    ;;
  *)
    echo "ERROR: Unrecognized installation option '$1'."
    echo "Try '$0 --help' for more information."
    exit 1
    ;;
  esac
done

if [[ -z "${color}" ]]; then
  color=orange
fi
if [[ -z "${firefoxfolder}" ]]; then
  firefoxfolder="${HOME}/.mozilla/firefox"
fi

function saveProfile(){
  local profile_path="$1"

  cd "$firefoxfolder/$profile_path" || exit

  # If being updated by dg-gnome-theme
  if [[ "${update_firefox}" == "true" ]]; then
    echo -e "${green}Updating ${nc}${bold}dg-firefox-theme ${nc}in ${bold}${PWD}${nc}"
  else
    echo -e "${green}Installing ${nc}${bold}${color} dg-firefox-theme ${nc}in ${bold}${PWD}${nc}"
  fi

  # Create a chrome directory if it doesn't exist.
  mkdir -p chrome
  cd chrome || exit

  # Copy theme repo inside
  cp -fR "$themedirectory" "$PWD"

  # Set accent color
  sed -i "/\$accent_color:/s/orange/${color}/" "${PWD}"/dg-firefox-theme/theme/colors/sass/_accent-colors.scss

  # Generate CSS
  sassc -M -t expanded "${PWD}/dg-firefox-theme/theme/colors/sass/dark-yaru.scss"  "${PWD}/dg-firefox-theme/theme/colors/dark-yaru.css"
  sassc -M -t expanded "${PWD}/dg-firefox-theme/theme/colors/sass/light-yaru.scss" "${PWD}/dg-firefox-theme/theme/colors/light-yaru.css"

  # Remove Sass directory
  rm -rf "${PWD}/dg-firefox-theme/theme/colors/sass"

  # Create single-line user CSS files if non-existent or empty.
  if [ -s userChrome.css ]; then
    # Remove older theme imports
    sed 's/@import "dg-firefox-theme.*.//g' userChrome.css | sed '/^\s*$/d' > tmpfile && mv tmpfile userChrome.css
    echo >> userChrome.css
  else
    echo >> userChrome.css
  fi

  # Import this theme at the beginning of the CSS files.
  sed -i '1s/^/@import "dg-firefox-theme\/userChrome.css";\n/' userChrome.css

  if [ $theme = "yaru" ]; then
    echo "@import \"dg-firefox-theme\/theme/colors/light-$theme.css\";" >> userChrome.css
    echo "@import \"dg-firefox-theme\/theme/colors/dark-$theme.css\";" >> userChrome.css
  fi

  # Create single-line user content CSS files if non-existent or empty.
  if [ -s userContent.css ]; then
    # Remove older theme imports
    sed 's/@import "dg-firefox-theme.*.//g' userContent.css | sed '/^\s*$/d' > tmpfile && mv tmpfile userContent.css
    echo >> userContent.css
  else
    echo >> userContent.css
  fi

  # Import this theme at the beginning of the CSS files.
  sed -i '1s/^/@import "dg-firefox-theme\/userContent.css";\n/' userContent.css

  if [ $theme = "yaru" ]; then
    echo "@import \"dg-firefox-theme\/theme/colors/light-$theme.css\";" >> userContent.css
    echo "@import \"dg-firefox-theme\/theme/colors/dark-$theme.css\";" >> userContent.css
  fi

  cd ..

  # Symlink user.js to dg-firefox-theme one.
  ln -fs chrome/dg-firefox-theme/configuration/user.js user.js

  cd ..
}

profiles_file="${firefoxfolder}/profiles.ini"
if [ ! -f "${profiles_file}" ]; then
  >&2 echo -e "${red}Failed${nc}, please check Firefox installation, unable to find profiles.ini at ${firefoxfolder}"
  exit 1
fi

profiles_paths="$(grep -E "^Path=" "${profiles_file}" | tr -d '\n' | sed -e 's/\s\+/SPACECHARACTER/g' | sed 's/Path=/::/g')"
profiles_paths+="::"

profiles_array=()
if [ "${profilename}" != "" ];
  then
    echo "Using ${profilename} theme"
    profiles_array+=("${profilename}")
else
  while [[ $profiles_paths ]]; do
    profiles_array+=( "${profiles_paths%%::*}" )
    profiles_paths=${profiles_paths#*::}
  done
fi

if [ ${#profiles_array[@]} -eq 0 ]; then
  echo No Profiles found on "$profiles_file";

else
  for i in "${profiles_array[@]}"
  do
    if [[ -n "$i" ]];
    then
      saveProfile "$(sed 's/SPACECHARACTER/ /g' <<< "$i")"
    fi;
  
  done
fi
