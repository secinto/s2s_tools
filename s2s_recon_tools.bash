#!/bin/bash

#*****************************************************************************
# 				TOOL - WRAPPERS
#*****************************************************************************
	
#============================================================================
# Performs an subfinder using an input file and interating over all lines.
# Each line is treated as it's own domain and used as input for subfinder. 
# It generates two output files, a text file and a simple JSON file as created
# by subfinder itself.
# 
# Note: Must not be used as command since the initialization is not called
#  but is assumed to have been called from a previous command.
# 
# Used tools:
# source:https://github.com/projectdiscovery/subfinder
# install:{GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder}
#============================================================================
subf_multi() {
	if ! initialize "$@"; then	
		echo "Exiting"
		return
	fi
	
	local domains=$defaultPath/domains.txt
	local input=$defaultPath/multi_domains.txt
	
	dos2unix $input
	if [ -s "$input" ]; then
		for line in $(<$input); 
		do 
			local outputTXT=$reconPath/subf.$line.output.txt
			local outputJSON=$reconPath/subf.$line.output.json
			echo "Checking $outputJSON"
			if checkFile $outputJSON; then
				subf_internal "$line" "$outputTXT" "$outputJSON" "$domains"
				sendToELK $outputJSON subf
				echo "--- All subdomains for $line enumerated --- "
				dns_brute "$line"
				echo "--- Subdomains are enumerated using brute force --- "
			else 
			
				if [ -f "$outputJSON" ]; then
					jq .host $outputJSON | sed "s/\"//g" | sed 's/\\n/\'$'\n''/g' | tee $outputTXT > /dev/null
				fi

				if [ -f "$outputTXT" ]; then
						cat $outputTXT | sort -u | anew $domains > /dev/null
				fi
				if [ -f "$brutePath/$line.enum.brute.txt" ]; then
						cat $brutePath/$line.enum.brute.txt | sort -u | anew $domains > /dev/null
				fi
				if [ -f "$brutePath/$line.fuzz.resv.txt" ]; then
						cat $brutePath/$line.fuzz.resv.txt | sort -u | anew $domains > /dev/null
				fi

				echo "Not performing $FUNCNAME since it has been performed recently."
			fi
			
		done
	else
		echo "Provided input $input is not a valid file."
	fi
}

#============================================================================
# Performs an subfinder run and saves the result as JSON as well as simple 
# list of subdomains. 
# As input the TLD name for which the enumeration should be performed is 
# expected. 
#
# Note: 
# This function should only be used for internal purposes since it doesn't 
# create a valid JSON as needed for other tools, especially s2s portal.
# 
# Used tools:
# source:https://github.com/projectdiscovery/subfinder
# install:{GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder}
#============================================================================
subf_internal() {
	local domain=$1
	local outputTXT=$2
	local outputJSON=$3
	local output=$4

	local now="$(date +'%d/%m/%Y -%k:%M:%S')"
	local resolvers=/opt/tools/s2s_tools/resources/resolvers.txt

	echo "============================================================================"
	echo "Performing subdomain enumeration using subfinder for project $project"
	echo "Storing result in $outputJSON"
	echo "Current time: $now"
	echo "============================================================================"
	
	subfinder -oJ -o "$outputJSON" -d $domain -rL $resolvers

	echo "============================================================================"
	echo "JSON output file $output with subdomains has been created."
	echo "Creating simple domain file $output "
	echo "as a simple list of domains for input in other tools."
	echo "============================================================================"

	jq .host $outputJSON | sed "s/\"//g" | sed 's/\\n/\'$'\n''/g' | tee $outputTXT > /dev/null

	#cat $outputTXT | sort -u | anew $output > /dev/null

	echo "$domain" | anew $output > /dev/null

}

