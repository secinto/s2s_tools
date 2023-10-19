#!/bin/bash

#============================================================================
# Performs a full scan of the provided IP range over all 65k ports. An 
# aggressive timing (T5) is used. No additional discovery (sV, O, A, scripts) 
# is performed. Ports used for raw printing are excluded
#
# Used tools:
# source{1}:https://github.com/nmap/nmap
# install{1}:{sudo apt install nmap}
#============================================================================
nmap_ip_full() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	

	local ipRange=$2
	
	local withScript=false
	
	if [ "$#" -gt 2 ]; then
		withScript=true
	fi
	
	local cleanedIP=$(cleanIP $ipRange)
	mkdir -p $defaultPath/nmap
	local outputPath=$defaultPath/nmap/$cleanedIP

	local log=$outputPath.log
	touch $log

	
	if $withScript; then
		sudo nmap -vv -n -Pn -sV --script=default,vuln -sT -sU -p T:1-65535,U:7,9,17,19,49,53,67-69,80,88,111,120,123,135-139,158,161-162,177,427,443,445,497,500,514-515,518,520,593,623,626,631,996-999,1022-1023,1025-1030,1433-1434,1645-1646,1701,1718-1719,1812-1813,1900,2000,2048-2049,2222-2223,3283,3456,3703,4444,4500,5000,5060,5353,5632,9200,10000,17185,20031,30718,31337,32768-32769,32771,32815,33281,49152-49154,49156,49181-49182,49185-49186,49188,49190-49194,49200-49201,65024 -T3 -oX "$outputPath.xml" $ipRange --host-timeout 1800 
		#sudo nmap -Pn -vv -p- --exclude-ports 515,721,9100-9107,9112-9116 -oX "$outputPath.xml" $ipRange 
	else
		sudo nmap -vv -Pn -sT -sU -p T:1-65535,U:7,9,17,19,49,53,67-69,80,88,111,120,123,135-139,158,161-162,177,427,443,445,497,500,514-515,518,520,593,623,626,631,996-999,1022-1023,1025-1030,1433-1434,1645-1646,1701,1718-1719,1812-1813,1900,2000,2048-2049,2222-2223,3283,3456,3703,4444,4500,5000,5060,5353,5632,9200,10000,17185,20031,30718,31337,32768-32769,32771,32815,33281,49152-49154,49156,49181-49182,49185-49186,49188,49190-49194,49200-49201,65024 -T3 -oX "$outputPath.xml" $ipRange --host-timeout 1800 
		#sudo nmap -Pn -vv -p- --exclude-ports 515,721,9100-9107,9112-9116 -oX "$outputPath.xml" $ipRange 
	fi
	
	xsltproc $outputPath.xml -o $outputPath.html

	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="

}


#============================================================================
# Performs a full scan of the provided list of IPs over all 65k ports. An 
# aggressive timing (T5) and a minimum rate of 5000 ports per second are used.
#
# Used tools:
# source{1}:https://github.com/nmap/nmap
# install{1}:{sudo apt install nmap}
#============================================================================
nmap_list_full() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	

	local ipList=$2
	
	local withScript=false
	
	if [ "$#" -gt 2 ]; then
		withScript=true
	fi
	
	local outfile=$(getFilename $ipList)
	local outfile_noext=$(getFilenameWithoutExtension $outfile)

	mkdir -p $defaultPath/nmap
	local outputPath=$defaultPath/nmap/$outfile_noext

	local log=$outputPath.log

	touch $log
	
	if $withScript; then
		sudo nmap -vv -n -Pn -sV -sT -sU -p T:1-65535,U:7,9,17,19,49,53,67-69,80,88,111,120,123,135-139,158,161-162,177,427,443,445,497,500,514-515,518,520,593,623,626,631,996-999,1022-1023,1025-1030,1433-1434,1645-1646,1701,1718-1719,1812-1813,1900,2000,2048-2049,2222-2223,3283,3456,3703,4444,4500,5000,5060,5353,5632,9200,10000,17185,20031,30718,31337,32768-32769,32771,32815,33281,49152-49154,49156,49181-49182,49185-49186,49188,49190-49194,49200-49201,65024 -T4 -oX "$outputPath.xml" -iL $ipList --host-timeout 1800 > $log
	else
		sudo nmap -vv -Pn -sT -sU -p T:1-65535,U:7,9,17,19,49,53,67-69,80,88,111,120,123,135-139,158,161-162,177,427,443,445,497,500,514-515,518,520,593,623,626,631,996-999,1022-1023,1025-1030,1433-1434,1645-1646,1701,1718-1719,1812-1813,1900,2000,2048-2049,2222-2223,3283,3456,3703,4444,4500,5000,5060,5353,5632,9200,10000,17185,20031,30718,31337,32768-32769,32771,32815,33281,49152-49154,49156,49181-49182,49185-49186,49188,49190-49194,49200-49201,65024 -T4 -oX "$outputPath.xml" -iL $ipList | tee $log
	fi
	
	xsltproc $outputPath.xml -o $outputPath.html

	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="

}

