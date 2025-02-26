#!/usr/bin/env python

import nilearn
from nilearn import plotting
from nilearn import datasets
from nilearn import surface
from nilearn import image
import matplotlib.pyplot as plt
from matplotlib.colors import to_rgba
import numpy as np

VOIS = ['Action', 'LTM', 'Perception', 'Procedural', 'WM']

COLS = [list(to_rgba(x)) for x in \
        ["#cc00cc", "#ff9900", "#ff3333", "#00cc33", "#00ccff"]]


def load_vois(task):
    f = open("%s/vois.txt" % task)
    vois = {}
    for line in f.readlines():
        name, coords = line.split()[:2]
        xyz = [int(x) for x in coords.split(",")]
        vois[name] = xyz
    
    return vois


def load_individual_coords(task):
    vdict = {}
    for voi in VOIS:
    
        # Opens file and extract MNI coordinates
        # ----------------------------------------------------------
        
        f = open("%s/%s_xyz.txt" % (d, voi), "r")
        tokens = [line.split() for line in f.readlines()[1:]]
        coords = [x[2:5] for x in tokens]
        mni = [[float(y) for y in x] for x in coords]
        name = tokens[0][1]
        vdict[name] = mni

    return vdict


fs = datasets.fetch_surf_fsaverage5()
#fs = datasets.fetch_surf_nki_enhanced()

for d in ["Emotion", "Social", "Relational", "WM", "Language", "Gambling"]:
    print("loading... " + d)
    #img = image.threshold_img(d+"/spmT_0001.nii", threshold=7.0)
    #img = image.threshold_img(d+"/spmT_0001.nii",)
    img = image.load_img(d+"/spmT_0001.nii")
    data = img.get_data()
    data[data < 0] = 0.0# Remove negative values
    img = image.smooth_img(img, fwhm=4)
    
    texture2 = surface.vol_to_surf(img, # d+"/spmT_0001.nii", #img,
                                   fs.pial_left)

    texture1 = surface.vol_to_surf(img, #d+"/spmT_0001.nii", #img
                                   fs.pial_right)

    plotting.plot_surf_stat_map(fs.infl_left, texture2, hemi="left",
                                colorbar=True, view="lateral",
                                bg_map=fs.sulc_left,
                                alpha=0.75,
                                title = "%s, Left" % d,
                                output_file="%s_left.png" % (d))

    plotting.plot_surf_stat_map(fs.infl_right, texture1,
                                colorbar=True, view="medial",
                                bg_map = fs.sulc_right,
                                alpha=0.75,
                                title = "%s, Right" % d,
                                output_file="%s_right.png" % (d))

    #p=plotting.plot_surf_stat_map(fs.infl_right, texture1,
    #                            colorbar=True, view="medial",
    #                            bg_map = fs.sulc_right,
    #                            alpha=0.75,
    #                            title = "%s, Right" % d)

    
    #p.add_markers([(-20,-30,-78)])
    #p.savefig("test_%s.png" % (d,))

    p=plotting.plot_stat_map(d+"/spmT_0001.nii", # img,
                             display_mode="xz",
                             threshold=.1,
                             #cut_coords=(10,15,20),
                             vmax=10)
    
    p.savefig("%s_xz.png" % (d))
    p.close()

    p=plotting.plot_glass_brain(d + "/spmT_0001.nii", # img,
                                display_mode="l",
                                threshold=7,
                                #cmap=plt.get_cmap("PuOr"),
                                #cut_coords=(10,15,20),
                                #vmin=10,
                                vmax=30)
    
    p.savefig("%s_gb_left.png" % (d))

    gb=plotting.plot_glass_brain(d + "/spmT_0001.nii", # img,
                                display_mode="l",
                                threshold=7,
                                cmap=plt.get_cmap("magma"),
                                #vmin=7
                                vmax=30)

    vois = load_vois(d)
    #print(vois)

    # Order them
    coords = [vois[name] for name in VOIS]

    gb.add_markers(coords,
                   marker_color = COLS,
                   marker_size = 120,
                   marker = "o")
    gb.savefig("%s_gb_left_group_markers.png" % (d))
    gb.close()
    
    ## All markers only

    gb=plotting.plot_glass_brain(d + "/spmT_0001.nii", # img,
                                 display_mode="l",
                                 threshold = np.max(data) * .9)
    #cmap=plt.get_cmap("PuOr"),
    #cut_coords=(10,15,20),
    #vmin=10,

    coords = load_individual_coords(d)
    for ii, voi in enumerate(VOIS):
        gb.add_markers(coords[voi], marker_color=COLS[ii],
                       marker="+", marker_size=40)
    gb.savefig("%s_gb_left_individual_markers.png" % (d))
    gb.close()



# Get a neutral empty Left view:

gb=plotting.plot_glass_brain("Relational/spmT_0001.nii", # img,
                             display_mode="l",
                             threshold=35.5,
                             cmap=plt.get_cmap("magma"),
                             #vmin=7
                             vmax=35.5)

gb.add_markers([(-2,-2,-2)], marker_color="white",
                       marker="+", marker_size=40)

gb.savefig("leftview")
gb.close()


for d in ["Emotion", "Social", "Relational", "WM", "Language", "Gambling"]:
    print("loading... " + d)
    #img = image.threshold_img(d+"/spmT_0001.nii", threshold=7.0)
    #img = image.threshold_img(d+"/spmT_0001.nii",)
    img = image.load_img(d+"/spmT_0001.nii")
    data = img.get_data()
    data[data < 0] = 0.0# Remove negative values
    img = image.smooth_img(img, fwhm=4)
    
    texture2 = surface.vol_to_surf(img, # d+"/spmT_0001.nii", #img,
                                   fs.pial_left)

    texture1 = surface.vol_to_surf(img, #d+"/spmT_0001.nii", #img
                                   fs.pial_right)

    plotting.plot_surf_stat_map(fs.infl_left, texture2, hemi="left",
                                colorbar=True, view="lateral",
                                bg_map=fs.sulc_left,
                                alpha=0.75,
                                title = "%s, Left" % d,
                                output_file="%s_left.png" % (d))

    plotting.plot_surf_stat_map(fs.infl_right, texture1,
                                colorbar=True, view="medial",
                                bg_map = fs.sulc_right,
                                alpha=0.75,
                                title = "%s, Right" % d,
                                output_file="%s_right.png" % (d))