#============================================================================
# Performs an amass passive run and saves the result as JSON as well as simple 
# list of subdomains. 
# As input the TLD name for which the enumeration should be performed is 
# expected. 
# 
# Used tools:
# source:https://github.com/projectdiscovery/subfinder
# install:{GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder}
#============================================================================
subf(){ 
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local outputTXT=$reconPath/$FUNCNAME.$project.output.txt
	local outputJSON=$reconPath/$FUNCNAME.$project.output.json
	local output=$defaultPath/domains.txt
	
	local run=false
	
	if checkFile $outputJSON; then
		local run=true
	fi
	
	if [ "$#" -gt 1 ]; then
		local run=true
	fi
	
	if $run; then
		subf_internal $project $outputTXT $outputJSON $output

		sendToELK $outputJSON subf
		echo "--- All subdomains for $project enumerated --- "
		dns_brute "$@"
		echo "--- Subdomains are enumerated using brute force --- "
	else 
	
		if [ -f "$outputJSON" ]; then
			jq .host $outputJSON | sed "s/\"//g" | sed 's/\\n/\'$'\n''/g' | tee $outputTXT > /dev/null
		fi

		if [ -f "$outputTXT" ]; then
				cat $outputTXT | sort -u | anew $domains > /dev/null
		fi
		if [ -f "$brutePath/$line.enum.brute.txt" ]; then
				cat $brutePath/$line.enum.brute.txt | sort -u | anew $domains > /dev/null
		fi
		if [ -f "$brutePath/$line.fuzz.resv.txt" ]; then
				cat $brutePath/$line.fuzz.resv.txt | sort -u | anew $domains > /dev/null
		fi

		echo "Not performing $FUNCNAME since it has been performed recently."
	fi
	echo "============================================================================"
	echo "Simple domain file $output has been created!"
	echo "============================================================================"

	local now="$(date +'%d/%m/%Y -%k:%M:%S')"
	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="

}

#============================================================================
# Performs resolution of subdomains to unique IPs.
# As input the TLD name for which the process should be performed is 
# expected. 
# As input the simple domain list generated am() run is expected. If it is not 
# already present am() is called for the same domain. See am() for details 
# on the input file.
# 
# Used tools:
# source:https://github.com/projectdiscovery/dnsx
# install:{GO111MODULE=on go get -v github.com/projectdiscovery/dnsx/cmd/dnsx}
#============================================================================
dpux() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local input=$defaultPath/domains.txt
	local output=$reconPath/dpux.txt
	local outputSimple=$reconPath/dpux_host_to_ip.json
	local outputDomains=$defaultPath/domains_dns.txt
	local outputJSON=$reconPath/$FUNCNAME.$project.output.json

	if [ -s "$input" ]; then
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"

		echo "============================================================================"
		echo "Performing resolution of subdomains to unique IPs for domain $project"
		echo "Current time: $now"
		echo "============================================================================"



		# Creating the domain:ip output together with the response from the DNS resolving. Host names can
		# exist multiple times in the output. For each IP combination a unique entry is created.
		#cat $input | dnsx -silent -a -resp | sort -u | sed 's/\[//g' | sed 's/\]//g' | sed 's/\ /\,/g' | sed '/127.0.0.1/d' | tee $outputCSV
		if [ -s "$outputJSON" ]; then
			rm $outputJSON
		fi

		cat $input | dnsx -silent -a -txt -srv -ns -mx -soa -axfr -cname -aaaa -resp -json -o $outputJSON 
		
		
		echo "============================================================================"
		echo "Creating plain list of unique IPs for domain $project"
		echo "============================================================================"
		cat $outputJSON | jq .a | sed 's/\[//g' | sed 's/\]//g' | sed 's/\"//g' | sed 's/null//g' | sed 's/,//g' | \
			sed 's/localhost//g' | sed 's/\ //g' | sed 's/[[:blank:]]//g' | sed 's/[[:space:]]//g' | sed '/^$/d' | \
			grep -vE "^10\..*|^172\.(1[6-9]|2[0-9]|3[0-1])\..*|^192\.168\..*|^127\.0\..*" | sort -u | tee $output
		
		sendToELK $outputJSON dpux
		
		# TODO: IPv6 addresses need to be integrated as well
		
		cat $outputJSON | jq 'select(.a != null) | {host, ip: .a[]}' | jq -c '.' | tee $outputSimple > /dev/null
		
		sendToELK $outputSimple dpux

		cat $outputJSON | jq .host | sed 's/\"//g' | tee $outputDomains > /dev/null
		

			
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="
	fi

}

