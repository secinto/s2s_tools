#!/bin/bash

#============================================================================
# Performs a directory enumeration (brute force - forced browsing) using 
# a default wordlist and the gobuster tool.
#
# Usage:
#	ferox project URL
# 
# Additional parameters:
#
#	ferox project URL [recurse] [errorCodes] [defaultLists] [auto] [words] [wordlist]
#
#	[recurse] 		Boolean		Recursion for every found item
#	[errorCodes]	String		List of comma separated error codes which should be filtered
# 	[defaultLists]  Integer		Switching between default list 
#									0 ... onelistforallmicro
#									1 ... raft-medium-directories-lowercase
#	[auto]			Boolean		Enables automatic backoff and collection of words
# 	[words]			Integer		Comma separated list of Word counts which should be filtered
#	[wordlist]		String		Manually specified word list.
#
#
# Used tools:
# source{1}:https://github.com/epi052/feroxbuster
# install{1}:{sudo snap install feroxbuster}
# source{2}:https://github.com/danielmiessler/SecLists
# install{2}:{git clone https://github.com/danielmiessler/SecLists.git}
#============================================================================
function ferox() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local url=$2
	local cleanedURL=$(cleanURL $url)
	local outputPath=$defaultPath/host
	mkdir -p $outputPath
	
	local recursive=false
	
	if [ "$#" -gt 2 ]; then
		recursive=$3
	fi
	
	local errorCodes=301,302,400,404,503
	
	if [ "$#" -gt 3 ]; then
		if [ ! "$4" -eq 0 ]; then
			local errorCodes=$errorCodes,$4
		fi
	fi	
	
	local wordlist=/opt/tools/s2s_tools/resources/onelistforallmicro.txt
	local output=$outputPath/ferox.$cleanedURL.onelist.output.json
	
	if [ "$#" -gt 4 ]; then
		if [ "$#" -gt 7 ]; then
				local wordlist=$8
				local wordlist_name=$(getFilename $wordlist)
				local output=$outputPath/ferox.$cleanedURL.$wordlist_name.output.json
		else
			if [ "$5" -eq 1 ]; then
				local wordlist=/opt/tools/s2s_tools/resources/raft-medium-directories-lowercase.txt
				local output=$outputPath/ferox.$cleanedURL.raft-directory.output.json
			fi
		fi
	fi
	
	if $recursive; then
		if [ "$#" -gt 5 ]; then
			if [ "$#" -gt 6 ]; then
				feroxbuster --smart -r -k -f -C $errorCodes --url $url --json -o $output -w $wordlist -W $7
			else
				feroxbuster --auto-tune --collect-words -r -k -f -C $errorCodes --url $url --json -o $output -w $wordlist
			fi
		else
			feroxbuster --smart -r -k -f -C $errorCodes --url $url --json -o $output -w $wordlist
		fi	
	else
		if [ "$#" -gt 5 ]; then
			if [ "$#" -gt 6 ]; then
				feroxbuster --smart -r -k -f -n -C $errorCodes --url $url --json -o $output -w $wordlist -W $7
			else
				feroxbuster --auto-tune --collect-words -r -n -k -f -C $errorCodes --url $url --json -o $output -w $wordlist
			fi
		else
			feroxbuster --smart -r -k -f -n -C $errorCodes --url $url --json -o $output -w $wordlist 
		fi	
	fi
	
	sendToELK $output ferox

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="

}

function ferox_list() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local url_list=$2

	exec 3<$url_list
	while read line <&3
	do	
		ferox $1 $line "${@:3}"
	done

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="
}


#============================================================================
# Performs a directoy enumeration (brute force - forced browsing) using 
# a default wordlist and the ffuf tool.
#
# Used tools:
# source{1}:https://github.com/ffuf/ffuf
# install{1}:{go install -v github.com/ffuf/ffuf@latest}
# source{2}:https://github.com/danielmiessler/SecLists
# install{2}:{git clone https://github.com/danielmiessler/SecLists.git}
#============================================================================
function ffuf_dir() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local url=$2

	local cleanedURL=$(cleanURLKeepHTTPAndHTTPS $url)
	local output=$defaultPath/host/ffuf.$cleanedURL.output.json
	local result=$defaultPath/host/ffuf.$cleanedURL.result.txt
	
	local responseCodeFilter="301,302,404"
	local wildcard=0

	if [ $# -eq 3 ]; then
		if [[ $3 == "--wildcard" ]]; then
			((wildcard=1))
		else
			responseCodeFilter+=",$3"
		fi
	fi

	ffuf -fc $responseCodeFilter -w /opt/tools/s2s_tools/onelistforallmicro.txt -u $url/FUZZ -o $output -of json

	sendToELK $output ffuf
	
	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="
}
