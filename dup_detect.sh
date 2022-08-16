#!/bin/bash
# Requires:
# ipcalc
#
# Designed for Raspberry Pis running raspbian with old network names enabled.
# Checks for duplicate IP addresses across connected non-vlanned subnets.
# Could be improved by automatically populating interfaces to support the
# new convention and by spreading support to redhat-based ipcalc formatting.
# Also, VLAN support, though that's currently unnecessary.





CheckItOut(){
# Multiple responses on ARP can indicate a duplicate IP.
# This is what this checks for.  It could be improved by
# checking replies against the first MAC address to respond.


	pinglines=`arping -I eth0 $Addr -c 3 | wc -l`
	if [ "$pinglines" -gt "8" ]
	then
		printf '\n\n'
		echo "Duplicate detected on $Addr"
		printf '\n'
	fi
}





main(){
# Outer while loop - Checks for currently assigned IPs on eth0
# then loops through the subnet by formatting with ipcalc, which
# pulls the network and broadcast address, breaks it down into
# component octets, then sets up loops through each, calling 
# CheckItOut to verify a lack of duplication.




	while read line
	do
		printf "Checking...  \n"
		printf "$line.\n"
		printf "["







		current_subnet="`ipcalc $line | grep 'Broadcast\|Network' | sed -e 's/:/=/g' | rev | cut -d' ' -f3-99 | rev | sed -e 's/ //g' | sed -e 's/\/.*//g' 2&>1`"
		if [ -z "$current_subnet" ]
	        then
		        eval $(ipcalc $line | grep 'Broadcast\|Network' | sed -e 's/:/=/g' | rev | cut -d' ' -f3-99 | rev | sed -e 's/ //g' | sed -e 's/\/.*//g')
		elif [ -n "$current_subnet" ]
	        then
			echo "Error."
			exit 1
		fi


	
		FirstNetwork="`echo $Network | cut -d'.' -f1-2`"
		BeginOctetThree="`echo $Network | cut -d'.' -f3`"
		BeginOctetFour="`echo $Network | cut -d'.' -f4`"
		EndOctetThree="`echo $Broadcast | cut -d'.' -f3`"
		EndOctetFour="`echo $Broadcast | cut -d'.' -f4`"


		for OctetThree in `seq $BeginOctetThree $EndOctetThree 2>/dev/null`
		do
			for OctetFour in `seq $BeginOctetFour $EndOctetFour 2>/dev/null`
			do
				Addr=$FirstNetwork.$OctetThree.$OctetFour
				printf "#"
				CheckItOut &
				sleep .125
			done
		done
		printf "]\n"
	done < <(ip a l | grep inet\  | grep -v 127.0. | grep -v eth0\\. | cut -d' ' -f6)

sleep 30
printf "\n"



}



main



