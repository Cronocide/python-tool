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

__require_bash() {
	__no_req "sort" && return 1;
	[[ $(printf "$1\n$BASH_VERSION" | sort -V | head -n 1) != "$1" ]] && return 1;
	return 0
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
		sed -i "$@";
	fi
}

# Project creation
new_python_tool() {
	# Check that we can run this tool
	if ! $(__require_bash "4.3"); then echo "Bash 4.3 or greater is required to run this script." && return 1; fi
	__missing_reqs 'sed git find grep sort mv' && return 1
	if [[ $(pwd) == *"python-tool"* ]]; then
		echo "This script should not be run within the python-tool directory. Please move it to a neutral location to run." && return 1
	fi
	[ -z "$1" ] && echo "Usage: new_python_tool <name_of_tool>" && return 1
	NAME="$1"
	if [[ $(echo "$1" | sed 's#^[a-z0-9\_]*$##' ) == "$NAME" ]]; then
		echo "Tool name '""$NAME""' is invalid." && return 1
	fi

	# Download and rename the template repo
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

	# Record setup instructions
	declare -a PYTHON_TOOL_SETUP_INSTRUCTIONS
	declare -a PYTHON_TOOL_WARNINGS

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
		echo "from $NAME.$NAME import *" > ./"$NAME"/"$NAME"/__init__.py
		echo "# Write your modular code (classes, functions, etc) here. They'll be automatically imported in bin/$NAME" > ./"$NAME"/"$NAME"/"$NAME".py
		PYTHON_TOOL_SETUP_INSTRUCTIONS+=("Put your main classes and functionality in $NAME/$NAME.py and import/use that functionality in bin/$NAME")
		PYTHON_TOOL_WARNINGS+=('You can use this package as a library! Classes you define in '"$NAME/$NAME.py"" can be imported with 'import $NAME.class_name")
	else
		PYTHON_TOOL_SETUP_INSTRUCTIONS+=("Put your main classes and functionality in bin/$NAME")
		sed_i "s#import $NAME##g" ./"$NAME"/bin/"$NAME"
	fi

	# Configure package to install as a persistent service?
	while [[ "$SERVICE_FILE" != 'y' && "$SERVICE_FILE" != "n" ]]; do
		echo "Install a persistent service file? (systemd/launchd services ONLY) (y/n)"
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
		PYTHON_TOOL_SETUP_INSTRUCTIONS+=("Modify your service files ($NAME.service and com.$USER.$NAME.plist) to schedule when the tool should run. By default, they run at boot and stay alive.")
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
		sed_i "s/.*##PLUGIN_\(.*\)/\1/g" ./"$NAME"/bin/"$NAME"
		mkdir ./"$NAME"/"$NAME"/plugins
		touch ./"$NAME"/"$NAME"/plugins/plugin.py
		PYTHON_TOOL_SETUP_INSTRUCTIONS+=("Set your plugin class by setting the plugin_class variable in bin/$NAME and defining the class in $NAME/plugins/*.py files.")
		PYTHON_TOOL_WARNINGS+=("At least one .py file needs to exist in $NAME/plugins/ for the plugin directory to be packaged for install. 'plugin.py' is provided for this purpose, but can be removed if you have other plugins. The file can be empty.")
		PYTHON_TOOL_WARNINGS+=("When installing this package, you MUST use 'pip install -e' to link the executable to the package directory. This allows your plugins to work.")
		if [[ "$PYTHON_MODULE" == 'y' ]]; then
			PYTHON_TOOL_WARNINGS+=("Migrating the plugin-loading logic from bin/$NAME to $NAME/$NAME.py might be a good idea if you want your plugins to be loaded as part of your library.")
		fi
	else :
		sed_i 's#.*plugins.*##g' ./"$NAME"/setup.py
		sed_i "/.*##PLUGIN_\(.*\)/d" ./"$NAME"/bin/"$NAME"
	fi

	# Configure package to install a default configuration file?
	while [[ "$INSTALL_CONFIG" != 'y' && "$INSTALL_CONFIG" != "n" ]]; do
		echo "Configure package to use and install a config file? (y/n)"
		read INSTALL_CONFIG
	done
	if [ "$INSTALL_CONFIG" == 'y' ]; then
		sed_i "s#INSTALL=\"\(.*\)\"#INSTALL=\"\1config \"#g" ./"$NAME"/setup.sh
		sed_i "s/.*##CONFIG_\(.*\)/\1/g" ./"$NAME"/bin/"$NAME"
		PYTHON_TOOL_WARNINGS+=("You'll need to install a copy of the config file yourself for debugging, as config.yml will only be installed when the package is installed.")
	else
		sed_i "/.*##CONFIG_\(.*\)/d" ./"$NAME"/bin/"$NAME"
		rm ./"$NAME"/config.yml
	fi

	# Remove setup.sh if our tool doesn't need it to install.
	if [[ "$SERVICE_FILE" != 'y' && "$INSTALL_CONFIG" != 'y' ]]; then
		sed_i 's#cmdclass=.*##g' ./"$NAME"/setup.py
		rm ./"$NAME"/setup.sh
	else
		PYTHON_TOOL_WARNINGS+=("The target system will need to have bash to run the postinstall actions you've chosen.")
	fi

	# Initialize the git repo
	rm -rf ./"$NAME"/.git
	git init ./"$NAME"

	# Delete self from project_file
	[ -f ./"$NAME"/new_python_tool.sh ] && echo "Removing project setup script..." && rm ./"$NAME"/new_python_tool.sh
	echo "Python tool $NAME is ready to start!"

	PYTHON_TOOL_SETUP_INSTRUCTIONS+=("Add a remote to the git repo (git remote add origin <url>)")
	PYTHON_TOOL_SETUP_INSTRUCTIONS+=("Update your library dependencies in setup.py as you add them to your project.")

	# Next steps
	echo "Next steps:"
	OLDIFS=$IFS
	IFS=$'\n'
	for ((i = 0; i < ${#PYTHON_TOOL_SETUP_INSTRUCTIONS[@]}; i++)); do
		STEPCOUNT=$(( "$i" + 1 ))
		echo " $STEPCOUNT. ${PYTHON_TOOL_SETUP_INSTRUCTIONS[$i]}"
	done
	STEPCOUNT=$(( $STEPCOUNT + 1 ))
	echo " $STEPCOUNT. ..." && STEPCOUNT=$(( $STEPCOUNT + 1 )) && echo " $STEPCOUNT. Profit" && echo
	IFS=$OLDIFS
	if [[ ${#PYTHON_TOOL_WARNINGS[@]} -gt 0 ]]; then
		OLDIFS=$IFS
		IFS=$'\n'
		echo "Things to consider:"
		for ((i = 0; i < ${#PYTHON_TOOL_WARNINGS[@]}; i++)); do
			echo "* ${PYTHON_TOOL_WARNINGS[$i]}"
		done
		IFS=$OLDIFS
	fi
}

new_python_tool "$1"
