#!/bin/bash

#============================================================================
# Cleans the provided URL in order to be used within the file system.
# It replaces the characters 'http{s}://', with '' and '/','#','?' and '&' 
# with '_'. 
#============================================================================
function cleanURL() {
	local input="$1"
	local cleaned_url="$(echo $input | sed 's/:/_/g' | sed 's/\//_/g' | sed 's/\#/_/g' | sed 's/\?/_/g' | sed 's/\&/_/g' | sed 's/\\/_/g')"
    echo $cleaned_url
}
#============================================================================
# Cleans the provided URL in order to be used within the file system.
# It replaces the characters 'http{s}://', with 'http{s}_' and '/','#','?'
# and '&' with '_'. 
#============================================================================
function cleanURLKeepHTTPAndHTTPS() {
	local input="$1"
	local cleaned_url="$(echo $input | sed 's/https:\/\//https_/g' | sed 's/http:\/\//http_/g' | sed 's/\//_/g' | sed 's/\#/_/g' | sed 's/\?/_/g' | sed 's/\&/_/g')"
    echo $cleaned_url
}
#============================================================================
# Cleans the provided IP address in order to be used within the file system.
# It replaces the characters '.', '/' and  with '_'. 
# E.g. 192.168.1.2/24 will become 192_168_1_2_24.
#============================================================================
function cleanIP() {
	local input=$1
	local cleaned_ip="$(echo "$input" | sed 's/\./_/g' | sed 's/\//-/g')"
	echo $cleaned_ip
}

#============================================================================
# Changes the file extension of the provided file to the one specified.
#============================================================================
function changeFileExtension() {
	local input=$1
	local fileExtension=$2
	local changedFileExtension="$(getFilenameWithoutExtension $input | awk -v var="$fileExtension" '{print $1"."var}')"
	echo $changedFileExtension
}

#============================================================================
# Returns the filename without the extension
#============================================================================
function getFilenameWithoutExtension() {
	local input=$1
	local fileWithoutExtension="$(echo $input | sed 's/\.[^.]*$//')"
	echo $fileWithoutExtension
}

#============================================================================
# Returns only the filename without the path
#============================================================================
function getFilename() {
	local input=$1
	local filename="$(echo $input | awk -F"/" '{print $NF}')"
	echo $filename
}

#============================================================================
# Returns the file extension
#============================================================================
function getFileExtension() {
	local input=$1
	local fileExtension="$(echo $input | awk -F"." '{print $NF}')"
	echo $fileExtension
}

#============================================================================
# Checks if an IP address is contained in the local files
#============================================================================
function findIPAddressInFiles() {
	grep -h -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' * | sort | uniq -c | sort -nr 
}

#============================================================================
# Removes all whitespaces (except carriage return and line feed)  
# from the input.
#============================================================================
function removeWhitespaces() {
	local removedWhitespaces="$(echo "$1" | sed 's/\ //g' | sed 's/[[:blank:]]//g' | sed 's/[[:space:]]//g' | sed '/^$/d')"
	echo $removedWhitespaces
}

#============================================================================
# Removes JSON or other format characters such as [ ] " , null
#============================================================================
function removeEnclosingTags() {
	local removedTags="$(echo "$1" | sed 's/\[//g' | sed 's/\]//g' | sed 's/\"//g' | sed 's/null//g' | sed 's/,//g')"
	echo $removedTags
}

#============================================================================
# Removes all notations of localhost from the input
#============================================================================
function removeLocalhost() {
	local removedLocalhost="$(echo "$input" | sed 's/127.0.0.1//g' | sed 's/127::1//g' | sed 's/::1//g' | sed 's/127.000.000.001//g' | sed 's/localhost//g')"
	echo $removedLocalhost
}
#============================================================================
# Sends the specified file to elasticsearch for storage and indexing. 
# The project is added within the fields as data and stored at an index 
# depending on the type of tool used.
#============================================================================
function sendToELK() {
	echo "============================================================================"
	echo "Sending $1 to be stored in ELK."
	echo "============================================================================"
	#cat $1 | nc -q0 localhost 50000
	if [ "$#" -eq 2 ]; then
		elasticPusher -f $1 -i s2s_bash_$2 -p $project -t json
	elif [ "$#" -eq 3 ]; then
		elasticPusher -f $1 -i s2s_bash_$2 -p $project -t $3
	elif [ "$#" -eq 4 ]; then
		elasticPusher -f $1 -i s2s_bash_$2 -p $project -t $3 -h $4
	else
		elasticPusher -f $1 -i s2s_bash_$2 -p $project
	fi
}