#============================================================================
# Performs DNS resolution for MX and TXT records for checking mail security
# topics. As input the TLD name for which the process should be performed is 
# expected. 
# As input the simple domain list generated subf run is expected. 
# If it is not already present subf is called for the same domain. 
# See subf for details on the input file.
# 
# Used tools:
# source:https://github.com/projectdiscovery/dnsx
# install:{GO111MODULE=on go get -v github.com/projectdiscovery/dnsx/cmd/dnsx}
#============================================================================
dnsmx() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi

	local input=$defaultPath/domains_clean.txt
	local multi=$defaultPath/multi_domains.txt
	local inputAll=$defaultPath/domains.txt
	local outputJSON=$reconPath/$FUNCNAME.$project.output.json
	local outputSimple=$reconPath/dpux_clean.json
	
	if [ -s "$input" ]; then

		if [ -s "$outputJSON" ]; then
			rm $outputJSON
		fi

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"

		echo "============================================================================"
		echo "Performing resolution of MX and TXT records for cleaned domains from $project"
		echo "Current time: $now"
		echo "============================================================================"

		
		local inputTemp=$input-temp.txt
		cat $input | anew $inputTemp > /dev/null
		
		
		if [ -s "$multi" ]; then
			for line in $(<$multi); 
			do 
				echo "$line" | anew $inputTemp > /dev/null
				echo "_dmarc.$line" | anew $inputTemp > /dev/null
			done
		else
			echo "_dmarc.$project" | anew $inputTemp > /dev/null
			echo "$project" | anew $inputTemp > /dev/null
		fi
		
		cat $inputAll | grep _domainkey | anew $inputTemp > /dev/null

		cat $inputTemp | dnsx -silent -a -txt -mx -cname -aaaa -resp -json -o $outputJSON 
		#cat $outputJSON | jq .a | sed 's/\[//g' | sed 's/\]//g' | sed 's/\"//g' | sed 's/null//g' | sed 's/,//g' | sed 's/0.0.0.0//g' | \
		#	sed 's/127.0.0.1//g' | sed 's/127::1//g' | sed 's/::1//g' | sed 's/127.000.000.001//g' | sed 's/localhost//g' | \
		#	sed 's/\ //g' | sed 's/[[:blank:]]//g' | sed 's/[[:space:]]//g' | sed '/^$/d' | sort -u | tee $output
	
		rm $inputTemp
	
		cat $outputJSON | grep -vE "._domainkey.|_dmarc.|\"spf." | jq 'select(.a != null) | {host, ip: .a[]}' | jq -c '.' | tee $outputSimple > /dev/null

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="
	fi

}

#============================================================================
# Performs a fast port scan over the resolved unique IPs and generates a 
# XML output in NMAP format from it. It is mostly relevant for finding hosts
# which are up and identifying the typical web ports open so that http_from 
# can get additional info.
#============================================================================
ports() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$reconPath/dpux_clean.txt
	local outputJSON=$reconPath/unique_open_ports.json
	local output=$reconPath/$FUNCNAME.$project.output.xml
	local outputTXT=$reconPath/unique_ip_ports.txt
	local script=/opt/tools/nmapXMLParser/nmapXMLParser.py
	local ports="-F"
	
	if [ "$#" -gt 1 ]; then
		if [ "$#" -eq 3 ]; then
			local target="$3"
			cleanedIP=cleanIP $target
			output=$reconPath/$cleanedIP.$project.output.xml
		fi
		
		if [ "$2" == "-" ]; then
			ports="-p-"
		else 
			if checkIfNumber $2; then
				ports="-top-ports $2"
			fi
		fi
	fi

	local now="$(date +'%d/%m/%Y -%k:%M:%S')"
	local ipCount="$(cat $input | wc -l)"
	echo "============================================================================"
	echo "Performing port scan over $ipCount unique IPs for domain $project"
	echo "Current time: $now"
	echo "============================================================================"
	
	if [ -s "$input" ]; then
		echo "Required input $input already exists!"
	else
		echo "Required input $input doesn't exist!"
		dpux "$@"
	fi
	if [ -z $target ]; then
		sudo nmap -Pn $ports -vv -T3 -iL $input -oX $output --host-timeout 600
		#sudo chown samareina:researchers $output
	else
		sudo nmap -Pn $ports -vv -T3 -oX $output --host-timeout 600 $target
		#sudo chown samareina:researchers $output
	fi
	
	python3 $script -f $output -json $outputJSON
	
	sendToELK $outputJSON ports
	
	echo "============================================================================"
	echo "Creating a list of IP:PORT combinations of alive HTTP servers for domain $project"
	echo "============================================================================"

	jq -r '[.ip, .port] | @csv' $outputJSON | sed "s/\"//g" | sed "s/\,/\:/g" | sort -u | tee $outputTXT
	
	#sudo chown samareina:researchers $outputTXT
	
	xsltproc $output -o $(changeFileExtension $output "html")
		
	local now="$(date +'%d/%m/%Y -%k:%M:%S')"
	echo "==========================================================================="
	echo "Workflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Verifies for which domains an HTTP service exists. 
