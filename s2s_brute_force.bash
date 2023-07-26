#!/bin/bash

function http_basic_fast_check() {

	initialize "$@"
	local url=$2

	local cleanedURL="$(cleanURLKeepHTTPAndHTTPS $url)"

	local resourcesDir="/opt/tools/s2s_tools/resources"

	local timestamp=$(getTimeForFile)
	local output=$workPath/ffuf.$cleanedURL.$timestamp.json

	/opt/tools/ffuf-scripts/ffuf_basicauth.sh "$resourcesDir/top-usernames-shortlist.txt" "$resourcesDir/top-passwords-shortlist.txt" | ffuf -w -:AUTH -u $url -H "Authorization: Basic AUTH" -fc 403 -c -of json -o $output
        cat $output | jq | tee $output


	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="
}