#============================================================================
# Performs a fast scan of the provided IP range over 1000 ports. 
#
# Used tools:
# source{1}:https://github.com/nmap/nmap
# install{1}:{sudo apt install nmap}
#============================================================================
nmap_ip_fast() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	

	local ipRange=$2
	
	local cleanedIP=$(cleanIP $ipRange)
	mkdir -p $defaultPath/nmap
	local outputFile=$defaultPath/nmap/$cleanedIP-fast.xml
	local fileName="$(getFilenameWithoutExtension $outputFile)"

	local log=$defaultPath/nmap/$cleanedIP-fast.log

	sudo nmap -Pn -vv --exclude-ports 515,721,9100-9110 -oX $outputFile $ipRange
	
	xsltproc "$outputFile" -o "$fileName.html"

	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "==========================================================================="

}

#=============================================================================
# Discovers hosts in the provided CIDR range and filters them for alive hosts.
#=============================================================================
function scan_net_nmap() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local ip=$2
	local cleaned_IP="$(cleanIP $ip)"
	local outputPath=$defaultPath/net
	mkdir -p $outputPath

	local outputAll=$outputPath/alive_ips.txt
	local output=$outputPath/$cleaned_IP.alive.txt
	local output_raw=$outputPath/$cleaned_IP.alive.gnmap

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "============================================================================"
	echo "Scanning network $ip for domain $project"
	echo "Current time: $now"
	echo "============================================================================"
	sudo nmap -vv -sn -oG $output_raw "$ip"
	cat $output_raw | grep "Status: Up" | awk '{print $2}' | tee $output
	cat $output | anew $outputAll
	
	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}	

#============================================================================
# Downloads the whole content of the provided URL including all HTML
#============================================================================
function download_all() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local url=$2
	
	local norm_url=$(cleanURL $url)
	
	local outputPath=$workPath/$norm_url
	mkdir -p $outputPath
	
	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "============================================================================"
	echo "Performing detection of open ports for IP range $input of domain $PROJECT"
	echo "Current time: $now"
	echo "============================================================================"
	
	wget --no-check-certificate --no-clobber --convert-links --page-requisites --random-wait -r -E -e robots=off -U mozilla -np -P $outputDir $url
	
	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="

}

function getDomainControllerFromIPRange() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	

	local ipRange=$2
	local outputPath=$workPath/nmap_root_dse.xml 

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "============================================================================"
	echo "Performing detection of domain controller for ip range $ipRange"
	echo "Current time: $now"
	echo "============================================================================"

	nmap -p 88,389 -T4 -A -v --script ldap-rootdse -oX $outputPath $ipRange
}

