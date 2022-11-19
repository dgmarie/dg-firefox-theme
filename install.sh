#!/usr/bin/env bash
dir="$(dirname -- "$0")"
themedirectory="$(realpath "${dir}")"
profilename=""
theme=yaru
color_variants=('orange' 'bark' 'sage' 'olive' 'viridian' 'prussiangreen' 'lightblue' 'blue' 'purple' 'magenta' 'pink' 'red')

color="orange"
firefoxfolder="${HOME}/.mozilla/firefox"

nc='\033[0m'
bold='\033[1m'
red='\033[0;31m'
bgreen='\033[1;32m'

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
    echo "  -c <color_name>. Specify accent color."
    echo "     [orange|bark|sage|olive|viridian|prussiangreen|lightblue|blue|purple|magenta|pink|red]"
    echo "     (Default: orange)"
    echo "  -h to show this message."
    exit 0
    ;;
  *)
    exit 1
    ;;
  esac
done

if ! printf '%s\0' "${color_variants[@]}" | grep -Fxqz -- "${color}"; then
  >&2 echo "ERROR: Unrecognized accent color '${color}'."
  exit 1
fi

function saveProfile(){
  local profile_path="$1"

  cd "$firefoxfolder/$profile_path" || exit

  echo -e "${bgreen}Installing${nc} the ${bold}${color} qualia Firefox theme ${nc}in ${bold}${PWD}${nc}"

  # Create a chrome directory if it doesn't exist.
  mkdir -p chrome
  cd chrome || exit

  mkdir -p qualia
  # Copy theme repo inside
  cp -fR "$themedirectory"/* "$PWD/qualia"

  # Set accent color
  sed -i "s/--yaru-orange/--yaru-${color}/g" "${PWD}"/qualia/theme/colors/light-yaru.css
  # Create single-line user CSS file
  if [ -s userChrome.css ]; then
    rm -rf userChrome.css
    echo >> userChrome.css
  else
    echo >> userChrome.css
  fi

  # Import this theme at the beginning of the CSS files.
  sed -i '1s/^/@import "qualia\/userChrome.css";\n/' userChrome.css

  if [ $theme = "yaru" ]; then
    echo "@import \"qualia\/theme/colors/light-$theme.css\";" >> userChrome.css
    echo "@import \"qualia\/theme/colors/dark-$theme.css\";" >> userChrome.css
  fi

  # Create single-line user content CSS file
  if [ -s userContent.css ]; then
    rm -rf userContent.css
    echo >> userContent.css
  else
    echo >> userContent.css
  fi

  # Import this theme at the beginning of the CSS files.
  sed -i '1s/^/@import "qualia\/userContent.css";\n/' userContent.css

  if [ $theme = "yaru" ]; then
    echo "@import \"qualia\/theme/colors/light-$theme.css\";" >> userContent.css
    echo "@import \"qualia\/theme/colors/dark-$theme.css\";" >> userContent.css
  fi

  cd ..

  # Symlink user.js to qualia one.
  ln -fs chrome/qualia/configuration/user.js user.js

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
    profiles_array+=("${profilename}")
else
  while [[ $profiles_paths ]]; do
    profiles_array+=( "${profiles_paths%%::*}" )
    profiles_paths=${profiles_paths#*::}
  done
fi

if [ ${#profiles_array[@]} -eq 0 ]; then
  >&2 echo No Profiles found on "$profiles_file"
else
  for i in "${profiles_array[@]}"; do
    if [[ -n "$i" ]]; then
      saveProfile "$(sed 's/SPACECHARACTER/ /g' <<< "$i")"
    fi
  done
fi
