#!/bin/bash

RSDIR="/projects/commonModel/code/ROI_Masks/OptimizedMaps"

for subject in `ls -d [0-9][0-9][0-9][0-9][0-9][0-9]`; do
    #echo "Subject $subject"
    if [ -e ${subject}/dcm_results/VOI_Action_mask.nii ]; then
	# Run only if there are DCM VOIs for subjec
	cd ${subject}/dcm_results
	for voi in Action LTM Perception Procedural WM; do
	    vsize=`3dBrickStat -sum VOI_${voi}_mask.nii | xargs`

	    # rename vois to lowercase
	    voiname=${voi,,}

	    # rename "action" to "motor"
	    if [ $voiname == "action" ]; then
		voiname="motor"
	    fi
	    
	    
	    # Calculate intersection
	    3dcalc -a VOI_${voi}_mask.nii \
		   -b ${RSDIR}/${voiname}_optimized_mask.nii \
		   -expr "a * b" \
		   -prefix rs_intersection.nii

	    # Count number of voxels
	    intsize=`3dBrickStat -sum rs_intersection.nii | xargs`

	    # Remove intersection img
	    rm rs_intersection.nii

	    # Spit out the report data
	    echo "${subject},${voi},${vsize},${intsize}"
	done
	cd ../..
    fi
done
