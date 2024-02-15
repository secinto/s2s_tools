#!/bin/bash

#*****************************************************************************
# 				Additional Recon Tools
#*****************************************************************************


#============================================================================
# Fetch the HTML body and header of the provided list of URLs or URL.
#
# Used tools:
# source{1}:
# install{1}:{}
#============================================================================
hakcrawl() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$reconPath/http_servers_all.txt
	local output=$reconPath/$FUNCNAME.$project.result.txt
	local result=$reconPath/$FUNCNAME.$project.result.json

	checkAndArchive $output
	checkAndArchive $result

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "==========================================================================="
	echo "Crawling websites for $project using hakrawler "
	echo "Current time: $now"
	echo "==========================================================================="

	if [[ "$#" -eq 1 && ! -f "$input" ]]; then
		http_from_ips "$@"
		http_from_domains "$@"
	fi
	
	if [ -s "$input" ]; then
		cat $input | hakrawler -t 20 -u -insecure | sort -u | anew $output
	else
		echo "Required input $input not available."
	fi
	
	createJSONFromBigFile $output $result "foundLinks" true

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"	

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="

}


#============================================================================
# Obtains all the known URLs using "gau" for the provided list of available
# subdomains which have been collected using all_domains().
#
# Used tools:
# source{1}:https://github.com/lc/gau
# install{1}:{GO111MODULE=on go get -u -v github.com/lc/gau}
# source{2}:https://github.com/stedolan/jq
# install{2}:{sudo apt install jq}
#============================================================================
gau_domain() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$defaultPath/domains_clean.txt
	local output=$reconPath/gau.txt
	local outputJSON=$reconPath/$FUNCNAME.$project.output.json
	#local outputTxt=$defaultPath/$FUNCNAME.$project.output.txt
	local result=$reconPath/$FUNCNAME.$project.result.json

	if [ -s "$input" ]; then
		echo "Required input $input already exists!"
	else
		echo "Required input $input doesn't exist!"
		subf "$@"
	fi
	
	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "============================================================================"
	echo "Getting all known URLS via gau for project $1"
	echo "Current time: $now"
	echo "============================================================================"

	
	cat $input | gau --json --o $outputJSON --subs $project
	
	#cat $outputTxt | sed 's/\"url":"/\ /g' -e 's/{ //g' -e 's/"}//g' | unfurl -u domains | anew $input

	cat $outputJSON | jq .url | sed 's/\"//g' | sort -u | anew $output

	echo "==========================================================================="
	echo "Plain text output $outputText created. Converting to result file"
	echo "==========================================================================="

	createJSONFromJSONLineFile $outputJSON $result "archivedUrls"


	local now="$(date +'%d/%m/%Y-%k:%M:%S')"
	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Obtains all the known URLs using "waybackurls" for the provided list of 
# available subdomains which have been collected using all_domains().
#
# Used tools:
# source{1}:https://github.com/tomnomnom/waybackurls
# install{1}:{go get github.com/tomnomnom/waybackurls}
# source{2}:https://github.com/tomnomnom/anew
# install{2}:{go get -u github.com/tomnomnom/anew}
#============================================================================
wayback_domain() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$defaultPath/domains_clean.txt
	local output=$reconPath/wayback.txt
	local outputTXT=$reconPath/$FUNCNAME.$project.output.txt
	local result=$reconPath/$FUNCNAME.$project.result.json

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	if [ -s "$input" ]; then
		echo "Required input $input already exists"
	else
		echo "Required input $input doesn't exist!"
		subf "$@"
	fi

	echo "============================================================================"
	echo "Getting all known URLS via waybackurls for project $1"
	echo "Current time: $now"
	echo "============================================================================"

	waybackurls $project | sort -u | tee $outputTXT 
	
	cat $outputTXT | anew $output > $output.new
	
	cat $outputTXT | unfurl -u domains | anew $input

	echo "==========================================================================="
	echo "Plain text output $outputTXT created. Converting to result file"
	echo "==========================================================================="

	createJSONFromBigFile $outputTXT $result "archivedUrls"

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"
	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="

}


#============================================================================
# Spiders (crawls) the provided URL, tries to fill out forms and obtains 
# endpoints from within the obtained files. It uses a headleass browser 
# (chrome) as the results are better. Then feeds the found endpoints into
# HTTPx which sends a GET and POST request to it and stores all the responses
# obtained in the project responses folder. 
#
# Used tools:
# source{1}:https://github.com/projectdiscovery/katana
# install{1}:{go install github.com/projectdiscovery/katana/cmd/katana@latest}
# source{2}:https://github.com/projectdiscovery/httpx
# install{2}:{go install github.com/projectdiscovery/httpx/cmd/httpx@latest}
#============================================================================
function spiderContentAndStore {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$defaultPath/recon/http_servers_clean.txt
	local katanaOztput=$reconPath/katana
	#Create details direcotry for storing all the explicit outputs from katana and httpx
	local detailsPath=$reconPath/details
	rm -rf $detailsPath
	mkdir -p $detailsPath
	local responseDir=$responsePath/details
	rm -rf $responseDir
	mkdir -p $responseDir
	if [ -s "$input" ]; then
		for line in $(<$input); 
		do 
			local cleanFile="$(cleanURLKeepHTTPAndHTTPS $line)"
			local katanaOutput=$detailsPath/katana.$cleanFile.txt
			local httpxOutput=$detailsPath/httpx.$cleanFile.json
			local domainName="$(getDomain $line)"
			echo $domainName
			katana -jc -kf all -aff -fs fqdn -iqp -ef css,svg,jpg,gif,pdf,mp4,ttf,woff,woff2,eot -mdc -ct 180 -silent -o -u $line | anew $katanaOutput
			if [ -s "$katanaOutput" ]; then
				httpx -l $katanaOutput -hash "mmh3" -random-agent=false -fc 404,401 -json -o $httpxOutput -srd $responseDir -duc -random-agent=false
			fi
		done
	else
		echo "Provided input $input is not a valid file."
	fi
}