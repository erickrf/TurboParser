#!/bin/bash

# output the word and POS tag columns 
if [ $2 = "upos" ];
then
    field=4
elif [ $2 = "xpos" ];
    then
        field=5
    else
        echo "Unknown field $2"
        exit 1  
fi

file_conll=$1

# ignore lines that start with # or have multiword tokens
awk -v field="$field" -F '\t' '{if ($0 == "") print ""; else if (NF>0 && $0 !~ /^#/ && $1 !~ /-/) print $2 "\t" $field}' \
    ${file_conll} > ${file_conll}.tagging
