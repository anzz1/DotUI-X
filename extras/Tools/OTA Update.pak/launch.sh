#!/bin/sh

zipvalid() {
	if [ "$(hexdump -n 4 -e '1/4 "%u"' "$1" 2> /dev/null)" = "67324752" ]; then
		return 0
	fi
	return 1
}

say "Checking for update ..."

cd "$(dirname "$0")"
rm -f launch.sh.old
rm -f update-base.zip
rm -f update-extras.zip

if [ -z "$(curl --version 2> /dev/null)" ] || [ -z "$(miniunz 2> /dev/null)" ]; then
	show okay.png
	say "A system library is missing!"$'\n'$'\n'"Please reinstall DotUI."$'\n'
	confirm only
	exit 0
fi

if ! (ip route get 1.1.1.1); then
	show okay.png
	say "No internet connection."
	confirm only
	exit 0
fi

MY_VERSION="$(cat /mnt/SDCARD/.system/paks/MiniUI.pak/version.txt | head -1 | cut -d- -f3-)"
TAG="$(curl --silent -f -m 30 -L -k "https://api.github.com/repos/anzz1/DotUI-X/releases/latest" | grep '"tag_name":' | sed -r 's/.*"([^"]+)".*/\1/')"

if [ -z "$TAG" ]; then
	show okay.png
	say "Failed to check for updates."
	confirm only
	exit 0
fi
if [ "$MY_VERSION" = "$TAG" ]; then
	show okay.png
	say "You have the latest version !"
	confirm only
	exit 0
fi
show confirm.png
say "Update is available !"$'\n\n'"Yours: "$MY_VERSION""$'\n'"Latest: "$TAG""$'\n\n'"Do you want to update?"$'\n'
if ! confirm; then exit 0; fi

progressui &
PROG_PID=$!
sleep 0.5

progress 0 "Checking for free space ..."

sync
if ! [ "$(df -m /mnt/SDCARD/ | tail -1 | awk '{print $(NF-2);exit}')" -gt 100 ] 2>/dev/null; then
	progress quit
	wait $PROG_PID
	show okay.png
	say "Not enough free space !"$'\n'$'\n'"100MB of free space is"$'\n'"required for OTA update."$'\n'
	confirm only
	exit 0
fi

progress 25 "Downloading update ..."

BASE_URL="https://github.com/anzz1/DotUI-X/releases/download/$TAG/DotUI-X-$TAG-base.zip"
EXTRAS_URL="https://github.com/anzz1/DotUI-X/releases/download/$TAG/DotUI-X-$TAG-extras.zip"
curl --silent -f --connect-timeout 30 -m 600 -L -k -o update-base.zip "$BASE_URL" && \
zipvalid "update-base.zip" && \
progress 50 "Downloading update ..." && \
curl --silent -f --connect-timeout 30 -m 600 -L -k -o update-extras.zip "$EXTRAS_URL" && \
zipvalid "update-extras.zip"
if [ $? -ne 0 ] || [ ! -f update-base.zip ] || [ ! -f update-extras.zip ]; then
	progress quit
	wait $PROG_PID
	show okay.png
	say "Update download failed."
	confirm only
	exit 0
fi

progress 75 "Extracting update ..."

# kill all extras here
killall dropbear

mv launch.sh launch.sh.old
miniunz -x -o "update-base.zip" -d "/mnt/SDCARD/" && \
miniunz -x -o "update-extras.zip" -d "/mnt/SDCARD/"

if [ $? -ne 0 ]; then
	rm -rf launch.sh
	mv launch.sh.old launch.sh
	rm -rf /mnt/SDCARD/miyoo354
	sync
	progress quit
	wait $PROG_PID
	show okay.png
	say "Update extraction failed."
	confirm only
	exit 0
fi

rm -f "update-base.zip"
rm -f "update-extras.zip"
sync

progress 100 "Rebooting ..."
sleep 2
progress quit

shutdown -r
while true; do
	sync && reboot && sleep 10
done
