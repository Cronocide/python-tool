#!/bin/bash

# The python-tool installation script.
# This script has been modified/generated by a project creation script.
# It assists in the installation of resources required by the tool.
# Modify at your own risk.

COMMAND="$1"
NAME="python-tool"
INSTALL=" "

[ -z "$1" ] && echo "No setup command given, nothing to do." && exit 1

export OS="$(uname -a)"
[[ "$OS" == *"iPhone"* || "$OS" == *"iPad"* ]] && export OS="iOS"
[[ "$OS" == *"ndroid"* ]] && export OS="Android"
[[ "$OS" == *"kali"* ]] && export OS="Kali"
[[ "$OS" == *"indows"* ]] && export OS="Windows"
[[ "$OS" == *"arwin"* ]] && export OS="macOS"
[[ "$OS" == *"BSD"* ]] && export OS="BSD"
[[ "$OS" == *"inux"* ]] && export OS="Linux"

install_systemd() {
	echo "Installing systemd job..."
	SERVICE_FILE="$NAME.service"
	SERVICE_DIR="/etc/systemd/system"
	sudo cp -r "$SERVICE_FILE" "$SERVICE_DIR"/
	sudo chown root:root "$SERVICE_DIR"/$"SERVICE_FILE"
	sudo systemctl daemon-reload
	sudo systemctl enable "$SERVICE_FILE"
	echo "Installed systemd job."
}

install_launchd() {
	echo "Installing launchd job..."
	SERVICE_FILE="com.$USER.$NAME.plist"
	SERVICE_DIR="/Library/LaunchAgents/"
	sudo cp -r "$SERVICE_FILE" "$SERVICE_DIR"/
	sudo chown root:wheel "$SERVICE_DIR"/"$SERVICE_FILE"
	sudo chmod 600 "$SERVICE_DIR"/"$SERVICE_FILE"
	sudo launchctl load "$SERVICE_DIR"/"$SERVICE_FILE"
	echo "Installed launchd job."
}

install_services() {
	echo "Installing included service files..."
	# Systemd job installation
	if [[ "$OS" == "Linux" && $(pidof systemd) ]]; then
		install_systemd
	fi

	if [[ "$OS" == "macOS" && $(ps -p 1 | grep launchd) == *"launchd" ]]; then
		install_launchd
	fi
}

install_config() {
	echo "Copying config file..."
	cp ./config.yml ~/.config/"$NAME".yml
}

setup_install() {
	[[ "$INSTALL" == *"services"* ]] && install_services
	[[ "$INSTALL" == *"config"* ]] && install_config
}

setup_develop() {
	echo "Not installing service files due to being installed in development mode."
	echo "Uncomment the next line to install service files anyway."
	#setup_install
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
