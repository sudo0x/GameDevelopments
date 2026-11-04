#!/usr/bin/env bash
# Runs every test with no window. The tests write save files, so Godot gets a temporary
# home folder: your real save is never touched.
#
# Usage, from the project folder:
#   tests/run_all.sh
# To use a different Godot, set GODOT first:
#   GODOT=/path/to/godot tests/run_all.sh

set -u
cd "$(dirname "$0")/.."

if [ -z "${GODOT:-}" ]; then
	case "$(uname -s)" in
		Darwin) GODOT="/Applications/Godot.app/Contents/MacOS/Godot" ;;
		*) GODOT="/c/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe" ;;
	esac
fi

temp_home="$(mktemp -d)"
trap 'rm -rf "$temp_home"' EXIT
export HOME="$temp_home"
export APPDATA="$temp_home"

failed=0

# A test with a script error never quits, so each one gets a time limit.
run() {
	perl -e 'alarm 60; exec @ARGV' "$GODOT" --headless --path . --fixed-fps 60 --script "tests/$1.gd" 2>&1
}

clear_save() {
	find "$temp_home" -name save.cfg -delete
}

# Fails on a non-zero exit, and on any error or warning, even if every check passed.
check() {
	local output status
	output="$(run "$1")"
	status=$?
	if [ "$status" -ne 0 ] || grep -qE 'FAIL |ERROR|WARNING' <<<"$output"; then
		echo "FAILED  $1"
		grep -E 'FAIL |ERROR|WARNING' <<<"$output"
		failed=$((failed + 1))
	else
		echo "passed  $1"
	fi
}

"$GODOT" --headless --import --path . >/dev/null 2>&1

for test_file in tests/test_*.gd; do
	clear_save
	check "$(basename "$test_file" .gd)"
done

# These come in pairs: the first plays and saves, the second is a fresh start that loads it.
for pair in save healed_land; do
	clear_save
	check "${pair}_1_play"
	check "${pair}_2_check"
done

echo
if [ "$failed" -eq 0 ]; then
	echo "All tests passed."
else
	echo "$failed test(s) failed."
	exit 1
fi
