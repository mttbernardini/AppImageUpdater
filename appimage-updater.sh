#!/bin/bash

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
	case "$flag" in
		n) NOTIFY="1" ;;
		v) VERBOSE="1" ;;
		h) printf "$USAGE_STRING\n" "$0"; exit 0 ;;
		*) printf "$USAGE_STRING\n" "$0"; exit 1 ;;
	esac
done


# ==== MAIN CODE ====

tmpdir=$(mktemp -d)

function aborted() {
	rm -rf "$tmpdir"
	echo -e "\e[31m# Aborted, updated $updated AppImages.\e[0m"
	exit 1
}
trap aborted SIGINT

[ "$VERBOSE" ] && out="/dev/stdout" || out="/dev/null"
updated="0"
aiu_exec=""

# update logic
function handle_update() {
	local app="$1"
	local elevate=""

	# work on a temp dir link to avoid permission issues and clobbering with temp files
	ln -srt "$tmpdir" "$app"
	pushd "$tmpdir" > /dev/null

	# nb: -O doesn't actually "overwrite", but rather replaces the file (i.e. original file is unlinked)
	"$aiu_exec" -O "$app" &> "$out"
	local success="$?"
	popd > /dev/null

	if [ "$success" -eq 0 ]; then
		[ ! -w . ] && elevate="pkexec" # in case we don't have write access to the original directory
		"$elevate" mv -ft . "$tmpdir/$app"
		echo -e "\e[32m# Successfully updated $app\e[0m"
		((updated+=1))
	else
		echo -e "\e[31m# Something went wrong while updating $app (exit code $success)\e[0m"
	fi
}

# lookup appimageupdatetool
for d in ${TRACKED_DIRS[*]}; do
	if [ -x "$d"/$AIU_NAME ]; then
		aiu_exec=$(echo "$d"/$AIU_NAME) # force glob expansion
		break
	fi
done

if [ ! "$aiu_exec" ]; then
	echo -e "\e[31m# appimageupdatetool not found in ${TRACKED_DIRS[*]}, or missing x permission. Cannot check updates.\e[0m"
	exit 1
fi

# iterate over appimages
for d in ${TRACKED_DIRS[*]}; do

	cd "$d" &> "$out" || continue

	shopt -s nullglob # prevents literal globs in case there are no matches
	for i in *.AppImage *.appimage; do
		echo -e "\e[34m# Checking updates for $i\e[0m"
		"$aiu_exec" -j "$i" &> "$out"
		updatable="$?"
		[ "$VERBOSE" ] && echo # sometimes $aiu_exec doesn't print trailing \n
		case "$updatable" in
			0) echo -e "\e[1;33m# No updates available for $i\e[0m" ;;
			1) handle_update "$i" ;;
			*) echo -e "\e[31m# Cannot check updates for $i (exit code $updatable)\e[0m" ;;
		esac
	done

done

# final stuff
rm -rf "$tmpdir"
echo -e "\e[34m# Done, updated $updated AppImages.\e[0m"

if [ "$NOTIFY" ] && [ "$updated" -gt 0 ]; then
	notify-send -i dialog-information-symbolic "Updated $updated AppImages"
fi
