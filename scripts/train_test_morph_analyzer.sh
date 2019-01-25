#!/bin/bash

# Root folder where TurboParser is installed.
root_folder="`cd $(dirname $0);cd ..;pwd`"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${root_folder}/deps/local/lib"

# Set options.
language=$1 # Example: "slovene" or "english_proj".
train_algorithm=svm_mira # Training algorithm.
num_epochs=10 # Number of training epochs.
regularization_parameter=1e12 # The C parameter in MIRA.
train=true
test=true
jackknifing=true #false # True for performing jackknifing in the training data. Useful for downstream applications.
model_type=2 # Second-order model (trigrams).
form_cutoff=1 # Word cutoff. Only words which occur more than these times won't be considered unknown.
suffix=morph

# Set path folders.
path_bin=${root_folder} # Folder containing the binary.
path_scripts=${root_folder}/scripts # Folder containing scripts.
path_data=${root_folder}/data/treebanks/${language} # Folder with the data.
path_models=${root_folder}/models/${language} # Folder where models are stored.
path_results=${root_folder}/results/${language} # Folder for the results.

# Create folders if they don't exist.
mkdir -p ${path_data}
mkdir -p ${path_models}
mkdir -p ${path_results}

# Set file paths. Allow multiple test files.
file_model=${path_models}/${language}_${suffix}.model
file_train=$(ls ${path_data}/*-train.conllu)
file_dev=$(ls ${path_data}/*-dev.conllu)
file_test=$(ls ${path_data}/*-test.conllu)

file_train=${file_train}.tagging
files_test[0]=${file_test}
files_test[1]=${file_dev}

# Obtain a prediction file path for each test file.
for (( i=0; i<${#files_test[*]}; i++ ))
do
    file_test=${files_test[$i]}
    file_prediction=${file_test}.pred
    files_prediction[$i]=${file_prediction}
done

################################################
# Train the tagger.
################################################

if $train
then

    if ${jackknifing}
    then
	num_jackknifing_partitions=10
	file_train_jackknifed=${file_train}.pred

	echo "Jackknifing with ${num_jackknifing_partitions} partitions..."
	python ${path_scripts}/split_corpus_jackknifing.py ${file_train} \
            ${num_jackknifing_partitions}

	for (( i=0; i<${num_jackknifing_partitions}; i++ ))
	do
	    file_train_jackknifing=${file_train}_all-splits-except-${i}
	    file_test_jackknifing=${file_train}_split-${i}
	    file_model_jackknifing=${file_model}_split-${i}
            file_prediction_jackknifing=${file_test_jackknifing}.pred

            echo ""
	    echo "Training on ${file_train_jackknifing}..."
	    ${path_bin}/TurboMorphologicalTagger \
		--train \
		--train_epochs=${num_epochs} \
		--file_model=${file_model_jackknifing} \
		--file_train=${file_train_jackknifing} \
		--train_algorithm=${train_algorithm} \
		--train_regularization_constant=${regularization_parameter} \
		--sequence_model_type=${model_type} \
		--form_cutoff=${form_cutoff} \
		--logtostderr
	    
            echo ""
            echo "Running on ${file_test_jackknifing}..."
            ${path_bin}/TurboMorphologicalTagger \
		--test \
		--evaluate \
		--file_model=${file_model_jackknifing} \
		--file_test=${file_test_jackknifing} \
		--file_prediction=${file_prediction_jackknifing} \
		--logtostderr

        if [ "${i}" == "0" ]
	    then
		cat ${file_prediction_jackknifing} > ${file_train_jackknifed}
            else
		cat ${file_prediction_jackknifing} >> ${file_train_jackknifed}
	    fi
	done
    fi

    echo "Training..."
    ${path_bin}/TurboMorphologicalTagger \
        --train \
        --train_epochs=${num_epochs} \
        --file_model=${file_model} \
        --file_train=${file_train} \
        --train_algorithm=${train_algorithm} \
        --train_regularization_constant=${regularization_parameter} \
        --sequence_model_type=${model_type} \
        --form_cutoff=${form_cutoff} \
        --logtostderr
fi

################################################
# Test the tagger.
################################################

if $test
then

    for (( i=0; i<${#files_test[*]}; i++ ))
    do
        file_test=${files_test[$i]}
        file_prediction=${files_prediction[$i]}

        echo ""
        echo "Running on ${file_test}..."
        ${path_bin}/TurboMorphologicalTagger \
            --test \
            --evaluate \
            --file_model=${file_model} \
            --file_test=${file_test} \
            --file_prediction=${file_prediction} \
            --logtostderr

        echo ""
    done
fi