function getSMTPOpenRelay() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local target=$2
	
	if [ "$#" -gt 2 ]; then
		local port=$3
	else	
		local port=25
	fi
	
	local outputPath=$defaultPath/host
	local outFile=$outputPath/$2.smtp-open-relay.xml
	mkdir -p $outputPath

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "============================================================================"
	echo "Performing detection of domain controller for domain $domain"
	echo "Current time: $now"
	echo "============================================================================"
	
	nmap -p $port -sV --script smtp-open-relay -v --script-args smtp-open-relay.to=samareina@protonmail.com,smtp-open-relay.from=pentest@secinto.com $target -oX $output
	
	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Pings all hosts in the provided /16 (Class B) network and returns if they
# responded. Result is printed in the console and stored in the network
# folder &NET_FOLDER in the selected project/domain. The network must be 
# specified only with two octets. For example for 10.16.0.0/16 the following
# notation (command) must be used:
# 
# Basic command:
#     pingResponseClassB demo.com 10.16 
#============================================================================
function pingResponseClassB() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local ip=$2
	local cleaned_IP=$(cleanIP $ip)
	local outputPath=$defaultPath/net
	local outFileRaw=$outputPath/$cleaned_IP.ping.info.raw
	local outFile=$outputPath/$cleaned_IP.ping.info
	mkdir -p $outputPath

	local now="$(date +'%d/%m/%Y-%k:%M:%S')"

	echo "============================================================================"
	echo "Scanning CLASS B network $ip for domain $project"
	echo "Current time: $now"
	echo "============================================================================"
	
	#for j in $(seq 0 254) ; 
	#do 
		#printf "%-16s %s \n" $ip.$j.0/24
		#for i in $(seq 1 254) ; 
		#do
	time ( s=$ip ; for j in $(seq 0 254) ; do for i in $(seq 1 254) ; do ( ping -n -c 1 -w 1 $ip.$j.$i 1>/dev/null 2>&1 && printf "%-16s %s\n" $ip.$j.$i responded ) & done ; done ; wait ; echo ) | tee $outFileRaw
		#done ; 
	#done ; 
	
	cat $outFileRaw | awk '{print $1}' | tee $outFile

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Tries to identify virtual hosts on a specified server using brute force. 
# The word list used by default is namelist.txt from Daniel Miesslers 
# SecLists repo. If the protocol is not specified, HTTPS is used. 
# To specify a filter for the response size also a protocol must be specified. 
# The response size filter can be a comma separated list of integer values.
# If wordlist is specified it is used instead of the default one.
# 
# Basic command:
#     vhost_enum "project" "ip address" "TLD host name" "protocol" \
#			"filter response size" "path to wordlist"
# Examples:
#     vhost_enum secinto.com 217.160.0.15 secinto.com  
#     vhost_enum secinto.com 217.160.0.15 secinto.com http
#     vhost_enum secinto.com 217.160.0.15 secinto.com https 45,56,78
#     vhost_enum secinto.com 217.160.0.15 secinto.com https 45,56,78 /home/test/wordlist.txt
#============================================================================
function vhost_enum() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local ip=$2
	local host=$3
	local prot="https"
	local wordlist="/opt/repos/SecLists/Discovery/DNS/namelist.txt"
	
	if [ $# -eq 4 ]; then
		prot=$4
	fi
	
	if [ $# -eq 6 ]; then
		wordlist="$6"
	fi
	
    local url="$prot://$ip"
	
	if [ "$#" -lt 5 ]; then
		ffuf -c -w $wordlist -u "$url" -H "Host: FUZZ.$host"
	else
		ffuf -c -w $wordlist -u "$url" -H "Host: FUZZ.$host" -fs "$5"
	fi
}

#============================================================================
# Performs a full Nmap scan over all identified IPs (DPUX). The function 
# nmap_ip_full is on the list of IPs from dpux_clean.txt.
#============================================================================
function fullNmapScan() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$reconPath/dpux_clean.txt
	
	if [ $# -eq 2 ]; then
		local input=$2
		echo "==========================================================================="
		echo "Using non-default input $input"
		echo "==========================================================================="
	fi
	
	if [ -s $input ]; then
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} for generating services.json started"
		echo "Current time: $now"
		echo "==========================================================================="
		
		local filename=$(getFilename $input)
		local fileWOExt=$(getFilenameWithoutExtension $filename)

		nmap_list_full $project $input
		
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="
	fi
}

