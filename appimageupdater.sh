#!/bin/bash
# move this file to ~/Applications/appimageupdater.sh

# ==== SETUP ====

# change if necessary
TRACKED_DIRS=("/Applications" "$HOME/Applications")
AIU_NAME="appimageupdatetool-*.AppImage"

# internal constants
read -r -d '' USAGE_STRING << 'EOF'
Usage: %s [-vh]
  -n  send a notification after updates with the number of
      updated applications (only if there's at least one)
  -v  verbose mode (show output from appimageupdatetool-*.AppImage)
  -h  displays this help and exits
EOF
NOTIFY=""
VERBOSE=""

# flags management
while getopts 'nvh' flag; do
	case "${flag}" in
		n) NOTIFY="1" ;;
		v) VERBOSE="1" ;;
		h) printf "$USAGE_STRING\n" $0; exit 0 ;;
		*) printf "$USAGE_STRING\n" $0; exit 1 ;;
	esac
done


# ==== MAIN CODE ====

shopt -s nullglob # prevents literal globs in case there are no matches
trap 'echo -e "\e[31m# Aborted, updated $updated AppImages.\e[0m"; exit 1' SIGINT

out=$( [ $VERBOSE ] && echo "/dev/stdout" || echo "/dev/null" )
updated=0
aiu_exe=""

# update logic
function handle_update() {
	app=$1

	# TODO: elevating the whole $aiu_exe is NOT A GOOD IDEA
	#       uncomment this at your own risk! (a better idea might be to use ACL)

	#[ ! -w "$app" ] && prepend="pkexec"

	$prepend $aiu_exe -O "$app" &> $out
	success=$?

	if [ $success -eq 0 ]; then
		echo -e "\e[32m# Successfully updated $app\e[0m"
		((updated+=1))
	else
		echo -e "\e[31m# Something went wrong while updating $app (exit code $success)\e[0m"
	fi
}

# lookup appimageupdatetool
for d in ${TRACKED_DIRS[*]}; do
	if [ -x $d/$AIU_NAME ]; then
		aiu_exe=$d/$AIU_NAME
		break
	fi
done

if [ ! $aiu_exe ]; then
	echo -e "\e[31m# appimageupdatetool not found in ${TRACKED_DIRS[*]}, or missing x permission. Cannot check updates.\e[0m"
	exit 1
fi

# iterate over appimages
for d in ${TRACKED_DIRS[*]}; do

	pushd $d > /dev/null

	# assumption: appimages are readable by us
	for i in $(echo "*.AppImage" "*.appimage"); do
		echo -e "\e[34m# Checking updates for $i\e[0m"
		$aiu_exe -j "$i" &> $out
		updatable=$?
		[ $VERBOSE ] && echo "" # sometimes $aiu_exec doesn't print trailing \n
		case $updatable in
			0) echo -e "\e[1;33m# No updates available for $i\e[0m" ;;
			1) handle_update "$i" ;;
			*) echo -e "\e[31m# Cannot check updates for $i (exit code $updatable)\e[0m" ;;
		esac
	done

	popd > /dev/null

done

# final prints
echo -e "\e[34m# Done, updated $updated AppImages.\e[0m"

if [ $NOTIFY ] && [ $updated -gt 0 ]; then
	notify-send -i dialog-information-symbolic "Updated $updated AppImages"
fi
