#!/usr/bin/env bash

NAME="alpine-mirror-http"
TITLE="Alpine Mirror"
SUBTITLE="HTTP"
AUTHOR="Johanna Walter"
AUTHOR_EMAIL="johanna@walter.fm"
AUTHOR_DOCKER="itsjohannawren"
AUTHOR_GITHUB="itsjohannawren"

# ==============================================================================

VARIABLES=(
	"HTTP_ADDR^^0.0.0.0"
	"HTTP_PORT^^80"
)

# ==============================================================================

_INDENT="0"
indent() {
	_INDENT="$((_INDENT + 1))"
}
outdent() {
	_INDENT="$((_INDENT - 1))"
	if [ "${_INDENT}" -lt "0" ]; then
		_INDENT="0"
	fi
}

_message() { # TYPE, COLOR, MESSAGE
	local TYPE="${1}"
	local COLOR="${2}"
	local MESSAGE="${3}"
	local FIRST="y"

	if [ "$(wc -l <<<"${MESSAGE}" | awk '{print $1}')" != "1" ]; then
		while read -r LINE; do
			if [ -n "${FIRST}" ]; then
				printf "%s%7s: %$((_INDENT * 3))s%s%s\n" $'\x1b[1;'"${COLOR}m" "${TYPE}" "" $'\x1b[0m' "${LINE}"
				FIRST=""
			else
				echo "         ${LINE}"
			fi
		done <<<"${MESSAGE}"
	else
		printf "%s%7s: %$((_INDENT * 3))s%s%s\n" $'\x1b[1;'"${COLOR}m" "${TYPE}" "" $'\x1b[0m' "${MESSAGE}"
	fi
}
debug() { # MESSAGE
	_message "Debug" "36" "${1}"
}
info() { # MESSAGE
	_message "Info" "37" "${1}"
}
notice() { # MESSAGE
	_message "Notice" "32" "${1}"
}
warning() { # MESSAGE
	_message "Warning" "33" "${1}" 1>&2
}
error() { # MESSAGE
	_message "Error" "31" "${1}" 1>&2
}
fatal() { # MESSAGE
	_message "Fatal" "31" "${1}" 1>&2
	exit 1
}

separator() {
	echo -e $'\x1b[1;30m'
	echo '--------------------------------------------------------------------------------'
	echo -e $'\x1b[0m'
}

# ==============================================================================

TOSSER="${TITLE}: ${SUBTITLE}"
TOSSER_LENGTH="${#TOSSER}"
TITLE_PADDING="$((43 - TOSSER_LENGTH))"

echo -ne $'\x1b[1;37m'
echo   '                      ____            ____'
echo   '      _      ______ _/ / /____  _____/ __/___ ___'
echo   '     | | /| / / __ `/ / __/ _ \/ ___/ /_/ __ `__ \'
echo   '     | |/ |/ / /_/ / / /_/  __/ /  / __/ / / / / /'
echo   '     |__/|__/\__,_/_/\__/\___/_(_)/_/ /_/ /_/ /_/'
echo -ne $'\x1b[0;35m'
echo   '   _______________________________________________  _____    ___'
echo   '  /                                              / /    /   /  /'
if [ -n "${SUBTITLE}" ]; then
	printf " /  %s%s %s%s%${TITLE_PADDING}s  %s/ /    /   /  /\n" $'\x1b[1;37m' "${TITLE}" $'\x1b[0m' "${SUBTITLE}" "" $'\x1b[35m'
else
	printf " /  %s%s%$((TITLE_PADDING + 1))s  %s/ /    /   /  /\n" $'\x1b[1;37m' "${TITLE}" "" $'\x1b[0;35m'
fi
echo   '/______________________________________________/ /____/   /__/'
echo -ne $'\x1b[0m'
echo
echo   "    https://hub.docker.com/u/${AUTHOR_DOCKER}/${NAME}"
echo   "    https://github.com/${AUTHOR_GITHUB}/${NAME}"
echo   "    ${AUTHOR} <${AUTHOR_EMAIL}>"
separator

# ==============================================================================

info "Loading environment..."
indent

for PAIR in "${VARIABLES[@]}"; do
	VARIABLE="${PAIR%^^*}"
	DEFAULT="${PAIR#*^^}"

	eval ${VARIABLE}="${!VARIABLE:-${DEFAULT}}"
	info "$(declare -p "${VARIABLE}" | awk '{$1=$2="";sub(/^ */,"");print}')"
done

outdent

info "Saving environment..."
indent

info "Removing any previously saved environment"
indent
if rm -f /environment &>/dev/null; then
	notice "Removed /environment"
else
	notice "No saved environment to remove"
fi
outdent

info "Writing /environment"
for PAIR in "${VARIABLES[@]}"; do
	VARIABLE="${PAIR%^^*}"

	if ! tee -a /environment &>/dev/null <<<"$(declare -p "${VARIABLE}" | awk '{$1=$2="";sub(/^ */,"");print}')"; then
		fatal "Failed to write ${VARIABLE} to /environment"
	fi
done
notice "Wrote /environment"

outdent

# ==============================================================================

info "Checking directory structure..."
indent

info "/data/alpine"
indent
if [ ! -e /data/alpine ]; then
	info "Creating /data/alpine"
	if mkdir /data/alpine &>/dev/null; then
		notice "Created /data/alpine"
	else
		fatal "Failed to create /data/alpine"
	fi
elif [ ! -d /data/alpine ]; then
	fatal "/data/alpine exists but is not a directory"
fi
outdent

outdent

# ==============================================================================

info "Filling in templates..."
indent

info "/etc/lighttpd/lighttpd.conf"
indent
info "Reading /templates/lighttpd.conf"
HTTPD_CONF="$(cat /templates/lighttpd.conf 2>/dev/null)"
if [ "$?" = "0" ]; then
	notice "Read /templates/lighttpd.conf"
else
	fatal "Failed to read /templates/lighttpd.conf"
fi
HTTPD_CONF="${HTTPD_CONF//%HTTP_ADDR%/${HTTP_ADDR}}"
HTTPD_CONF="${HTTPD_CONF//%HTTP_PORT%/${HTTP_PORT}}"
info "Writing /etc/lighttpd/lighttpd.conf"
if tee /etc/lighttpd/lighttpd.conf &>/dev/null <<<"${HTTPD_CONF}"; then
	notice "Wrote /etc/lighttpd/lighttpd.conf"
else
	fatal "Failed to write /etc/lighttpd/lighttpd.conf"
fi
outdent

outdent

# ==============================================================================

notice "Launching..."
separator

exec /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf

fatal "Failed to launch"