#============================================================================
# Performs a hping3 scan to get the uptime if possible from the host.
# 
# Basic command:
#	getUptime project
#
# Examples:
#	getUpTime secinto.com
#============================================================================
function getUptime() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local input=$reconPath/ports.$project.output.xml

	if [ $# -eq 2 ]; then
		local input=$2
		echo "==========================================================================="
		echo "Using non-default input $input"
		echo "==========================================================================="
	fi
	

	if [ -s "$input" ]; then

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} for identifying services on open ports started"
		echo "Current time: $now"
		echo "==========================================================================="

		mkdir -p $defaultPath/host
		
		local output=$defaultPath/findings/uptime.txt
		local temp=$defaultPath/work/uptime
		
		mkdir -p $temp

		if [ -f $output ]; then
			rm $output
		fi

		local ips="$(python3 $script -ip -f $input)"
		while read -r line
		do
			local open_tcp_ports="$(getOpenPortsForHost $line tcp $input)"
			
			if [ ! -z "$open_tcp_ports" ]; then
				local port="$(echo $open_tcp_ports | awk -F',' '{print $1}')"  
				echo "Getting uptime from $line on port $port"
				sudo hping3 -p $port -S --tcp-timestamp -c 2 $line > $temp/uptime_$line.txt 2>&1
				local outputText="$(cat $temp_$line.txt | grep "System uptime")"
				if [ ! -z "$outputText" ]; then
					echo $outputText | awk -v ipAddress=$line -v portInfo=$port '{print "{\"ip\": \"" ipAddress "\", \"port\": \"" portInfo "\", \"days\": \"" $4 "\", \"hours\": \"" $6 "\"}"}' >>$output
				fi
			fi
		done <<< "$ips"

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="

	fi
}



#============================================================================
# Performs a NMAP scan over the hosts and ports already identified to be 
# open and listening. It uses the DPUX list of hosts and ports for input as 
# created during recon.
# Each host in the list is scanned with only the open ports performing 
# service, OS discovery, applying default and vuln scripts and performing
# traceroute.
# 
# Basic command:
#	fullServiceScan project
#
# Examples:
#	fullServiceScan secinto.com
#============================================================================
function fullServiceScan() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local script="/opt/tools/nmapXMLParser/nmapXMLParser.py"
	local input=$defaultPath/nmap/dpux_clean.xml

	if [ $# -eq 2 ]; then
		local input=$2
		echo "==========================================================================="
		echo "Using non-default input $input"
		echo "==========================================================================="
	fi
	

	if [ -s "$input" ]; then

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} for identifying services on open ports started"
		echo "Current time: $now"
		echo "==========================================================================="

		local ips="$(python3 $script -ip -f $input)"

		while read -r line
		do
			local open_tcp_ports=$(getOpenPortsForHost $line tcp $input)
			local open_udp_ports=$(getOpenPortsForHost $line udp $input)
			local output=$defaultPath/nmap/$line
			
			local run=true
			
			if [[ ! -z "$open_tcp_ports" && ! -z "$open_udp_ports" ]]; then
				echo "Open TCP ports: $open_tcp_ports"
				echo "Open UDP ports: $open_udp_ports"
				local scan_ports="-sT -sU -p T:$open_tcp_ports,U:$open_udp_ports"
			elif [[ ! -z "$open_tcp_ports" && -z "$open_udp_ports" ]]; then
				echo "Open TCP ports: $open_tcp_ports"
				local scan_ports="-sT -p T:$open_tcp_ports"
			elif [[ -z "$open_tcp_ports" && ! -z "$open_udp_ports" ]]; then
				echo "Open UDP ports: $open_udp_ports"
				local scan_ports="-sU -p U:$open_udp_ports"
			else 
				local run=false
			fi

			if $run; then
				sudo nmap -v -Pn $scan_ports -sV -sC -A -oX $defaultPath/nmap/$line.xml $line
			fi
			
		done <<< "$ips"

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="

	fi
}