# As input the TLD name for which the enumeration should be performed is 
# expected. 
# As input the simplified domain list from the am() run is expected. If it is 
# not already present, am() is called for the same domain. 
# See am() for details on the input file.
#
# Used tools:
# source{1}:https://github.com/projectdiscovery/httpx
# install{1}:{GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx}
#============================================================================
http_from() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	if [ "$#" -lt 3 ]; then
		echo "Missing input parameters, 3 required (project, input, type)"
	else 
		local input=$2
		local type=$3
		local outputDir=$defaultPath/responses
		local output=$reconPath/$FUNCNAME.$type.output.json
		
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		
		echo "============================================================================"
		echo "Performing HTTP server resolution from subdomain names for project $1"
		echo "Current time: $now"
		echo "============================================================================"

		echo $output
		
		if [ $type == "clean" ]; then
			local output=$reconPath/$FUNCNAME.$type.$4.output.json
			cat $input | httpx -hash "mmh3" -random-agent -vhost -nf -location -cl -ct -td -cdn -cname -ip -server -tls-grab -json -o $output -fr -maxr 10 -srd $outputDir/$type -store-chain
			sendToELK $output httpx
		else 
			local outputURLs=$reconPath/http_servers_all.txt
			local outputHttpsURLs=$reconPath/https_servers_all.txt
			# Required for removing duplicates up front
			cat $input | httpx -silent -hash "mmh3" -json -ip -nf -o $output -fr -maxr 10 -srd $outputDir/$type -store-chain

			cat	$output | jq .url | sed 's/\"//g' | anew $outputURLs > /dev/null
			cat	$outputURLs | grep https | anew $outputHttpsURLs > /dev/null
		fi
		

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="
	fi
}

#============================================================================
# Verifies for which domains an HTTP service exists. 
# As input the TLD name for which the enumeration should be performed is 
# expected. 
# As input the simplified domain list from the am() run is expected. If it is 
# not already present, am() is called for the same domain. 
# See am() for details on the input file.
#
# Used tools:
# source{1}:https://github.com/projectdiscovery/httpx
# install{1}:{GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx}
#============================================================================
http_from_domains() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$defaultPath/domains.txt

	if [ -s "$defaultPath/domains_with_ports.txt" ]; then
		local input=$defaultPath/domains_with_ports.txt
	fi
	
	if [ -s "$input" ]; then
		echo "Required input $input already exists!"
	else
		echo "Required input $input doesn't exist!"
		subf "$@"
	fi
	
	http_from $1 $input "domains"
	
	local now="$(date +'%d/%m/%Y -%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="

}

#============================================================================
# Verifies for which IPs associated open ports an HTTP service exists. 
# As input the TLD name for which the enumeration should be performed is 
# expected. 
# As input the open ports list from the ports() run is expected. If it is 
# not already present, ports() is called for the same domain. 
# See ports() for details on the input file.
#
# Used tools:
# source{1}:https://github.com/projectdiscovery/httpx
# install{1}:{GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx}
#============================================================================
http_from_ips() {
	
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$reconPath/unique_ip_ports.txt
	
	if [ -s "$input" ]; then
		echo "Required input $input already exists!"
	else
		echo "Required input $input doesn't exist!"
		ports "$@"
	fi
	
	http_from $1 $input "ips"
	
	local now="$(date +'%d/%m/%Y -%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
	
}


