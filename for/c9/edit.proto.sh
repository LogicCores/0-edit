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


	if [ -z "$GIT_CACHE_DIR" ]; then
	    echo "ERROR: 'GIT_CACHE_DIR' environment variable not set!"
	fi
	if [ -z "$WORKSPACE_DIR" ]; then
	    echo "ERROR: 'WORKSPACE_DIR' environment variable not set!"
	fi
	if [ -z "$EDITOR_PORT" ]; then
	    echo "ERROR: 'EDITOR_PORT' environment variable not set!"
	fi


	function launchEditor {
		BO_format "$VERBOSE" "HEADER" "Ensuring and launching Cloud9"

		# TODO: Check for declared version and if version changes re-install.

		BASE_PATH="$GIT_CACHE_DIR/github.com/c9/core"
		
		NODEJS_VERSION="4"
		COMMIT_REF="c8163f99fba48a8ca4f963ac06303a82b1f64318"


		BO_log "$VERBOSE" "Activating NodeJS version '$NODEJS_VERSION' ..."
		BO_ensure_nvm
		if ! nvm use $NODEJS_VERSION; then
        	nvm install $NODEJS_VERSION
		fi


		if [ ! -e "$BASE_PATH" ]; then
			if [ ! -e "$(dirname $BASE_PATH)" ]; then
				mkdir -p "$(dirname $BASE_PATH)"
			fi
			BO_log "$VERBOSE" "Cloning from 'git@github.com:c9/core.git' ..."
			git clone git@github.com:c9/core.git "$BASE_PATH"
			pushd "$BASE_PATH" > /dev/null

    			BO_log "$VERBOSE" "Checking out commit '$COMMIT_REF' ..."
			    git checkout $COMMIT_REF
#				git checkout 18aff20ea4ebb33565f128123cc5d2b91cff217d
#				git checkout 0b30b4efece00ab9f6292e34793bd2271256fbcc

    			BO_log "$VERBOSE" "Installing at '$BASE_PATH' ..."
				scripts/install-sdk.sh

			popd > /dev/null
		fi

		BO_log "$VERBOSE" "Running from '$BASE_PATH' ..."
		pushd "$BASE_PATH" > /dev/null
			# TODO: Detect if already open in browser and don't open again if so
			(sleep 1 && open "http://127.0.0.1:$EDITOR_PORT")&

			node server.js --port $EDITOR_PORT -w "$WORKSPACE_DIR"
		popd > /dev/null

		BO_format "$VERBOSE" "FOOTER"
	}
}
init $@