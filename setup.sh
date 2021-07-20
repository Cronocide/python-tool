#!/bin/bash

COMMAND="$1"

[ -z "$1" ] && echo "No setup command given, nothing to do." && exit 1

export OS="$(uname -a)"
[[ "$OS" == *"iPhone"* || "$OS" == *"iPad"* ]] && export OS="iOS"
[[ "$OS" == *"ndroid"* ]] && export OS="Android"
[[ "$OS" == *"kali"* ]] && export OS="Kali"
[[ "$OS" == *"indows"* ]] && export OS="Windows"
[[ "$OS" == *"arwin"* ]] && export OS="macOS"
[[ "$OS" == *"BSD"* ]] && export OS="BSD"
[[ "$OS" == *"inux"* ]] && export OS="Linux"

setup_install() {
	echo "Installing included service files..."
	# Systemd job installation
	if [[ "$OS" == "Linux" && $(pidof systemd) ]]; then
		echo "Installing systemd job..."
		SERVICE_FILE='python-tool.service'
		SERVICE_DIR="/etc/systemd/system"
		sudo cp -r "$SERVICE_FILE" "$SERVICE_DIR"/
		sudo chown root:root "$SERVICE_DIR"/$"SERVICE_FILE"
		sudo systemctl daemon-reload
		sudo systemctl enable "$SERVICE_FILE"
		echo "Installed systemd job."
	fi

	if [[ "$OS" == "macOS" && $(ps -p 1 | grep launchd) == *"launchd" ]]; then
		echo "Installing launchd job..."
		SERVICE_FILE='com.cronocide.python-tool.plist'
		SERVICE_DIR="/Library/LaunchAgents/"
		sudo cp -r "$SERVICE_FILE" "$SERVICE_DIR"/
		sudo chmod 644 "$SERVICE_DIR"/"$SERVICE_FILE"
		sudo launchctl load "$SERVICE_FILE"
		echo "Installed launchd job."
	fi
}

setup_develop() {
	echo "Not installing service files due to being installed in development mode."
}

setup_egg_info() {
	echo "No custom egg metadata to update."
}

setup_build_ext() {
	echo "No external build scripts called."
}

case "$COMMAND" in
	"install")
		setup_install;;
	"develop")
		setup_develop;;
	"egg_info")
		setup_egg_info;;
	"build_ext")
		setup_build_ext;;
	*)
esac