#============================================================================
# Generates host mappings using the output of NMAP and the resolved hostnames.
#============================================================================
function generateHostMappings() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	echo "============================================================================"
	echo "Generating host mappings for $project"
	echo "============================================================================"
	
	nmapParser -p $project -a -hd
}

#============================================================================
# Removes the duplicates from domain enumeration and creates a domains_clean 
# file for further processing.
#============================================================================
function removeDuplicate() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	echo "============================================================================"
	echo "Removing duplicates for project $project"
	echo "============================================================================"
	
	cleanAndFind -p $project
}

#============================================================================
# Analyzes the HTTPx JSON output to identify possible interesting hosts and
# issues within them.
#============================================================================
function getFindings() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	echo "============================================================================"
	echo "Get findings for $project"
	echo "============================================================================"
	
	simpleFinder -p $project 
}

#============================================================================
# Analyzes the stored responses, including request and the whole chain, 
# obtained by HTTPx. The output is written to the findings folder. 
#============================================================================
function analyzeResponses() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	echo "============================================================================"
	echo "Get findings for $project"
	echo "============================================================================"
	
	analyzeResponses -p $project 
}

#============================================================================
# Changes the ownership of all created files to user:researchers in order
# to be accessible for all users in the researchers group
#============================================================================
function changeOwnership() {
	local user=$(whoami)
	#sudo chmod -R 666 $defaultPath/*
	sudo chown -R $user:researchers $defaultPath 
	sudo find $defaultPath -type f -exec chmod 664 {} \;
}

#============================================================================
# Delete all files with zero size in all sub folders of the current project
#============================================================================
function cleanZeroFiles() {

	find $defaultPath -type f -empty -print -delete 2> /dev/null
	find $workPath -type f -empty -print -delete 2> /dev/null
	find $reconPath -type f -empty -print -delete 2> /dev/null
	find $responsePath -type f -empty -print -delete 2> /dev/null
	#find $brutePath -type f -empty -print -delete 2> /dev/null
}

