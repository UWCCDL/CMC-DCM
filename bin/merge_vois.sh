#!/bin/bash

for subject in `ls -d [0-9][0-9][0-9][0-9][0-9][0-9]`; do
    echo "Subject $subject"
    if [ -e ${subject}/dcm_results/VOI_Action_mask.nii ]; then
	# Run only if there are DCM VOIs for subjec6
	
	if [ ! -e VOI_Action_mask_sum.nii ]; then
	    # Create base sum VOIs, if they do not not exist,
	    # by coping those of the first subject
	    
	    for voi in Action LTM Perception Procedural WM; do
		cp ${subject}/dcm_results/VOI_${voi}_mask.nii \
		   VOI_${voi}_mask_sum.nii
	    done
	else
	    # If we have sum VOIs, then we can just add the subject's 
	    # vois to the sums.
	    
	    for voi in Action LTM Perception Procedural WM; do
		3dcalc -a ${subject}/dcm_results/VOI_${voi}_mask.nii \
		       -b VOI_${voi}_mask_sum.nii \
		       -expr "a + b" \
		       -prefix partial_sum.nii

		mv partial_sum.nii VOI_${voi}_mask_sum.nii
	    done
	fi
    fi
done

	
