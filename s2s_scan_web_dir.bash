#!/bin/bash

#============================================================================
# Performs a directory enumeration (brute force - forced browsing) using 
# a default wordlist and the gobuster tool.
#
# Usage:
#	fuzz project URL
# 
# Additional parameters:
#
#	fuzz project URL [recurse] [errorCodes] [defaultLists] [words] [wordlist] [method]
#            $1    $2    $3          $4           $5           $6      $7         $8
#
#	[recurse] 		Boolean		Recursion for every found item
#	[errorCodes]	String		List of comma separated error codes which should be filtered
# 	[defaultLists]  Integer		Switching between default list 
#									0 ... onelistforallmicro
#									1 ... raft-medium-directories-lowercase
# 	[words]			Integer		Comma separated list of Word counts which should be filtered
#	[wordlist]		String		Manually specified word list.
#	[method]		String		Comma separated list of methods to be used. E.g.: POST,DELETE,GET. Default GET is used
#
# Used tools:
# source{1}:https://github.com/epi052/feroxbuster
# install{1}:{sudo snap install feroxbuster}
# source{2}:https://github.com/danielmiessler/SecLists
# install{2}:{git clone https://github.com/danielmiessler/SecLists.git}
#============================================================================
function fuzz() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local url=$2
	local cleanedURL=$(cleanURLKeepHTTPAndHTTPS $url)
	local outputPath=$defaultPath/host
	mkdir -p $outputPath
	
	local commonOptions=""
	
	if [ "$#" -gt 2 ]; then
		local commonOptions="${commonOptions} -recursion"
	fi
	
	local errorCodes=400,404,503
	
	if [ "$#" -gt 3 ]; then
		if [ ! "$4" -eq 0 ]; then
			local errorCodes=$errorCodes,$4
		fi
	fi	
	
	local wordlist=/opt/tools/s2s_tools/resources/onelistforallmicro.txt
	local output=$outputPath/fuzz.$cleanedURL.onelist.output.json
	local method="GET"
	
	# Check if a different default wordlist should be used
	if [ "$#" -gt 4 ]; then
		if [ "$5" -eq 1 ]; then
			local wordlist=/opt/tools/s2s_tools/resources/raft-medium-directories-lowercase.txt
			local output=$outputPath/fuzz.$cleanedURL.raft-directory.output.json
		elif [ "$5" -eq 2 ]; then
			local wordlist=/opt/tools/s2s_tools/resources/api_wordlist.txt
			local output=$outputPath/fuzz.$cleanedURL.raft-directory.output.json
			local method="POST,GET"
		fi
	fi

	local wordCount=0
	
	if [ "$#" -gt 5 ]; then
		local wordCount=$6
	fi

	if [ "$#" -gt 6 ]; then
		local wordlist=$7
		local wordlist_name=$(getFilename $wordlist)
		local output=$outputPath/fuzz.$cleanedURL.$wordlist_name.output.json
	fi
	
	if [ "$#" -gt 7 ]; then
		local method=$8
	fi

	if [[ ! "$wordCount" -eq 0 ]]; then
		ffuf $commonOptions -fw $wordCount -w $wordlist -u $url/FUZZ -o $output -of json -X $method -fc $errorCodes
		
	else
		ffuf $commonOptions -w $wordlist -u $url/FUZZ -o $output -of json -X $method -fc $errorCodes
	fi
	cat $output | jq .results | jq -c '.[]' | tee $output > /dev/null
	sendToELK $output fuzz

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="

}

