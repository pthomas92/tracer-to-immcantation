#!/bin/bash

while IFS= read -r line; do
	var=$(head -n 1 $line)
    if [[ $var =~ ([a-zA-Z0-9]+)_([0-9]{1,3})_([a-zA-Z0-9]{2,3}) ]]; then
        FILE_NAME="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}_${BASH_REMATCH[3]}_"
        # Loop over your array file
        while IFS= read -r line_array; do
            if [[ $line_array =~ $FILE_NAME ]]; then
                echo "$line_array" >> array-params-complete_ERROR-137.txt
            fi
        done < array-params-complete.txt
    fi
done < ERROR_137_run1.txt