#============================================================================
# Verifies for the provided input list (domains and IPs) if an HTTP service 
# exists and provides all relevant information about it. 
# As input a list of hosts - either DNS or IP (and port) - is used for 
# probing for HTTP service. The output it is written to the provided file.
#
# Used tools:
# source{1}:https://github.com/projectdiscovery/httpx
# install{1}:{go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest}
#============================================================================
http_from_all() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	rm -rf "$responsePath/domains"
	rm -rf "$responsePath/ips"
	rm $reconPath/http_servers_all.txt
	rm $reconPath/https_servers_all.txt

	http_from_domains "$@"
	http_from_ips "$@"

	local now="$(date +'%d/%m/%Y -%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Verifies for the provided input host list if an HTTP service exists and
# provides all relevant information about it. 
# As input a list of hosts - either DNS or IP (and port) - is used for 
# probing for HTTP service. The output it is written to the provided file.
#
# Used tools:
# source{1}:https://github.com/rverton/webanalyze
# install{1}:{go get -v -u github.com/rverton/webanalyze/cmd/webanalyze}
#============================================================================
web_tech() {
	if [ "$#" -eq 2 ]; then
		local input=$1
		local output=$2
		
		
		local filename="$(getFilenameWithoutExtension $output)"

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "============================================================================"
		echo "Performing web technology resolution from subdomains for domain $project"
		echo "Current time: $now"
		echo "============================================================================"

		if [[ -s "$input" && ! -z "$output" ]]; then
			echo "Required input $input already exists!"
			webanalyze -silent -redirect -hosts $input -crawl 2 -output json 2> $filename.log | tee $output > /dev/null
		elif [[ ! -f "$input" ]]; then
			echo "Output file name must be specified!"
		else
			echo "Required input $input doesn't exist!"
		fi

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="		
	else
		echo "============================================================================"
		echo "${FUNCNAME[0]} requires a list of hosts as input and output file to write the"
		echo "results to be specified as parameters." 
		echo "============================================================================"
	fi

}



#============================================================================
# Obtains all relevant infos from the HTTP servers available via explicit IPs
# as well as the identified subdomain names.
#
# Used tools:
# source{1}:https://github.com/rverton/webanalyze
# install{1}:{go get -v -u github.com/rverton/webanalyze/cmd/webanalyze}
#============================================================================
web_tech_all() {

	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$reconPath/http_servers_clean.txt
	local output=$reconPath/$FUNCNAME.output.json
	web_tech $input $output

	sendToELK $output webanalyze
	
	local now="$(date +'%d/%m/%Y -%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="

}

#============================================================================
# Performs a brute force enumeration of subdomains of the specified project
# using puredns with wordlist and alterx together with shuffledns.
#
# Basic command:
#		dns_brute project
#
# Used tools:
# https://github.com/d3mondev/puredns
#============================================================================
dns_brute() {

	if [ "$#" -eq 1 ]; then
		if ! initialize "$@"; then
			echo "Exiting"
			return
		fi
		local dns=$project
	else
		# Needed for multi domains to brute force each entry
		local dns=$1
	fi

	local inputTXT=$reconPath/subf.$dns.output.txt
	local outputTXT=$reconPath/subf.$dns.resv.txt
	local domains=$defaultPath/domains.txt
	
	# Resolving DNS entries found by subfinder. If resolved they are added to domains.
	if [ -s "$inputTXT" ]; then
		local dnsEntries="$(cat $inputTXT | wc -l)"
		echo "Found $dnsEntries in $inputTXT"
		if [[ "$dnsEntries" -ge 50 ]]; then
			puredns resolve $inputTXT -q --resolvers $resolvers | tee $outputTXT
		else
			echo "Not resolving entries from subfinder, less than 50"
			cat $inputTXT | anew $outputTXT
		fi
		echo "Adding resolved domains from subfinder to $domains"
		cat $outputTXT | anew $domains
	fi

	dns_enum "$@"
	dns_fuzz "$@"
}

