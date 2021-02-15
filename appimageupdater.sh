#!/bin/bash
# move this file to ~/Applications/appimageupdater.sh

# ==== SETUP ====

read -r -d '' USAGE_STRING << 'EOF'
Usage: %s [-vh]
  -n  send a notification after updates with the number of
      updated applications (only  there's at least one)
  -v  verbose mode (show output from appimageupdatetool-*.AppImage)
  -h  displays this help and exits
EOF

NOTIFY=""
VERBOSE=""

while getopts 'nvh' flag; do
  case "${flag}" in
    n) NOTIFY="1" ;;
    v) VERBOSE="1" ;;
    h) printf "$USAGE_STRING\n" $0; exit 0 ;;
    *) printf "$USAGE_STRING\n" $0; exit 1 ;;
  esac
done

if [ $VERBOSE ]; then
	out="/dev/stdout"
else
	out="/dev/null"
fi

updated=0


# ==== MAIN CODE ====

trap "echo -e '\e[31m# Aborted.\e[0m'" SIGINT

cd ~/Applications

if [ ! -x appimageupdatetool-*.AppImage ]; then
  echo -e "\e[31m# appimageupdatetool not found in ~/Applications, or missing x permission. Cannot check updates.\e[0m"
  exit 1
fi

for i in $(echo "*.AppImage" "*.appimage"); do
	echo -e "\e[34m# Checking updates for $i\e[0m"
	./appimageupdatetool-*.AppImage -j "$i" &> $out
	updatable=$?
	case $updatable in
	  0) echo -e "\e[1;33m# No updates available for $i";;
	  1) ./appimageupdatetool-*.AppImage "$i" &> $out # not using -r flag because is broken (deletes new appimage instead of old one)
	     echo -e "\e[32m# Successfully updated $i"; ((updated+=1)) ;;
	  *) echo -e "\e[31m# Cannot check updates for $i (exit code $updatable)";;
	esac
  # NB: sometimes old AppImages are not renamed to .zs-old, so you need to manually delete them.
  #     I could patch this, but not sure how to do it in a reliable way.
	gio trash -f "$i.zs-old"
done

echo -e "\e[34m# Done, updated $updated AppImages.\e[0m"

if [ $NOTIFY ] && [ $updated -gt 0 ]; then
	notify-send -i dialog-information-symbolic "Updated $updated AppImages"
fi
