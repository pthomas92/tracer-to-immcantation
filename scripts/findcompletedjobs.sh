#!/bin/bash

HOURS=$1
JOB_NUMB=$2
JOB_NAME=$3
EXIT_STATUS=$4


jobhist --hours $HOURS | tail -n+3 > completed_script_output

while read -r line
do 
	
	IFS='|' read -ra columns <<< "$line"

	for i in "${!columns[@]}"
	do
    	columns[$i]="${columns[$i]#"${columns[$i]%%[![:space:]]*}"}"
    	columns[$i]="${columns[$i]%"${columns[$i]##*[![:space:]]}"}"
	done

	if [[ ${columns[4]} == "$JOB_NUMB" ]]; then
		if [[ ${columns[7]} == "$JOB_NAME" ]]; then
			if [[ ${columns[6]} == "$EXIT_STATUS" ]]; then
				echo $line >> "EXIT-${EXIT_STATUS}_${JOB_NAME}_${JOB_NUMB}.txt"
			fi
		fi
	fi



done < completed_script_output

