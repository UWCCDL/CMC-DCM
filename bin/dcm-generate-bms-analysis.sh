#!/bin/bash

## ---------------------------------------------------------------- ##
## DCM-GENERATE-BMS-ANALYSIS.SH
## ---------------------------------------------------------------- ##
## Extract DCMs for the Autism task
## ---------------------------------------------------------------- ##
## History 
## ---------------------------------------------------------------- ##
##
## 2016-05-17 : Added subject directory for DCMs as an argument
##            : (consistent with other scripts). 
##
## 2015-09-27 : Added documentation and help string
##
## 2013-05-16 : File Created
## ---------------------------------------------------------------- ##

NL="
"   # new line

HELP_MSG="dcm-generate-bms-analysis
 --------------------------------------
 This program creates a matlab script
 to perform a Bayesian Model Selection
 analysis.
  
 Usage
 --------------------------------------
 $ dcm-generate-bms-analysis.sh 
   <models-file> <DCM dir> <BMS dir>
   <subj1> <sub2> ... <subN>
 
 where:
   <models-file>  is a text file listing
          the names of the DCM models
          to compare (including the trailing
          .mat).
   <DCM dir> is the name of the folder where 
          each subject's models can be found
   <BMS dir>  is the name of the folder
          where the BMS file will be
          placed.
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

if [ $# -lt 4 ]; then
    echo "$HELP_MSG"
    exit
fi


models=$1      # Model file name
shift;

dcm_dir=$1     # DCM folder name
shift

dir=`pwd`/$1   # BMS folder name
shift

echo "matlabbatch{1}.spm.stats.bms.bms_dcm.dir = {'${dir}'};"
j=0
for s in $@; do
    j=$((j+1))
    echo "matlabbatch{1}.spm.stats.bms.bms_dcm.sess_dcm{${j}}.mod_dcm = {"
    while read model; do
	model_path=`pwd`/$s/${dcm_dir}/${model}
	echo "'${model_path}'"
    done < $models
    echo "};"
done
echo "matlabbatch{1}.spm.stats.bms.bms_dcm.model_sp = {''};"
echo "matlabbatch{1}.spm.stats.bms.bms_dcm.load_f = {''};"
echo "matlabbatch{1}.spm.stats.bms.bms_dcm.method = 'FFX';"
echo "matlabbatch{1}.spm.stats.bms.bms_dcm.family_level.family_file = {''};"
echo "matlabbatch{1}.spm.stats.bms.bms_dcm.bma.bma_no = 0;"
echo "matlabbatch{1}.spm.stats.bms.bms_dcm.verify_id = 0;"