#============================================================================
# Performs a brute force enumeration of subdomains of the specified project
# using puredns.
#
# Basic command:
#		dns_enum project
#
# Used tools:
# https://github.com/d3mondev/puredns
#============================================================================
dns_enum() {

	if [ "$#" -eq 1 ]; then
		if ! initialize "$@"; then
			echo "Exiting"
			return
		fi
		local dns=$project
	else
		# Needed for multi domains to brute force each entry
		local dns=$1
	fi
	
	local domains=$defaultPath/domains.txt
	local inputTXT=$reconPath/subf.$dns.resv.txt
	local output=$brutePath/$dns.enum.brute.txt
	local wordlist=/opt/tools/s2s_tools/resources/dns2_long.txt
	local resolvers=/opt/tools/s2s_tools/resources/resolvers.txt

	local run=false

	if checkFile $output; then
		local run=true
	fi

	if [ ! -s "$inputTXT" ]; then
		local run=false
	else
		local dnsEntries="$(cat $inputTXT | wc -l)"
		if [[ "$dnsEntries" -lt 2 ]]; then
			local run=false
		fi
	fi
	
	if [ "$#" -gt 1 ]; then
		local run=true
	fi
	
	if $run; then

		local now="$(date +'%d/%m/%Y -%k:%M:%S')"

		echo "==========================================================================="
		echo "Worflow ${FUNCNAME[0]} started"
		echo "Current time: $now"
		echo "==========================================================================="

		puredns bruteforce $wordlist $dns -q -r $resolvers | tee $output 
		cat $output | anew $domains
		cat $output | anew $inputTXT
		
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="			
	else
		echo "Not performing $FUNCNAME since it has been performed recently."
		if [ -f "$output" ]; then
			cat $output | anew $domains
			cat $output | anew $inputTXT
		fi
	fi
}	

#============================================================================
# Performs a brute force enumeration of subdomains of the specified project
# using puredns.
#
# Basic command:
#		dns_fuzz project
#
# Used tools:
# https://github.com/d3mondev/puredns
#============================================================================
dns_fuzz() {

	if [ "$#" -eq 1 ]; then
		if ! initialize "$@"; then
			echo "Exiting"
			return
		fi
		local dns=$project
	else
		# Needed for multi domains to brute force each entry
		local dns=$1
	fi
	
	local domains=$defaultPath/domains.txt
	local inputTXT=$reconPath/subf.$dns.resv.txt

	local outputRaw=$brutePath/$dns.fuzz.raw.txt
	local outputResolved=$brutePath/$dns.fuzz.resv.txt
	local resolvers=/opt/tools/s2s_tools/resources/resolvers.txt

	local run=false
	
	if checkFile $outputResolved; then
		local run=true
	fi
	
	if [ ! -s "$inputTXT" ]; then
		local run=false
	else
		local dnsEntries="$(cat $inputTXT | wc -l)"
		if [ $dnsEntries -lt 2 ]; then
			local run=false
		fi
	fi

	if [ "$#" -gt 1 ]; then
		local run=true
	fi
	
	if $run; then
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"

		echo "==========================================================================="
		echo "Worflow ${FUNCNAME[0]} started"
		echo "Current time: $now"
		echo "==========================================================================="

		alterx -l $inputTXT -en -o $outputRaw
		
		#shuffledns -d $dns -l $outputRaw -r $resolvers -silent | tee $outputResolved
		puredns resolve $outputRaw -q -r $resolvers | tee $outputResolved
		
		cat $outputResolved | anew $domains
		cat $outputResolved | anew $inputTXT
		
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"
		echo "==========================================================================="
		echo "Workflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="			
	else
		echo "Not performing $FUNCNAME since it has been performed recently."
		if [ -f "$outputResolved" ]; then
			cat $outputResolved | anew $domains
			cat $outputResolved | anew $inputTXT
		fi
	fi
}	