#============================================================================
# Performs a directory enumeration (brute force - forced browsing) using 
# a default wordlist and the gobuster tool.
#
# Usage:
#	ferox project URL
# 
# Additional parameters:
#
#	ferox project URL [recurse] [errorCodes] [defaultLists] [words] [wordlist] [method]
#            $1    $2    $3          $4           $5           $6      $7         $8
#
#	[recurse] 		Boolean		Recursion for every found item
#	[errorCodes]	String		List of comma separated error codes which should be filtered
# 	[defaultLists]  Integer		Switching between default list 
#									0 ... onelistforallmicro
#									1 ... raft-medium-directories-lowercase
# 	[words]			Integer		Comma separated list of Word counts which should be filtered
#	[wordlist]		String		Manually specified word list.
#	[method]		String		Comma separated list of methods to be used. E.g.: POST,DELETE,GET. Default GET is used
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
	local cleanedURL=$(cleanURLKeepHTTPAndHTTPS $url)
	local outputPath=$defaultPath/host
	mkdir -p $outputPath
	
	local commonOptions="--auto-tune -A -k -f -n"
	local trueValue="true"
	local compare="$3"
	
	if [[ "$#" -gt 2 && "${compare,,}" == "${trueValue,,}" ]]; then
		local commonOptions="--auto-tune -A -k -f"
	fi
	
	local errorCodes=301,302,400,404,503
	
	if [ "$#" -gt 3 ]; then
		if [ ! "$4" -eq 0 ]; then
			local errorCodes=$errorCodes,$4
		fi
	fi	
	
	local wordlist=/opt/tools/s2s_tools/resources/onelistforallmicro.txt
	local output=$outputPath/ferox.$cleanedURL.onelist.output.json
	local method="GET"
	
	# Check if a different default wordlist should be used
	if [ "$#" -gt 4 ]; then
		if [ "$5" -eq 1 ]; then
			local wordlist=/opt/tools/s2s_tools/resources/raft-medium-directories-lowercase.txt
			local output=$outputPath/ferox.$cleanedURL.raft-directory.output.json
		elif [ "$5" -eq 2 ]; then
			local wordlist=/opt/tools/s2s_tools/resources/api_wordlist.txt
			local output=$outputPath/ferox.$cleanedURL.api_wordlist.output.json
			local method="POST,GET"
		fi
	fi
	
	local wordCount=0
	
	if [ "$#" -gt 5 ]; then
		local wordCount=$6
	fi

	if [ "$#" -gt 6 ]; then
		local wordlist=$7
		local wordlist_name=$(getFilename $wordlist)
		local output=$outputPath/ferox.$cleanedURL.$wordlist_name.output.json
	fi
	
	if [ "$#" -gt 7 ]; then
		local method=$8
	fi
		
	if [[ ! "$wordCount" -eq 0 ]]; then
		feroxbuster $commonOptions -C $errorCodes -u $url --json -o $output -w $wordlist -W $wordCount -m $method
	else
		feroxbuster $commonOptions -C $errorCodes -u $url --json -o $output -w $wordlist -m $method
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
	
	
	local responseCodeFilter="301,302,400,404,503"
	local wildcard=0

	if [ "$#" -gt 2 ]; then
		if [[ "$3" == "--wildcard" ]]; then
			((wildcard=1))
		else
			responseCodeFilter+=",$3"
		fi
	fi
	
	local wordlist=/opt/tools/s2s_tools/resources/onelistforallmicro.txt
	
	if [ "$#" -gt 3 ]; then
		if [ "$4" -eq 1 ]; then
			local wordlist=/opt/tools/s2s_tools/resources/raft-medium-directories-lowercase.txt
			local output=$outputPath/ferox.$cleanedURL.raft-directory.output.json
		elif [ "$4" -eq 2 ]; then
			local wordlist=/opt/tools/s2s_tools/resources/api_wordlist.txt
			local output=$outputPath/ferox.$cleanedURL.raft-directory.output.json
		else 
			if [ "$#" -gt 4 ]; then
				local wordlist=$5
				local wordlist_name=$(getFilename $wordlist)
				local output=$outputPath/ffuf.$cleanedURL.$wordlist_name.output.json
			fi
		fi
	fi


	ffuf -fc $responseCodeFilter -w $wordlist -u $url/FUZZ -o $output -of json

	sendToELK $output ffuf
	
	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="
}
