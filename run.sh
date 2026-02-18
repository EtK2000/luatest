#!/bin/bash

run_dir=run
root_dir="$run_dir/root"
disk_root_dir="$run_dir/disk"
http_root_dir="$run_dir/http"


# find the emulator (fast-fail)
is_bsd=
case "$OSTYPE" in
	darwin*)
		craftos=/Applications/CraftOS-PC.app/Contents/MacOS/craftos
		is_bsd=1;;
	*)
		echo "no craftos config for $OSTYPE"
		exit 1;;
esac
if [[ ! -f "$craftos" ]]; then
    echo "craftos not found, should be at $craftos"
    exit 1
fi


# move to the directory this script is in
cd "$(dirname "${BASH_SOURCE[0]}")"

# cleanup any previous runs
rm -rf "$run_dir"

# setup the state for a new run
mkdir -p "$disk_root_dir"
cp installer/main.lua "$disk_root_dir/startup.lua"
mkdir -p "$http_root_dir"
cp -R ./* "$http_root_dir/"
mkdir -p "$root_dir"
cp run_helper.lua "$root_dir/startup.lua"


for arg in "$@"; do
	case "$arg" in
		--no-http-latency)
			if [[ "$is_bsd" ]]; then
				sed -i '' 's/^local httpLatency = true$/local httpLatency = false/' "$root_dir/startup.lua"
			else
				sed -i 's/^local httpLatency = true$/local httpLatency = false/' "$root_dir/startup.lua"
			fi;;
		*)
			echo "ignoring unknown argument '$arg'";;
		esac
done

# start the emulator
"$craftos" \
	--mount-rw /="$(realpath "$root_dir")" \
	--mount-rw disk="$(realpath "$disk_root_dir")" \
	--mount-rw http="$(realpath "$http_root_dir")"
