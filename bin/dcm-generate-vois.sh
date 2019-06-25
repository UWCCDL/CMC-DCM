#!/bin/bash
## ---------------------------------------------------------------- ##
## DCM-GENERATE-VOIS.SH
## ---------------------------------------------------------------- ##
## Generates VOIs for DCM analysis.
## ---------------------------------------------------------------- ##
## The file takes a VOI description file and a list of subject 
## folders. For each subject, it creates VOIs based on the specs
## contained in the VOI file.
## ---------------------------------------------------------------- ##
## Usage:
## 
##   $ dcm-generate-vois.sh <VOI_file> <subj1> <subj2> ... <subjN>.
##
## Where:
##   <VOIfile>: A VOI description file (see below)
##   <subjXX> : the name of a participant's folder.
## ---------------------------------------------------------------- ##
## VOI File Format
##
## The VOI file format is a text table file. Each VOI is a row in
## the table, and each column is an attribute of the VOI. Rows
## in the table correspond to text lines (e.g., separated by line
## feeds) and cells in the table correspond to REGEX words (e.g.,
## columns are separated by white space).
##
## Each line contains the following columns:
##
## 1. VOI name, e.g., 'LPFC'
## 2. MNI Coordinates, separated by ',', with no spaces between 
##    coordinates. E.g., '42,-44,-3'.
## 3. VOI radiums, in mm. E.g., '6'
## 4. Results folder. The name of the folder (in the subjects'
##    directory) that contains the SPM file of interest. E.g., 
##    'results'.
## 5. Contrast for adjusting. This is the contrast that is used to 
##    adjust the time series before extracting the data. This should
##    be the 'Effects of Interest', omnibus F interaction.
## 6. Contrast number. The number (in SPM order) of the contrast
##    used to identify the VOI.
## 7. Threshold. The statistical threshold (0 < T < 1) at which the
##    voxel values are filtered.
## 8. Location. A binary value, determining whether the location of
##    of the VOI is fixed (0) or it is moved to closest activation
##    peak (1).
## ---------------------------------------------------------------- ##

HLP_MSG='
 Usage:                                                               \n
                                                                      \n
   $ dcm-generate-vois.sh <VOI_file> <subj1> <subj2> ... <subjN>      \n
                                                                      \n
 Where:                                                               \n
   <VOIfile>: A VOI description file (see below)                      \n
   <subjXX> : the name of a subject folder.                           \n
                                                                      \n
 The VOI File Format                                                  \n
 -------------------                                                  \n
 The VOI file is a text table file. Each VOI is a row in the table,   \n
 and each column is an attribute of the VOI. Rows in the table        \n
 correspond to text lines (e.g., separated by line feeds) and cells   \n
 in the table correspond to REGEX words (that is, they are separated  \n
 by white space characters, such as spaces or tabs).                  \n
                                                                      \n
 Each line contains the following values, separated by spaces or tabs:\n
                                                                      \n
 1. VOI NAME, e.g., "LPFC"                                            \n
 2. MNI COORDINATES, separated by ",", with no spaces between         \n
    coordinates. E.g., "42,-44,-3".                                   \n
 3. VOI RADIUS, in mm. E.g., "6".                                     \n
 4. RESULTS FOLDER. The name of the folder (in the subjects           \n
    directory) that contains the SPM file of interest. E.g.,          \n
    "results".                                                        \n
 5. ADJUSTING CONTRAST NUMBER. This is the contrast that is used to   \n
    adjust the time series before extracting the data. This should    \n
    be the "Effects of Interest", omnibus F interaction.              \n
 6. EXTRACTION CONTRAST NUMBER. The number (in SPM order) of the      \n
    contrast used to identify the VOI.                                \n
 7. THRESHOLD. The statistical threshold (0 < T < 1) at which the     \n
    voxel values are filtered.                                        \n
 8. LOCATION TYPE. A binary value, determining whether the location   \n
    of the VOI is fixed (0) or it is moved to closest activation      \n
    peak (1).                                                         \n
                                                                      \n