#============================================================================
# Performs HTTPx only over the cleaned domains list and creates a cleaned 
# list of http servers, currently without IPs. Could be extended to it, but
# usually only duplicates or dead ends will be found.
#
# Basic command:
#		do_clean project
#
#============================================================================
do_clean() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local domains=$defaultPath/domains_clean.txt
	local ips=$reconPath/dpux_clean.txt

	if [ -s "$domains" ]; then
	
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"

		echo "==========================================================================="
		echo "Worflow ${FUNCNAME[0]} - performing HTTPx over cleaned domains - started"
		echo "Current time: $now"
		echo "==========================================================================="
		
		rm -rf "$responsePath/clean"

		#rm $reconPath/http_from.clean.domains.output.json
		#rm $reconPath/http_from.clean.ips.output.json
		if [ -f "$reconPath/http_from.clean.output.json" ]; then
			rm $reconPath/http_from.clean.output.json
		fi
		# Perform resolution of cleaned domains.
		http_from $project $domains "clean" "domains"
		# Perform resolution of cleaned ips.
		http_from $project $ips "clean" "ips"
		
		saveResponses "clean"

		# Create list of cleaned HTTPs servers without IPs.
		local outputDomainURLs=$reconPath/https_servers_clean_domains.txt
		cat	$reconPath/http_from.clean.domains.output.json | jq .url | sed 's/\"//g' | grep https | tee $outputDomainURLs > /dev/null
		
		# Create combined list of cleaned HTTP resolution
		cat $reconPath/http_from.clean.ips.output.json | anew $reconPath/http_from.clean.output.json > /dev/null
		cat $reconPath/http_from.clean.domains.output.json | anew $reconPath/http_from.clean.output.json > /dev/null
		
		# Create list of cleaned HTTP/HTTPs servers including IPs
		local outputURLs=$reconPath/http_servers_clean.txt
		local outputHttpsURLs=$reconPath/https_servers_clean.txt
		cat	$reconPath/http_from.clean.output.json | jq .url | sed 's/\"//g' | tee $outputURLs > /dev/null
		cat	$outputURLs | grep https | tee $outputHttpsURLs > /dev/null

		
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"

		echo "==========================================================================="
		echo "Worflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="
	fi
}

