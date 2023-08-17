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
function getIPInfoAndCleanDPUx() {
	initialize "$@"
	local input=$reconPath/dpux.txt
	local result=$reconPath/dpux_ipinfo.json
	local hostIP=$reconPath/dpux_host_to_ip.json
	local removedIPs=$reconPath/dpux_removed_ips.txt
	local cleanedInput=$reconPath/dpux_clean.txt
	
	if [ -f "$removedIPs" ]; then
		rm $removedIPs
	fi
		
	if [ -s "$input" ]; then

		local now="$(date +'%d/%m/%Y-%::z')"
	
		echo "============================================================================"
		echo "Obtaining additional IP address information for $project"
		echo "Current time: $now"
		echo "============================================================================"	
		
		if [ -s "$input" ]; then
			echo "Required input $input already exists!"
		else
			echo "Required input $input doesn't exist!"
			dpux "$@"
		fi
		
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
			
			#local ipsToRemove="$(cat $result | jq -r 'select(.org != null) | select(.org | contains("Microsoft")) | .ip')"
			cat $hostIP | grep autodiscover. | jq .ip | sed 's/\"//g' | anew $removedIPs
			cat $hostIP | grep lyncdiscover. | jq .ip | sed 's/\"//g' | anew $removedIPs
			cat $hostIP | grep sip. | jq .ip | sed 's/\"//g' | anew $removedIPs
			cat $hostIP | grep enterpriseenrollment. | jq .ip | sed 's/\"//g' | anew $removedIPs

			local ipsToRemove="$(cat $removedIPs)"
			
			echo "============================================================================"
			echo "IP addresses which will be removed from dpux.txt"
			echo "============================================================================"	
			echo "$ipsToRemove"
			echo "============================================================================"
			cat $input | tee $cleanedInput > /dev/null
			if [ ! -z "$ipsToRemove" ]; then
			
				while read -r line
				do
					sed -i "/$line/d" "$cleanedInput"
				done <<< "$ipsToRemove"
			else
				echo "No IP addresses are set to be removed"
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
