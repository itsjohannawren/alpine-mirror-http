#!/usr/bin/env bash

source /environment

if [ "${HTTP_ADDR}" = "0.0.0.0" ]; then
	HTTP_ADDR="127.0.0.1"
fi

exec curl -s "http://${HTTP_ADDR}:${HTTP_PORT}/" &>/dev/null
