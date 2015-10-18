#!/bin/bash
if [ -z "$HOME" ]; then
	echo "ERROR: 'HOME' environment variable is not set!"
	exit 1
fi
# Source https://github.com/bash-origin/bash.origin
. "$HOME/.bash.origin"
function init {
	eval BO_SELF_BASH_SOURCE="$BO_READ_SELF_BASH_SOURCE"
	BO_deriveSelfDir ___TMP___ "$BO_SELF_BASH_SOURCE"
	local __BO_DIR__="$___TMP___"

	C9_EDIT_CORE_BASE_PATH="$__BO_DIR__"


	if [ -z "$GIT_CACHE_DIR" ]; then
	    echo "ERROR: 'GIT_CACHE_DIR' environment variable not set!"
	fi
	if [ -z "$WORKSPACE_DIR" ]; then
	    echo "ERROR: 'WORKSPACE_DIR' environment variable not set!"
	fi
	if [ -z "$EDITOR_PORT" ]; then
	    echo "ERROR: 'EDITOR_PORT' environment variable not set!"
	fi


	function ensurePlugin {
		BO_format "$VERBOSE" "HEADER" "Ensuring Cloud9 plugin ..."

		BO_log "$VERBOSE" "Plugin Name: $1"
		BO_log "$VERBOSE" "Plugin Path: $2"

		PLUGIN_BASE_PATH=".c9/plugins"

		pushd "$WORKSPACE_DIR" > /dev/null
			if [ ! -e "$PLUGIN_BASE_PATH" ]; then
				mkdir -p "$PLUGIN_BASE_PATH"
			fi
			BO_log "$VERBOSE" "Linking plugin from '$2' to runtime location '$PLUGIN_BASE_PATH/$1'"

			rm -Rf "$PLUGIN_BASE_PATH/$1" > /dev/null || true
			ln -s "$2" "$PLUGIN_BASE_PATH/$1"

			# TODO: Remove once implemented: https://github.com/c9/core/issues/172
#			if [ ! -e "$HOME/$PLUGIN_BASE_PATH" ]; then
#				mkdir -p "$HOME/$PLUGIN_BASE_PATH"
#			fi
#			rm -Rf "$HOME/$PLUGIN_BASE_PATH/$1" > /dev/null || true
#			ln -s "$2" "$HOME/$PLUGIN_BASE_PATH/$1"

		popd > /dev/null

		BO_format "$VERBOSE" "FOOTER"
	}
	
	function ensurePluginSetting {
		BO_format "$VERBOSE" "HEADER" "Ensuring Cloud9 plugin setting ..."

		BO_log "$VERBOSE" "Plugin Name: $1"
		BO_log "$VERBOSE" "Settings key: $2"
		BO_log "$VERBOSE" "Settings value: $3"

		SETTINGS_PATH=".c9/project.settings"

		node --eval '
			const FS = require("'$C9_EDIT_CORE_BASE_PATH'/node_modules/fs-extra");
			var config = {};
			if (FS.existsSync("'$SETTINGS_PATH'")) {
				config = JSON.parse(FS.readFileSync("'$SETTINGS_PATH'"));
			}
			var pluginName = "'$1'";
			var key = "'$2'";
			var value = "'$3'";
			if (!config[pluginName]) {
				config[pluginName] = {};
			}
			config[pluginName][key] = value;
			FS.outputFileSync("'$SETTINGS_PATH'", JSON.stringify(config, null, 4));
		'

		BO_format "$VERBOSE" "FOOTER"
	}

	function launchEditor {
		BO_format "$VERBOSE" "HEADER" "Ensuring and launching Cloud9"

		# TODO: Check for declared version and if version changes re-install.

		BASE_PATH="$GIT_CACHE_DIR/github.com/cadorn/core"
		CLONE_URL="git://github.com/cadorn/core.git"
		COMMIT_REF="536cf9d9f1e699b595dd463a2f631c2807d188d2"

		if [ ! -e "$BASE_PATH" ]; then
			if [ ! -e "$(dirname $BASE_PATH)" ]; then
				mkdir -p "$(dirname $BASE_PATH)"
			fi
			BO_log "$VERBOSE" "Cloning from '$CLONE_URL' ..."
			git clone $CLONE_URL "$BASE_PATH"
			pushd "$BASE_PATH" > /dev/null

				if [ ! -z "$COMMIT_REF" ]; then
					BO_log "$VERBOSE" "Checking out commit '$COMMIT_REF' ..."
				    git checkout $COMMIT_REF
				fi

    			BO_log "$VERBOSE" "Installing at '$BASE_PATH' ..."
				scripts/install-sdk.sh

			popd > /dev/null
		fi

		BO_log "$VERBOSE" "Running from '$BASE_PATH' ..."
		pushd "$BASE_PATH" > /dev/null
			# TODO: Detect if already open in browser and don't open again if so
			(sleep 1 && open "http://127.0.0.1:$EDITOR_PORT")&

			_WS_PATH="$WORKSPACE_DIR"

			# NOTE: We reset some variables so that they are determined based on the current path in the c9 terminal.
			export WORKSPACE_DIR=""
			export Z0_ROOT=""
			export BOOT_CONFIG_PATH=""
			export PORT=""

			node server.js --port $EDITOR_PORT -w "$_WS_PATH"
		popd > /dev/null

		BO_format "$VERBOSE" "FOOTER"
	}
}
init $@