#!/usr/bin/env bash
# A tool to create a new python project with less setup than usual.
# v1.0 Jul 2021 by Cronocide


# Boilerplate functions from bash_profile for convenience
OS="$(uname -a)"
[[ "$OS" == *"iPhone"* || "$OS" == *"iPad"* ]] && export OS="iOS"
[[ "$OS" == *"ndroid"* ]] && export OS="Android"
[[ "$OS" == *"kali"* ]] && export OS="Kali"
[[ "$OS" == *"indows"* ]] && export OS="Windows"
[[ "$OS" == *"arwin"* ]] && export OS="macOS"
[[ "$OS" == *"BSD"* ]] && export OS="BSD"
[[ "$OS" == *"inux"* ]] && export OS="Linux"

__no_req() {
	[[ "$(type $1 2>/dev/null)" == "" ]] && return 0;
	return 1
}

__missing_reqs() {
	for i in "$@"; do
		[[ "$0" != "$i" ]] && __no_req "$i" && echo "$i is required to perform this function." && return 0;
	done;
	return 1
}

__missing_sed() {
	__no_req "sed" && __no_req "gsed" && echo "sed or gsed is required to perform this function." && return 0
}

sed_i() {
	__missing_sed && return 1;
	if [[ "$OS" == "macOS" ]]; then
		if [[ $(type gsed 2>/dev/null) != "" ]]; then
			gsed -i "$@";
		else
			sed -i '' "$@";
		fi;
	else
		sed -i $@;
	fi
}

# Project creation
new_python_tool() {
	# Download and rename the template repo
	__missing_reqs 'sed git find grep sort mv' && return 1
	if [[ $(pwd) == *"python-tool"* ]]; then
		echo "This script should not be run within the python-tool directory. Please move it to a neutral location to run." && return 1
	fi
	NAME="$1"
	if [[ $(echo "$1" | sed 's#^[a-z0-9\-]*$##' ) == "$NAME" ]]; then
		echo "Tool name '""$NAME""' is invalid." && return 1
	fi
	if [ ! -d ./python-tool ]; then
		echo "Downloading template..."
		git clone 'https://github.com/Cronocide/python-tool.git'
	fi
	echo "Renaming project..."
	# Rather novel approach from https://stackoverflow.com/a/53734138
	find ./ -depth -name '*python-tool*' | while IFS= read -r i; do mv $i ${i%python-tool*}$NAME${i##*python-tool}; done
	# "I'm assuming you have no spaces in the project name because you're not an idiot."
	for i in $(grep -r 'python-tool' ./"$NAME" | grep -v '.git' | cut -d \: -f 1 | sort -u); do
		sed_i "s#python-tool#$NAME#g" "$i"
	done
	mv ./"$NAME"/com.cronocide."$NAME".plist ./"$NAME"/com."$USER"."$NAME".plist
	echo "Configuring project..."

	# Describe the project
	echo "Describe the project: "
	read DESCRIPTION
	sed_i "s/## ->.*//g" ./"$NAME"/README.md
	sed_i "s/## Description/## $DESCRIPTION/g" ./"$NAME"/README.md
	sed_i "s/\(.*\)description='',/\1description='$DESCRIPTION',/g" ./"$NAME"/setup.py

	# Configure package as a module?
	while [[ "$PYTHON_MODULE" != 'y' && "$PYTHON_MODULE" != "n" ]]; do
		echo "Set up project as a module? (in addition to a singular executable script) (y/n)"
		read PYTHON_MODULE
	done
	if [ "$PYTHON_MODULE" == 'y' ]; then
		mkdir ./"$NAME"/"$NAME"
		touch ./"$NAME"/"$NAME"/__init__.py
		touch ./"$NAME"/"$NAME"/"$NAME".py
	fi

	# Configure package to install as a persistent service?
	while [[ "$SERVICE_FILE" != 'y' && "$SERVICE_FILE" != "n" ]]; do
		echo "Install a persistent service file? (y/n)"
		read SERVICE_FILE
	done
	if [ "$SERVICE_FILE" == 'y' ]; then
		sed_i "s#INSTALL=\"\(.*\)\"#INSTALL=\"\1services \"#g" ./"$NAME"/setup.sh
		# Configure service file to log output to file?
		while [[ "$SERVICE_LOG" != 'y' && "$SERVICE_LOG" != "n" ]]; do
			echo "Configure the service file to log output? (y/n)"
			read SERVICE_LOG
		done
		if [ "$SERVICE_LOG" != 'y' ]; then
			sed_i 's#.*Standard.*##g' ./"$NAME"/com."$USER"."$NAME".plist
			sed_i 's#.*/var/log.*##g' ./"$NAME"/com."$USER"."$NAME".plist
			sed_i 's#.*[sS]yslog.*##g' ./"$NAME"/"$NAME".service
		fi
		# Don't forget to configure the service files.
		echo "Don't forget to configure your service files."
	else
		# Remove the custom setup scripts
		rm ./"$NAME"/com."$USER"."$NAME".plist
		rm ./"$NAME"/"$NAME".service
	fi

	# Configure package to load plugins from plugins directory?
	while [[ "$USE_PLUGINS" != 'y' && "$USE_PLUGINS" != "n" ]]; do
		echo "Configure package to load plugins? (y/n)"
		read USE_PLUGINS
	done
	if [ "$USE_PLUGINS" == 'y' ]; then
		# You've made Thomas Hatch proud.
		! [ -d ./"$NAME"/"$NAME" ] && mkdir ./"$NAME"/"$NAME"
		mkdir ./"$NAME"/"$NAME"/plugins
	else :
		sed_i 's#.*plugins.*##g' ./"$NAME"/setup.py
	fi

	# Configure package to install a default configuration file?
	while [[ "$INSTALL_CONFIG" != 'y' && "$INSTALL_CONFIG" != "n" ]]; do
		echo "Configure package to install a config file? (y/n)"
		read INSTALL_CONFIG
	done
	if [ "$INSTALL_CONFIG" == 'y' ]; then
		sed_i "s#INSTALL=\"\(.*\)\"#INSTALL=\"\1config \"#g" ./"$NAME"/setup.sh
	else
		rm ./"$NAME"/config.yml
	fi

	# Remove setup.sh if our tool doesn't need it to install.
	if [[ "$SERVICE_FILE" != 'y' && "$INSTALL_CONFIG" != 'y' ]]; then
		sed_i 's#cmdclass=.*##g' ./"$NAME"/setup.py
		rm ./"$NAME"/setup.sh
	fi

	# Initialize the git repo
	rm -rf ./"$NAME"/.git
	git init ./"$NAME"

	# Delete self from project_file
	[ -f ./"$NAME"/new_python_tool.sh ] && echo "Removing project setup script..." && rm ./"$NAME"/new_python_tool.sh
	echo "Python tool $NAME is ready to start."

	# Next steps
	echo "Next steps:"
	echo " 1. Modify your bin/$NAME file to load your project libraries (if applicable)"
	echo " 2. Add a remote to the git repo"
	echo " 3. Add the correct dependencies in setup.py"
	echo " 4. Update the execution and logging parameters in your service files (if applicable)"
	echo " 5. Write the software"
	echo " 6. ..."
	echo " 7. Profit"
}

new_python_tool "$1"
