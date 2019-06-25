#!/bin/bash
# ------------------------------------------------------------------ #
# DCM-GENERATE-FIRST-LEVEL
# ------------------------------------------------------------------ #
# Generates a 1st level model SPM/Matlab script, which is output on
# the terminal and can be saved on a .m file.
# ------------------------------------------------------------------
# Usage
# -----
#
#   $ dcm-generate-first-level.sh [param_file] <results_dir> 
#                             <contrast_file>
#                             <subj1> <subj2>...<subjN>
#
# Where:
#   
#   [param_file] is an optional parameter file (see below)
#   <results_dir> is the folder where the SPM.mat file will be
#                 placed for each subject (it needs to already exist)
#                 in each subject's folder. 
#   <contrast_file> is a file listing all the contrast names and their
#                   vectors, separated by ":" 
#   <subjX> is the name of a subject's data directory.
# 
# # Parameter File
# --------------
# A parameter file is a text file that contains preprocessing 
# parameters, one per line, in the form <PARAM> = <VALUE>. The 
# following parameters are read by this script (everything else
# is ignored).
# 
#   * TR: the repetition time.  By default, TR = 2.
#
#   * CONTRAST_MANAGMENT: Specifies the way SPM should handle the
#     contrast vector. These are the options:
#
#     1. none   : Will just use the vector. This is the ideal option
#                 when you have special vectors that already span
#                 multiple contrasts.
#     2. repl   : Will replicate the vector across session, but 
#                 *not* scale it.
#     3. replsc : Will replicate AND scale the contrasts across 
#                 multiple sessions (this is the default behavior)
#   
#   * HPF: Specifies the value of the High-pass filter in SPM 
#     (in seconds). Can be any positive number; by default it is
#     HPF = 128
#
# Contrast File
# --------------
# A contrast file is a text file that contains contrast names and 
# vector values, one per line, in the form <NAME> : <VECTOR>. For 
# example:
# 
#   Words > Pictures : 0 0 -0.5 -0.5 0 0.5 0.5 
#   Pictures > Words : 0 0 0.5 0.5 0 -0.5 -0.5 
#   ....
#
# The script assumes that the same contrast vector is used for
# each session, and will use SPM's "Replicate&Scale" option when
# generating the contrasts. In some studies, this is not the case,
# so the script cannot be used.
# 
# ------------------------------------------------------------------ #
# Notes
# -----
# 
# The script assumes the data are organized according to the CCDL's 
# standard format,i.e.:
#
#  1. The root folder for each experiment EXP is located in
#    /fmri/data/<PROJECT>/<EXP>;
#
#  2. The data for each subject is contained in folder that has
#    the same name as the subject;
#    
# In addition, the script assumes that 
#   
#  3. the contrast vector can be replicated and scaled across 
#    sessions.
#
# Do not use the script unless all of the above assumptions are true.
# ------------------------------------------------------------------ #
#
# History
# -------
#
#  2015-12-10 : Forked from generate-first-level.sh
#
# ------------------------------------------------------------------ #

HLP_MSG="
 Usage
 -----

   $ dcm-generate-first-level.sh [param_file] <results_dir> 
                             <contrast_file>
                             <subj1> <subj2>...<subjN>

 Where:
   
   [param_file] is an optional parameter file (see below)
   <results_dir> is the folder where the SPM.mat file will be
                 placed for each subject (it needs to already exist)
                 in each subject's folder. 
   <contrast_file> is a file listing all the contrast names and their
                   vectors, separated by ":" 
   <subjX> is the name of a subject's data directory.
 
 Parameter File
 --------------
 A parameter file is a text file that contains preprocessing 
 parameters, one per line, in the form <PARAM> = <VALUE>. The 
 following parameters are read by this script (everything else
 is ignored).
 
   * TR: the repetition time.  By default, TR = 2.

   * CONTRAST_MANAGMENT: Specifies the way SPM should handle the
     contrast vector. These are the options:

     1. none   : Will just use the vector. This is the ideal option
                 when you have special vectors that already span
                 multiple contrasts.
     2. repl   : Will replicate the vector across session, but 
                 *not* scale it.
     3. replsc : Will replicate AND scale the contrasts across 
                 multiple sessions (this is the default behavior)

   * HPF: Specifies the value of the High-pass filter in SPM 
     (in seconds). Can be any positive number; by default it is
     HPF = 128

   * MOTION_REGRESSORS: Specifies whether to include (=1) or not
     (=1) the motion parameters as additional regressors. Default
     is MOTION_REGRESSORS = 0.

 Contrast File
 --------------
 A contrast file is a text file that contains contrast names and 
 vector values, one per line, in the form <NAME> : <VECTOR>. For 
 example:
 
   Words > Pictures : 0 0 -0.5 -0.5 0 0.5 0.5 
   Pictures > Words : 0 0 0.5 0.5 0 -0.5 -0.5 
   ....

 The script assumes that the same contrast vector is used for
 each session, and will use SPM's 'Replicate&Scale' option when
 generating the contrasts. In some studies, this is not the case,
 so the script cannot be used.
 
 Notes
 -----
 
 The script assumes the data are organized according to the CCDL's 
 standard format,i.e.:

  1. The root folder for each experiment EXP is located in
     /fmri/data/<PROJECT>/<EXP>;

  2. The data for each subject is contained in folder that has
     the same name as the subject;
    
 In addition, the script assumes that:
   
  3. the contrast vector can be replicated and scaled across 
     sessions.

 Do not use the script unless all of the above assumptions are true.

 Summary
 -------

   $ dcm-generate-first-level.sh [param_file] <results_dir> 
                             <contrast_file>
                             <subj1> <subj2>...<subjN>

