#!/bin/bash

## ---------------------------------------------------------------- ##
## DCM-EXTRACT-MODEL-DATA.SH
## ---------------------------------------------------------------- ##
## Extract data from DCM models 
## ---------------------------------------------------------------- ##
## History 
## ---------------------------------------------------------------- ##
##
## 2019-01-22 : Added the subject DCM folderas as a parameter. Also,
##            : modified the script to print out the results to
##            : STOUT (for consistency with other scripts). Changed
##            : the name to 'dcm-extract-model-data.sh', also for
##            : consistency.
## 
## 2013-05-16 : The matlab code now correctly outputs the size of
##            : each matrix being written.
##
## 2013-05-11 : Added code that checks the consistency between the
##            : size of a parameter matrix and the corresponding
##            : name matrix in Matlab.
##
## 2013-03-14 : Modified the output Matlab code so that it now
##            : adds a header with column names to the output files
##            : (the parameter matrices). Column names are created
##            : from the data of tyhe first DCM model.
##
## 2012-02-07 : Generalized the code. Now takes the model as an 
##            : argument.
##
## 2012-02-02 : File created
## ---------------------------------------------------------------- ##

NL="
"   # new line

HELP_MSG="extract-dcm-data
 --------------------------------------
 This program extracts the various DCM
 matrices for a specific model. It 
 creates files corresponding to each
 matrix for each given participant, as
 well as group matrices with all
 participants.
  
 Usage
 --------------------------------------
 $ extract-dcm-data.sh <model> <dcm_dir>
                    <sub1> ... <subN>
 
 where:
   <model>  is the DCM model name 
          (without the .mat extension)
   <dcm_dir> is the name of the dcm folder
   <subX>   is the [list of] of subject
          folders.

 Notes
 --------------------------------------
 * The script must be run from the root
   folder, where all the subjects 
   folders are located
 * Each subject folder must have a 'DCM'
   directory where the model is located
 * At least two arguments need to be 
   provided (model and at least one 
   subject)
" 

if [ $# -lt 2 ]; then
    echo "$HELP_MSG"
    exit
fi

MODEL=$1
shift
DCM_DIR=$1 #'dcm_results'
shift

# MFILE=`pwd`/extract_${MODEL}_data_`date +%Y_%m_%d_%H%M`.m
BASE_DIR="`pwd`"


echo "% Extracting DCM data for $@"

INIT=0  # Flag to check for the initialized VOI names, which will
        # be used to create the headers for the files containing
        # matrices A, B, C, and D. The VOI names and headers are
        # created after parsing the first subject; after that this
        # flag is set to 1.

for subj in $@; do
    echo "clear DCM;"  
    echo "load(fullfile('${BASE_DIR}', '${subj}', '$DCM_DIR', '${MODEL}.mat'));"  

    if [ $INIT -eq 0 ]; then 
	echo "Not initialized, creating names now" >&2
        # This is the code that creates the name matrices
	echo "vois={DCM.xY.name};"     # VOI names
	echo "inputs=DCM.U.name;"      # Input names
	echo "nv = DCM.n;"             # Number of VOIs
	echo "ni = length(inputs);"    # Number of inputs
    
	echo "namesA=cell(nv, nv);"  
	echo "namesB=cell(nv, nv, ni);"  
	echo "namesC=cell(nv, ni);"  
	echo "namesD=cell(nv, nv, nv);"  
	echo "for i=1:nv,"  
	echo "    for j=1:ni,"  
	echo "        namesC{i,j}=strcat(inputs{j},'-to-',vois{i});"  
	echo "    end"  
	echo "    for j=1:nv,"  
	echo "        namesA{i,j}=strcat(vois{j},'-to-',vois{i});"  
	echo "        for k=1:ni,"  
	echo "            namesB{i,j,k}=strcat(vois{j},'-to-',vois{i}, '-by-', inputs{k});"  
	echo "        end"  
	echo "        for k=1:nv,"  
	echo "            namesD{i,j,k}=strcat(vois{j},'-to-',vois{i}, '-by-', vois{k});"  
	echo "        end"  
	echo "    end"  
	echo "end"  

	for matrix in 'A' 'B' 'C' 'D'; do
	    echo "res_file  = fopen('${BASE_DIR}/${MODEL}_data_${matrix}.txt', 'w');"  
	    echo "c=cumprod(size(names${matrix}));"  
	    echo "n=c(end);"  
	    echo "vals=reshape(names${matrix},1,n);"  
	    echo "fprintf(res_file, '%s\t', 'Subject');"  
	    echo "fprintf(res_file, '%s\t', vals{:});"  
	    echo "fprintf(res_file, '\n');"  
	done
	INIT=1
    fi

    echo "${NL}%------------------------------------"  
    echo "disp('Extracting model ${MODEL} data for ${subj}');"  
    echo "${NL}%------------------------------------${NL}"  
    for matrix in 'A' 'B' 'C' 'D'; do
	echo "disp('    Extracting matrix ${matrix}');"  
	echo "subj_file = fopen('${BASE_DIR}/${subj}/${DCM_DIR}/${subj}_${MODEL}_data_${matrix}.txt', 'w');"  
	echo "res_file  = fopen('${BASE_DIR}/${MODEL}_data_${matrix}.txt', 'a');"  
	echo "c = cumprod(size(DCM.Ep.${matrix}));"  
	echo "n = c(end);"  
	echo "fprintf('        (Size: %d)\n', n);"  
	echo "if n ~= 0"  
	echo "    vals = reshape(names${matrix},1,n);"  
	echo "    fprintf(subj_file, '%s\t', vals{:});"  
	echo "    fprintf(subj_file, '%f\t', reshape(DCM.Ep.${matrix}, 1, n)');"  
	echo "    fprintf(res_file, '%s\t', '${subj}');"  
	echo "    fprintf(res_file, '%f\t', reshape(DCM.Ep.${matrix}, 1, n)');"  
	echo "else"  
	echo "    display('    Array of size 0 detected');"  
	echo "end"  
	echo "fprintf(subj_file, '\n');"  
	echo "fprintf(res_file, '\n');"  
	echo "${NL}%------------------------------------${NL}"  
    done
done
