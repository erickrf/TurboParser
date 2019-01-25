# Run the tagger on conll format data
#
# Usage: run_tagger_conll.sh PATH_MODEL PATH_INPUT PATH_OUTPUT [upos|xpos|both]
#
# UPOS or XPOS determine which POS tag annotation to use

path_model=$1
path_input=$2
path_output=$3
pos_type=$4

root_folder="`cd $(dirname $0);cd ..;pwd`"
path_bin=${root_folder}
path_scripts=${root_folder}/scripts
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${root_folder}/deps/local/lib"

tagger_input=${path_input}.tagging
awk -F '\t' '{if ($0 == "") print ""; else if (NF>0 && $0 !~ /^#/ && $1 !~ /-/) print $2 "\t" $4}' \
    ${path_input} > ${tagger_input}

tagger_output=${tagger_input}.output
${path_bin}/TurboTagger --test --file_model=${path_model} \
    --file_test=${tagger_input} --file_prediction=${tagger_output} \
    --logtostderr
python ${path_scripts}/merge-turbotagger-conll.py ${path_input} ${tagger_output} \
    ${path_output} ${pos_type}

rm ${tagger_input} ${tagger_output}