"

# ------------------------------------------------------------------ #
# General variabls
# ------------------------------------------------------------------ #

TR=2.0
CONTRAST_MANAGEMENT=replsc
HPF=256
MOTION_REGRESSORS=0
FUNC_FOLDER=raw
STRUCT_FOLDER=struct

# ------------------------------------------------------------------ #
# Load params (if any)
# ------------------------------------------------------------------ #

if [ $# -gt 0 ]; then
    if [ -f $1 ]; then
	param_file=$1
        # If the first argument is a file, it must be a parameter file
	echo "Found parameter file $param_file" >&2

        # Check the TR
	if grep -q "TR" $param_file; then
	    TR=`grep '^TR' ${param_file} | cut -f2 -d= | tail -1 | tr -d " '"`
	    echo "  Setting TR to $TR" >&2 
	fi

	# Check what to do with contrasts
	if grep -q "CONTRAST_MANAGEMENT" $param_file; then
	    CONTRAST_MANAGEMENT=`grep '^CONTRAST_MANAGEMENT' ${param_file} | cut -f2 -d= | tail -1 | tr -d " '"`
	    echo "  Setting CONTRAST_MANAGEMENT to $CONTRAST_MANAGEMENT" >&2 
	fi

	# Check the value of HPF
	if grep -q "HPF" $param_file; then
	    HPF=`grep '^HPF' ${param_file} | cut -f2 -d= | tail -1 | tr -d " '"`
	    echo "  Setting HPF to $HPF" >&2 
	fi

	# Check whether to include motion parameters
	if grep -q "MOTION_REGRESSORS" $param_file; then
	    MOTION_REGRESSORS=`grep '^MOTION_REGRESSORS' ${param_file} | cut -f2 -d= | tail -1 | tr -d " '"`
	    echo "  Setting MOTION_REGRESSORS to $MOTION_REGRESSORS" >&2 
	fi
	
	if grep -q "^FUNC_FOLDER" $param_file; then
	    FUNC_FOLDER=`grep "^FUNC_FOLDER" ${param_file} | cut -f2 -d= | tail -1 | tr -d ' '`
	    echo "  Setting parameter FUNC_FOLDER = $FUNC_FOLDER" >&2
	fi
	
	if grep -q "^STRUCT_FOLDER" $param_file; then
	    STRUCT_FOLDER=`grep "^STRUCT_FOLDER" ${param_file} | cut -f2 -d= | tail -1 | tr -d ' '`
	    echo "  Setting parameter STRUCT_FOLDER = $STRUCT_FOLDER" >&2
	fi

        # Finally, skip the first argument
	shift 1
    fi
fi

# ------------------------------------------------------------------ #
# Print instructions, if not enough args
# ------------------------------------------------------------------ #

if [ $# -lt 3 ]; then
    IFS=''
    echo -e $HLP_MSG >&2
    unset IFS
    exit
fi


results_dir=$1
c_file=$2
shift 2

base=`pwd`
J=1

for subj in "$@" ; do
    echo "Generating model for $subj" >&2
    [ -d $subj ] || continue
    cd ${subj}/${FUNC_FOLDER}
    
    echo "matlabbatch{$J}.spm.stats.fmri_spec.timing.units = 'secs';"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.timing.RT = ${TR};"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.timing.fmri_t = 16;"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.timing.fmri_t0 = 1;"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.dir = {'${base}/${subj}/${results_dir}/'}"

    S=1
    
    echo "matlabbatch{$J}.spm.stats.fmri_spec.sess($S).scans = {"

    # Merge all sessions.

    for session in `ls sw*.nii`; do
	
	#N=`echo $session | cut -f1 -d. | tail -c 4`
	#N=`fslinfo $session | grep "^dim4" | awk '{print $2}'`
	N=`niftidims.py $session | awk '{print $4}'`
	#N=$(echo $N | sed 's/^0*//')   # Removed leading zeroes
	
	# Note that this loops stops at image<=N, not image<N,
	# because the number of volumes comes from the header
	for ((image=1; image<=N; ++image)); do 
	    echo "'${base}/${subj}/${FUNC_FOLDER}/${session},${image}'"
	done
    done

    echo "};"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.sess($S).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.sess($S).multi = {'${base}/${subj}/behav/sessions_dcm.mat'};"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.sess($S).regress = struct('name', {}, 'val', {});"

    # for k in sessions
    K=1
    NS=`ls sw*.nii | wc | awk '{print $1}'`
    NS=$((NS - 1))
    # If NS > 0; else regressors is empty
    # for (, i < NS, i++)
    for ((s=1; s<=NS; ++s)); do 
	echo "matlabbatch{$J}.spm.stats.fmri_spec.sess.regress($K).name = 'Session $s';"
	echo -n "matlabbatch{$J}.spm.stats.fmri_spec.sess.regress($K).val = ["
	k=0
	for sess in `ls sw*.nii`; do
	    k=$((k + 1))
	    #L=`fslinfo $sess | grep "^dim4" | awk '{print $2}'`
	    L=`niftidims.py $sess | awk '{print $4}'`
	    if [ "$k" == "$s" ]; then
		echo -n "ones(1,$L),"
	    else
		echo -n "zeros(1,$L),"
	    fi
	done
	echo "];"
	K=$((K+1))
    done
  
    echo "matlabbatch{$J}.spm.stats.fmri_spec.sess.multi_reg = {''};"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.sess($S).hpf = ${HPF};"
	
    S=$((S+1))
    
    echo "matlabbatch{$J}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.volt = 1;"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.global = 'None';"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.mask = {''};"
    echo "matlabbatch{$J}.spm.stats.fmri_spec.cvi = 'AR(1)';"
    
    cd ../../
    J=$((J+1))

    echo -e "\n % Estimate\n"
    
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1) = cfg_dep;"
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1).tname = 'Select SPM.mat';"
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).name = 'filter';"
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).value = 'mat';"
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).name = 'strtype';"
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).value = 'e';"
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1).sname = 'fMRI model specification: SPM.mat File';"
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1).src_exbranch = substruct('.','val', '{}',{$((J-1))}, '.','val', '{}',{1}, '.','val', '{}',{1});"
    echo "matlabbatch{$J}.spm.stats.fmri_est.spmmat(1).src_output = substruct('.','spmmat');"
    echo "matlabbatch{$J}.spm.stats.fmri_est.method.Classical = 1;"
    
    J=$((J+1))
    
    echo -e "\n% Contrast manager"
    
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1) = cfg_dep;"
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1).tname = 'Select SPM.mat';"
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1).tgt_spec{1}(1).name = 'filter';"
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1).tgt_spec{1}(1).value = 'mat';"
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1).tgt_spec{1}(2).name = 'strtype';"
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1).tgt_spec{1}(2).value = 'e';"
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1).sname = 'Model estimation: SPM.mat File';"
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1).src_exbranch = substruct('.','val', '{}',{$((J-1))}, '.','val', '{}',{1}, '.','val', '{}',{1});"
    echo "matlabbatch{$J}.spm.stats.con.spmmat(1).src_output = substruct('.','spmmat');"
    
    C=1
    while read line; do
	cname=`echo $line | cut -f1 -d:`
	cvector=`echo $line | cut -f2 -d:`
	echo "matlabbatch{$J}.spm.stats.con.consess{$C}.tcon.name = '${cname}';"
	echo "matlabbatch{$J}.spm.stats.con.consess{$C}.tcon.convec = [${cvector}];"
	echo "matlabbatch{$J}.spm.stats.con.consess{$C}.tcon.sessrep = '${CONTRAST_MANAGEMENT}';"
	C=$((C+1))
	
    done < ${c_file}
    
    # Add F-contrast Effects of Interest
    echo "matlabbatch{$J}.spm.stats.con.consess{$C}.fcon.name = 'EoI';"
    echo "matlabbatch{$J}.spm.stats.con.consess{$C}.fcon.convec = {"
    echo "                                                        eye($((C-1)))"
    echo "                                                       };"

    echo "matlabbatch{$J}.spm.stats.con.consess{$C}.fcon.sessrep = 'none';"
    echo "matlabbatch{$J}.spm.stats.con.delete = 1;"
    
    J=$((J+1))
    
done