Usage:                                                                \n
                                                                      \n
   $ dcm-generate-vois.sh <VOI_file> <subj1> <subj2> ... <subjN>.     \n'


VOI_FILE=$1
#MFILE=`pwd`/create_vois_${VOI_FILE}_`date +%Y_%m_%d_%H%M`.m
BASE_DIR="`pwd`"
NL="
"   # new line
SEP="---------------------------------------------------------------------"

if [ $# -lt 1 ]; then
    echo -e $HLP_MSG >&2
    exit
fi
if [ -e ${VOI_FILE} ]; then
    echo "% DCMs for $@"

    #unset $@[1]  # Remove the first thing---it's the file
    shift;
    for subj in $@; do
	echo "Matlab code for subject $subj" >&2
	while read voi_info; do
	    
	    #Read region by region
	    name=`echo ${voi_info} | awk '{print $1}'`
	    coordinates=`echo ${voi_info} | awk '{print $2}'`
	    radius=`echo ${voi_info} | awk '{print $3}'`
	    results_dir=`echo ${voi_info} | awk '{print $4}'`
	    contrast_adj=`echo ${voi_info} | awk '{print $5}'`
	    contrast_num=`echo ${voi_info} | awk '{print $6}'`
	    threshold=`echo ${voi_info} | awk '{print $7}'`
	    moveable=`echo ${voi_info} | awk '{print $8}'`
	    #contrast="GoNoGo"
	    echo "    matlab code for region ${name}" >&2
	    # Get the specific coordinates
	    x=`echo ${coordinates} | cut -f1 -d,`
	    y=`echo ${coordinates} | cut -f2 -d,`
	    z=`echo ${coordinates} | cut -f3 -d,`

	    echo "% EXTRACTING TIME SERIES: ${name}"
	    echo "%${SEP}"
	    echo "clear matlabbatch"
	    echo "disp('Creating ROI ${name} for subject ${subj}')"
	    echo "matlabbatch{1}.spm.util.voi.spmmat = cellstr(fullfile('${BASE_DIR}', '${subj}', '${results_dir}', 'SPM.mat'));"
	    echo "matlabbatch{1}.spm.util.voi.adjust = ${contrast_adj};  % Effects of Interest"
	    echo "matlabbatch{1}.spm.util.voi.session = 1; % Session 1 (no others)"
	    echo "matlabbatch{1}.spm.util.voi.name = '${name}';"
	    echo "matlabbatch{1}.spm.util.voi.roi{1}.spm.spmmat = {''}; % using SPM.mat above"
	    echo "matlabbatch{1}.spm.util.voi.roi{1}.spm.contrast = ${contrast_num};  % The contrast used to identify the VOI"
	    echo "matlabbatch{1}.spm.util.voi.roi{1}.spm.threshdesc = 'none'; % Uncorrected"
	    echo "matlabbatch{1}.spm.util.voi.roi{1}.spm.thresh = ${threshold}; % The threshold" 
	    echo "matlabbatch{1}.spm.util.voi.roi{1}.spm.extent = 0; % No voxel limit"
	    echo "matlabbatch{1}.spm.util.voi.roi{2}.sphere.centre = [${x} ${y} ${z}]; % Seed point"
	    echo "matlabbatch{1}.spm.util.voi.roi{2}.sphere.radius = ${radius};"
	    
	    if [ ${moveable} -eq 1 ]; then
		echo "matlabbatch{1}.spm.util.voi.roi{2}.sphere.move.local.spm = ${moveable}; % Move to local max"
		echo "matlabbatch{1}.spm.util.voi.roi{2}.sphere.move.global.mask = ''; % none"
	    fi

	    echo "matlabbatch{1}.spm.util.voi.expression = 'i1 & i2'; % Not sure why but it's needed" 
	    echo "spm_jobman('run',matlabbatch);"

	done < $VOI_FILE
    done
else
    echo "VOI file does not exist: $1" >&2
fi