#============================================================================
# 
# 
# Basic command:
#
#============================================================================
function tls_check() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local input=$reconPath/https_servers_clean_domains.txt
	local outputDomains=$reconPath/$FUNCNAME.domains.json
	local script="/opt/tools/testssl.sh/testssl.sh"

	if [ -s "$input" ]; then
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"

		echo "==========================================================================="
		echo "Worflow ${FUNCNAME[0]} started - Identifying issues with TLS and certs"
		echo "Current time: $now"
		echo "==========================================================================="

		#sslyze --targets_in $inputDomains --json_out $outputDomains
		#sslyze --targets_in $inputIPs --json_out $outputIPs
		rm $defaultPath/work/*tls.*
		
		interlace -tL $input -o $defaultPath/work -c "$script -oA $defaultPath/work/_cleantarget_.tls.json --fast --assume-http --connect-timeout 900 --openssl-timeout 900 --warnings off _target_"
		
		local now="$(date +'%d/%m/%Y -%k:%M:%S')"

		echo "==========================================================================="
		echo "Worflow ${FUNCNAME[0]} finished"
		echo "Current time: $now"
		echo "==========================================================================="
	fi
}

#============================================================================
# Perform a full recon phase using all relevant tools.
#
# Used tools:
# source{1}:
# install{1}:{}
#============================================================================
recon() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local now="$(date +'%d/%m/%Y -%k:%M:%S')"
	echo "STARTED $now" > $defaultPath/recon_started

	if [ -f "$defaultPath/recon_finished" ]; then
		rm $defaultPath/recon_finished
	fi
	
	local multi_domains=$defaultPath/multi_domains.txt
	
	if [ $# -eq 2 ]; then
		echo "==========================================================================="
		echo "Cleaning results for project $project"
		echo "==========================================================================="
		rm -rf $reconPath
		rn $defaultPath/domains.txt
		
	fi
	
	if [ -s "$multi_domains" ]; then
		echo "==========================================================================="
		echo "Multi domain file found. Performing resolution first"
		echo "==========================================================================="
		subf_multi "$@"
	else
		subf "$@"
	fi
	
	dpux "$@"
	echo "--- All IPs are resolved --- "
	getIPInfoAndCleanDPUx "$@"
	echo "--- Additional IP info obtained --- "
	ports "$@"
	echo "--- All open ports for IPs are identified --- "
	generateHostMappings "$@"
	echo "--- Create port hostname mappings --- "
	http_from_all "$@"
	echo "--- HTTP servers from domains are enumerated --- "
	removeDuplicate "$@"
	echo "--- Cleaned the subdomains from duplicates --- "
	dnsmx "$@"
	echo "--- Identified dns mappings for cleaned domains --- "
	do_clean "$@"
	echo "--- Performed recon for cleaned domains --- "
	tls_check "$@"
	echo "--- Identified issues with TLS and certs --- "
	getFindings "$@"
	echo "--- Get findings from obtained data --- "
	web_tech_all "$@"
	echo "--- web technologies obtained from HTTP servers"
	getWebserversWithProtocolIssues "$@" 
	echo "--- Obtained web servers with protocol issues --- "
	fullNmapScan "$@"
	echo "--- Performed a full Nmap scan over cleaned IPs --- "
	createServicesJSON "$@" true
	echo "--- Created services JSON --- "
	cleanZeroFiles 
	echo "--- Removed zero files --- "

	local now="$(date +'%d/%m/%Y -%k:%M:%S')"

	echo "FINISHED $now" > $defaultPath/recon_finished
	echo "--- RECON FINISHED $now --- "


	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Perform a full recon phase using all relevant tools.
#
# Used tools:
# source{1}:
# install{1}:{}
#============================================================================
full_recon() {
	if ! initialize "$@"; then
		echo "Exiting"
		return
	fi
	
	local multi_domains=$defaultPath/multi_domains.txt
	
	if [ $# -eq 2 ]; then
		echo "==========================================================================="
		echo "Cleaning results for project $project"
		echo "==========================================================================="
		rm -rf $reconPath
	fi
	
	if [ -s "$multi_domains" ]; then
		echo "==========================================================================="
		echo "Multi domain file found. Performing resolution first"
		echo "==========================================================================="
		subf_multi "$@"
	else
		subf "$@"
	fi

	recon "$@"
	
	fullNmapScan "$@"
	echo "--- Performed a full Nmap scan over cleaned IPs --- "
	fullServiceScan "$@"
	echo "--- Performed a full Service scan over cleaned IPs --- "
	gowit "$@" & disown
	echo "--- Screenshots from all default HTTP pages are taken --- "
	hakcrawl "$@" & disown
	echo "--- Links from HTTP pages are crawled --- "
	wayback_domain "$@" & disown
	echo "--- Urls from wayback machine are obtained --- "
	github_dork "$@" & disown
	
	cleanZeroFiles

	local now="$(date +'%d/%m/%Y -%k:%M:%S')"
	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}

#============================================================================
# Perform a full recon phase using all relevant tools for all the existing 
# folders in /opt/s2s. All the existing folders are used as basis FQDN. If 
# in the folder a multi_domains file exist this one is used to enumerate 
# subdomains. Otherwise the folder name is used.
#
# Used tools:
# source{1}:
# install{1}:{}
#============================================================================
function recon_all {
	echo "==========================================================================="
	echo "Starting recon for all existing projects"
	echo "==========================================================================="

	local dirList="$(find /opt/s2s/. -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -R --random-source=/dev/urandom)"

	for d in $dirList ; do
		
		local folder=$(echo "$d" | sed 's/\/opt\/s2s\///g')
		echo "==========================================================================="
		echo "Performing recon for $folder"
		echo "==========================================================================="
		
		recon $folder
		
	done
	
	local now="$(date +'%d/%m/%Y -%k:%M:%S')"

	echo "==========================================================================="
	echo "Worflow ${FUNCNAME[0]} finished"
	echo "Current time: $now"
	echo "==========================================================================="
}