#============================================================================
# Sends the specified data type (httpx, dpux, subf, ports) from all folders 
# to elastic for storage and indexing.
#============================================================================
function sendAllToELK {
	echo "==========================================================================="
	echo "Starting recon for all existing projects"
	echo "==========================================================================="

	local dirList="$(find /opt/s2s/. -mindepth 1 -maxdepth 1 -type d -printf '%f\n')"
	local lineCounter=1
	for d in $dirList ; do
		
		local folder=$(basename $d)

		initialize "$folder"

		sendToELK $reconPath/http_from.$project.output.json httpx
		sendToELK $reconPath/dpux.$project.output.json dpux
		sendToELK $reconPath/subf.$project.output.json subf
		sendToELK $reconPath/ports.$project.output.json ports
		lineCounter=$((lineCounter+1))
	done

	echo "==========================================================================="
	echo "Transfered data for $lineCounter projects"
	echo "==========================================================================="

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Sends all responses from the specified project to ELK
#============================================================================
function saveResponses {

	local type=$1
		
	echo "==========================================================================="
	echo "Sending responses for project $project"
	echo "==========================================================================="
		
	local responseDirList="$(find $responsePath/$type/response/. -mindepth 1 -maxdepth 1 -type d -printf '%f\n')"

	for dir in $responseDirList ; do
		local host=$(basename $dir)
		local completeDir=$responsePath/$type/response/$dir
		local files="$(find $completeDir/ -mindepth 1 -maxdepth 1 ! -name '*chain*' -type f -printf '%f\n')"
		for entry in $files ; do
			local file="$completeDir/$entry"
			sendToELK $file responses raw $host
		done
	done

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}


#============================================================================
# Sends all responses from all projects to ELK
#============================================================================
function saveAllResponses {
	echo "==========================================================================="
	echo "Starting recon for all existing projects"
	echo "==========================================================================="

	local dirList="$(find /opt/s2s/. -mindepth 1 -maxdepth 1 -type d -printf '%f\n')"
	for d in $dirList ; do
		
		local folder=$(basename $d)
		initialize "$folder"
		
		local responseDirList="$(find $responsePath/. -mindepth 1 -maxdepth 1 -type d -printf '%f\n')"

		for dir in $responseDirList ; do
			local host=$(basename $dir)
			local completeDir=$responsePath/$dir
			local files="$(find $completeDir/ -mindepth 1 -maxdepth 1 -type f -printf '%f\n')"
			for entry in $files ; do
				local file="$completeDir/$entry"
				sendToELK $file responses raw $host
			done
		done
	done

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Sends the specified data type (httpx, dpux, subf, ports) from all folders 
# to elastic for storage and indexing.
#============================================================================
function commandToALL {
	echo "==========================================================================="
	echo "Starting recon for all existing projects"
	echo "==========================================================================="
	local command=$1
	local dirList="$(find /opt/s2s/. -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -R --random-source=/dev/urandom)"
	local lineCounter=1
	for d in $dirList ; do
		local folder=$(basename $d)
		
		initialize "$folder"
		
		if [ $command == "tech" ]; then
			web_tech_all $folder
		elif [ $command == "subf" ]; then
			subf $folder "${@:2}"
		elif [ $command == "httpx" ]; then
			http_from_all $folder
		elif [ $command == "dpux" ]; then
			dpux $folder "${@:2}"
		elif [ $command == "ports" ]; then
			ports $folder "${@:2}"
		fi
		lineCounter=$((lineCounter+1))
	done

	echo "==========================================================================="
	echo "Transfered data for $lineCounter projects"
	echo "==========================================================================="

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

function checkFile() {
	local fileToCheck=$1
	
	if [[ -f "$fileToCheck" && $(find "$fileToCheck" -mmin +3600 -print) ]]; then
		true
	elif [[ ! -f "$fileToCheck" ]]; then
		true
	else
		false
	fi
}
#============================================================================
# Checks if a specific file is at least older than a day and if yes archives 
# the file and returns true. Otherwise, nothing is done and false is returned.
#============================================================================
function checkAndArchive() {
	local fileToCheck=$1
	
	if [[ -s "$fileToCheck" && $(find "$fileToCheck" -mmin +720 -print) ]]; then
		if [ "$#" -eq 2 ]; then
			local archiveDirectory=$2
			mkdir -p $archiveDirectory
		else
			local archiveDirectory=$archivePath
		fi
		
		local filename=$(basename $fileToCheck)
		
		local fileExtension="$(getFileExtension $filename)"
		local fileWithout="$(getFilenameWithoutExtension $filename)"
		local currentTime="$(date "+%Y.%m.%d-%H.%M.%S")"
		local archiveFile=$fileWithout.$currentTime.$fileExtension
		local fullPath=$archiveDirectory/$archiveFile
		cp $fileToCheck $fullPath
		echo "============================================================================"
		echo "$fileToCheck" 
		echo "has been archived as "
		echo "$fullPath"
		echo "============================================================================"
		
		true
	elif [[ ! -s "$fileToCheck" ]]; then
		true
	else
		false
	fi
	
}

function getTimeForFile() {
	local currentTime="$(date "+%Y.%m.%d-%H.%M.%S")"
	echo $currentTime
}

#============================================================================
# Removes the net portion of the IP and sets the last octet of the IPv4 
# address to '0'
#============================================================================
function makeIPCIDRReady() {
	# Removes the net portion of the IP and sets the last octet of the IPv4 address to '0'
	local cidrReadyIP="$(echo "$1" | sed 's/\/.*//g' | sed '/[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/s/\.[0-9]\+$/.0/')"
	echo $cidrReadyIP
}

#============================================================================
# Sorts the provided list of IPs in ascedending order
#============================================================================
function sortIPs() {
	local input=$1
	
	local output="$(getFilenameWithoutExtension $input)-sorted.txt"
	sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n $input | tee $output
}

#============================================================================
# Checks if the provided parameter is of type integer
#============================================================================
function checkIfNumber() {
	local paramToCheck=$1
	
	re='^[0-9]+$'
	if ! [[ $paramToCheck =~ $re ]] ; then
		false
	else
		true
	fi
}
#============================================================================
# Creates a JSON list from the provided input file which is expected to be a 
# plain text file. Each line will be one entry in the specified output JSON 
# and the provided name will be the key.
#
# Note: This function only works if the file is not big. Because it uses an
# argument list as input for JQ, which seems to have a limit.
#
# e.g. createJSONFromShortFile infileName outfileName keyname
# { "keyname" : [ "line1", 
#				"line2",
#				...
#				"lineN"
#				]
# }
# 
#============================================================================
createJSONFromShortFile() {
	if [ "$#" -lt 2 ]; then
		echo "The required input params (in/out) file not provided"
		#exit 1
	elif [ "$#" -lt 3 ]; then
		local keyword="values"
		echo "No main key for the JSON output specified. Using $keyword"
		#exit 1
	else
		local input=$1
		local output=$2
		local keyword=$3
	fi

	echo "============================================================================"
	echo "Creating JSON output $output "
	echo "from provided input file $input  "
	echo "using $keyword as key name"
	echo "============================================================================"

	if [ -s "$input" ]; then
		local list="$(cat $input)"
		echo "Using lines from the file separately as input for JSON conversion."
		jq -n --arg inarr "$list" '{ '"$keyword"': $inarr | split("\n") }' | tee $output
	else	
		echo "Provided input $input does not exist"
	fi
}

#============================================================================
# Creates a JSON list from the provided input file which is expected to be a 
# plain text file. Each line will be one entry in the specified output JSON 
# and the provided name will be the key.
# e.g. createJSONFromBigFile infileName outfileName keyname
# { "keyname" : [ "line1", 
#				"line2",
#				...
#				"lineN"
#				]
# }
# 
#============================================================================
function createJSONFromBigFile() {
	if [ "$#" -lt 2 ]; then
		echo "The required input params (in/out) file not provided"
		#exit 1
	elif [ "$#" -lt 3 ]; then
		local keyword="values"
		echo "No main key for the JSON output specified. Using $keyword"
		#exit 1
	else
		local input=$1
		local output=$2
		local keyword=$3
	fi

	echo "============================================================================"
	echo "Creating JSON output $output "
	echo "from provided input file $input  "
	echo "using $keyword as key name"
	echo "============================================================================"

	if [ -s "$input" ]; then
		echo "Directly using file input for JSON converions."
		local json="$(cat "$input" | jq --raw-input --slurp 'split("\n") | map(select(. != ""))')"
		local jsonStart='{"'"$keyword"'":'
		local jsonEnd='}'
		echo "$jsonStart" "$json" "$jsonEnd" | tee $output
	else	
		echo "Provided input $input does not exist"
	fi
}

#============================================================================
# Creates a JSON file from the provided CSV file. Each column (CSV separated
# entry) is provided as value for an associated key element. Each line is one
# specific element in the resulting JSON. The main key and the column keys 
# "must" be specified in the input. The amount of specified keys must be the
# same as distinct entries in the CSV.
#
# e.g.: createJSONFromSeparatedValues <input> <output> <separator> <skip-first> 
#				<main-key> <column1-key> ... <columnN-key>
#============================================================================
function createJSONFromSeparatedValues(){
	if [ "$#" -eq 0 ]; then
	  myArray=( temp )
	else
	  myArray=( "$@" )
	fi
	local input=${myArray[0]}
	local output=${myArray[1]}
	local separator=${myArray[2]}
	#echo $input
	if [ -s "$input" ]; then
		echo "Required input $input exists!"

		exec 3<$input
		local jsonStart='{"'"${myArray[4]}"'":['
		local jsonEnd=']}'
		local json=""
		local lineCounter=0
		
		while read line <&3
		do	
				if [[ $lineCounter == 0 && "${myArray[3]}" == "true" ]]; then
					lineCounter=$((lineCounter+1))
					continue
				fi
				#Read line and assign the elements separated by comma to an array.
				IFS=$separator read -r -a array < <(printf '%s\n' "$line")
				#Get the length of the array
				local length=${#array[@]}
				json+="{"
				local counter=0
				while [  $counter -lt $length ]; do
					local key=${myArray[$counter+5]}
					local value=${array[$counter]}

					if [[ ${value: -1} == $'\r' ]]; then
						value="${value::-1}"
					fi

					json+='"'"$key"'":"'"$value"'",'
					counter=$((counter+1))
				done
				json="${json::-1}"
				json+='},'
				# Increase line counter
				lineCounter=$((lineCounter+1))
		done 
		local cleanedJson="${json::-1}"
		echo "============================================================================"
		echo "Creating final JSON output "
		echo "============================================================================"
		
		echo "$jsonStart" "$cleanedJson" "$jsonEnd" | jq '.' | tee $output
	else
		echo "Required input ${myArray[0]} doesn't exist! Not creating an JSON output."
	fi
}

#============================================================================
# Creates from the provided input JSON (line JSON as from projectDiscovery) a
# valid JSON using the lines as entries in an JSON array. The object keyword 
# can be specified or if not is set to "values".
#
# e.g.: createJSONFromJSONLineFile <input> <output> <values> 
#============================================================================
function createJSONFromJSONLineFile() {
	
	if [ "$#" -lt 2 ]; then
		echo "The required input params (in/out) file not provided"
	elif [ "$#" -lt 3 ]; then
		local keyword="values"
		echo "No main key for the JSON output specified. Using $keyword"
	else
		local input=$1
		local output=$2
		local keyword=$3
	fi
	
	if [ -s "$input" ]; then
		exec 3<$input

		local json_start='{"'"$keyword"'":['
		local json_end=']}'
		local json=""
		while read line <&3
		do
				json+="$line," 
		done 
		local json_content="${json::-1}"
		echo "$json_start" "$json_content" "$json_end" | jq '.' | tee $output
	fi
}


#============================================================================
# Converts all XML files from the NMAP directory of current project to HTML
#============================================================================
function convert_xml_to_html() {

	initialize "$@"
	
	local inputFolder=$defaultPath/nmap
	
	cd $inputFolder
	
	shopt -s nullglob
	for i in *.xml; do
		local filename="$(getFilenameWithoutExtension $i)"
		if [ ! -s "$filename.html" ]; then
			echo "Converting file $i"
			#local filename="$(getFilenameWithoutExtension $i)"
			#xmlstarlet edit --update "/?xml-stylesheet/@href" -v ="file:///usr/bin/../share/nmap/nmap.xsl" $i
			sed -i 's/file:\/\/\/C:\/Program Files (x86)\/Nmap\/nmap\.xsl/file:\/\/\/usr\/bin\/\.\.\/share\/nmap\/nmap\.xsl/g' $i
			xsltproc "$i" -o "$filename.html"
		fi
	done
	
	cd ~

	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="

}

#============================================================================
# Prints the externally visible IP used from this host
#============================================================================
function myip() {
	dig @resolver4.opendns.com myip.opendns.com +short
}

#============================================================================
# Prints all IP addresses fetched from the xml files at the given directory
#
# source{1}:https://github.com/laconicwolf/Nmap-Scan-to-CSV
# install{1}:{git clone https://github.com/laconicwolf/Nmap-Scan-to-CSV.git}
#============================================================================
function getIPListFromAllXML() {
	local script=/opt/tools/nmapXMLParser/nmapXMLParser.py
	local directory=$1
	if [ "${directory: -1}" == "/" ]; then 
		directory=${directory::-1}
	fi

	local files=$(ls $directory/*.xml)
	python3 script -ip -f $files | anew | sort -u
}

#============================================================================
# Gets the open ports for the specified host from the output of the complete
# NMAP scan over all hosts (DPUX). The input (dpux.xml) is parsed and the 
# open ports are returned comma separated, thus can again be used as input
# for a NMAP scan to identify the services or perform scripts only on the 
# open ports.
#
# source{1}:https://github.com/laconicwolf/Nmap-Scan-to-CSV
# install{1}:{git clone https://github.com/laconicwolf/Nmap-Scan-to-CSV.git}
#============================================================================
function getOpenPortsForHost() {
	local script=/opt/tools/nmapXMLParser/nmapXMLParser.py
	local input=$reconPath/ports.$project.output.xml
	local host=$1
	local type=$2
	

	if [ $# -eq 3 ]; then
		local input=$3
	fi	
	
	if [ -s $input ]; then
	
		python3 $script -p -f $input | grep $host | grep $type | awk '{ print $5 }' | sed -z 's/\n/,/g;s/,$/\n/'
		
	fi
}

#============================================================================
# Converts the services found via the complete NMAP scan over all identified
# hosts (DPUX) from XML to JSON. Each IP address and port combintation 
# is represented by one entry in JSONL format. The keys are IP, protocol, port
# and service type.
#
# source{1}:https://github.com/secinto/nmapXMLParser
# install{1}:{git clone https://github.com/secinto/nmapXMLParser}
#============================================================================
function createServicesJSON() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local script=/opt/tools/nmapXMLParser/nmapXMLParser.py
	local input=$reconPath/ports.$project.output.xml
	
	local fullScan=false

	local output=$defaultPath/findings/services.json

	
	if [ $# -eq 2 ]; then
		local input=$defaultPath/nmap/dpux_clean.xml
		local fullScan=true
		local output=$defaultPath/findings/services_full.json
		echo "Using info from full scan for services.json"
	fi		

	if [ -s $input ]; then
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} for generating services.json started"
		echo "Current time: $now"
		echo "==========================================================================="

		python3 $script -p -f $input | awk '{print "{\"ip\": \"" $1 "\", \"protocol\": \"" $4 "\", \"port\": \"" $5 "\", \"service\": \"" $6 "\"}"}' | tee $output.jsonl &> /dev/null
		
		if $fullScan; then
			cat $output.jsonl | anew $defaultPath/findings/services.json.jsonl 
			cat $defaultPath/findings/services.json.jsonl | jq -s '.' | tee $defaultPath/findings/services.json 
		fi
		cat $output.jsonl | jq -s '.' | tee $output 
		

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="
	fi
}

