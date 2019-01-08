#!/bin/bash

# output the second and fourth columns (word form and coarse POS tag)
# for lines that don't start with # and don't have multiword tokens
file_conll=$1
awk -F '\t' '{if ($0 == "") print ""; else if (NF>0 && $0 !~ /^#/ && $1 !~ /-/) print $2 "\t" $4}' \
    ${file_conll} > ${file_conll}.tagging
