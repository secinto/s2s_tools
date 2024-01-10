#!/bin/bash

#============================================================================
# Resolves the provided hostname to an ip address explicitly. 
#
# Used tools:
# source{1}: https://github.com/wpscanteam/wpscan
# install{1}:{}
#============================================================================
function findIPAddressesForHosts() {
	initialize "$@"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} started"
	echo "==========================================================================="

	local dnsserver="8.8.8.8"
		
	local input=$defaultPath/domains.txt
	local output=$defaultPath/ips.$project.result.json
	local query_type="A"
	
	if [ -s "$input" ]; then
		echo "Required input $input already exists!"
	else
		echo "Required input $input doesn't exist!"
		subf "$@"
	fi
	
	exec 3<$input
	local jsonStart='{"resolvedHosts":['
	local jsonEnd=']}'
	local json=""

	while read line <&3
	do
		local ipContent="$(host -t ${query_type} ${line} ${dnsserver}| awk '/has.*address/{print $NF}')"
		if [ -n "${ipContent}" ]; then
			json+='{"'"host"'": "'"${line}"'","'"ips"'":[' 
			local jsonIPContent="$(echo "${ipContent}" | while read line; do echo '"'"${line}"'",'; done)"
			jsonIPContent="${jsonIPContent::-1}"
			json+="${jsonIPContent}]},"
		fi
	done
	#Remove last comma.
	local cleanedJson="${json::-1}"
	#echo "Cleaned JSON ${cleanedJson}"
	echo "$jsonStart" "$cleanedJson" "$jsonEnd" | jq '.' | tee $output

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="

}

#============================================================================
# Obtains additional information to each identified IP address using IPinfo
#============================================================================
function getIPInfo() {
	initialize "$@"
	local input=$reconPath/dpux.txt
	local result=$reconPath/dpux_ipinfo.json
		
	if [ -s "$input" ]; then

		local now="$(date +'%d/%m/%Y-%::z')"
	
		echo "============================================================================"
		echo "Obtaining additional IP address information for $project"
		echo "Current time: $now"
		echo "============================================================================"	
		
		if [ -n "${S2S_IPINFO_TOKEN+set}" ]; then
			if [ $# -lt 2 ]; then
			
				exec 3<$input
				local json=""

				while read line <&3
				do
					local url="https://ipinfo.io/$line/json?token=$S2S_IPINFO_TOKEN"
					echo "$url"
					local ipContent="$(curl -s "$url")"
					if [ -n "${ipContent}" ]; then
						json+="${ipContent}"
					fi
				done

				echo "$json" | jq '.' | tee $result
			fi
		else
			echo "S2S_IPINFO_TOKEN environment variable not set"
		fi
	else
		echo "Not performing ${FUNCNAME[0]} since it has been performed recently."
	fi

	

	local now="$(date +'%d/%m/%Y-%::z')"
	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="	
}

#============================================================================
# Filtering obtained IPs. Currently only IPs used for Ofice 365 signaling (
# are excluded autodiscover, sip, ...).
#============================================================================
function filterIPs() {


	local input=$reconPath/dpux.txt
	local output=$reconPath/dpux_clean.txt

	echo "Filtering obtained IPs to exclude IPs used for office 365 signaling (autodiscover, sip, ...)"

	local ipsToRemove="$(mapcidr -silent -cl /opt/tools/s2s_tools/resources/microsoft_ips.txt -mi $input)"
	cat $input | tee $output > /dev/null
	if [ ! -z "$ipsToRemove" ]; then
		while read -r line
		do
			sed -i "/$line/d" "$output"
		done <<< "$ipsToRemove"
	else
		echo "No IP addresses are set to be removed"
	fi
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

