#!/usr/bin/env python

import nilearn
import matplotlib
from nilearn import plotting
from nilearn import datasets
from nilearn import surface
from nilearn import image
from matplotlib.colors import to_rgba
import matplotlib.pyplot as plt
import string

fs = datasets.fetch_surf_fsaverage5()
#fs = datasets.fetch_surf_nki_enhanced()


tasks = ["Emotion", "Social", "Relational", "WM", "Language", "Gambling"]
task_names = {"Emotion" : "Emotion Processing",
              "Social" : "Social Cognition",
              "Relational" : "Relational Reasoning",
              "WM" : "Working Memory",
              "Language" : "Language & Math",
              "Gambling" : "Incentive Processing"}

cols = [list(to_rgba(x)) for x in \
        ["#cc00cc", "#ff9900", "#ff3333", "#00cc33", "#00ccff"]]

VOIS = ['Action', 'LTM', 'Perception', 'Procedural', 'WM']


#statmap = plt.get_cmap("inferno")
#statmap = plt.get_cmap("cividis")
#statmap = plt.get_cmap("plasma")
#statmap = plt.get_cmap("summer")
#statmap = plt.get_cmap("cool")
#statmap = plt.get_cmap("bone")
#statmap = plt.get_cmap("cubehelix")
statmap = plt.get_cmap("PuOr")
#statmap = plt.get_cmap("hot_white_bone_r")
statmap = plt.get_cmap("Spectral")
statmap = plt.get_cmap("hot_white_bone")


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


fig = plt.figure(figsize=(6,10))


for i, d in enumerate(sorted(tasks)):
    print("loading: " + d)
    ax = plt.subplot(3, 2, (i+1))
    #img = image.threshold_img(d+"/spmT_0001.nii", threshold=7.0)
    #img = image.threshold_img(d+"/spmT_0001.nii",)
    img = image.load_img(d+"/spmT_0001.nii")
    data = img.get_data()
    data[data < 0] = 0.0  # Remove negative values
    img = image.smooth_img(img, fwhm=4)

    gb = plotting.plot_glass_brain(img, display_mode="l",
                                   axes=ax, vmax=30, vmin=0,
                                   title="%s" % d, colorbar = False, #(i == 1),
                                   cmap=statmap)

    #print(load_vois(d))
    vois = load_vois(d)
    print(vois)

    # Order them
    coords = [vois[name] for name in VOIS]

    gb.add_markers(coords,
                   marker_color = cols,
                   marker_size = 60,
                   marker = "o")

    
plt.savefig("uberfigure.png")

fig = plt.figure(figsize=(24, 18))


for i, d in enumerate(sorted(tasks)):
    print("loading: " + d)
    ax = plt.subplot(3, 4, (2*i+1))
    #img = image.threshold_img(d+"/spmT_0001.nii", threshold=7.0)
    #img = image.threshold_img(d+"/spmT_0001.nii",)
    img = image.load_img(d+"/spmT_0001.nii")
    data = img.get_data()
    data[data < 0] = 0.0  # Remove negative values
    img = image.smooth_img(img, fwhm=4)
        

    # Task-Related activity
    
    gb = plotting.plot_glass_brain(img, display_mode="l",
                                   axes=ax, vmin=0, vmax=30,
                                   title="%s" % d, colorbar = False, #(i == 1),
                                   cmap=statmap)

    #print(load_vois(d))
    vois = load_vois(d)
    #print(vois)

    # Order them
    coords = [vois[name] for name in VOIS]

    gb.add_markers(coords,
                   marker_color = cols,
                   marker_size = 120,
                   marker = "o")


    # Individual locations

    ax = plt.subplot(3, 4, (2*i+2))
    
    gb = plotting.plot_glass_brain(img,
                                   display_mode="l",
                                   axes=ax, cmap=statmap,
                                   title="%s" % d, colorbar = False, #(i == 1),
                                   )

    coords = load_individual_coords(d)
    for ii, voi in enumerate(VOIS):
        gb.add_markers(coords[voi], marker_color=cols[ii],
                       marker="+", marker_size=5)
    
plt.savefig("uberfigure2.png")


fig = plt.figure(figsize=(16, 8))


for i, d in enumerate(sorted(tasks)):
    print("loading: " + d)
    # ax = plt.subplot(2, 3, (i+1))
    img = image.load_img(d + "/spmT_0001.nii")
    data = img.get_data()
    data[data < 0] = 0.0  # Remove negative values
    img = image.smooth_img(img, fwhm=4)
        

     # Individual locations

    ax = plt.subplot(2, 3, (i+1))
    gb = plotting.plot_glass_brain(img, vmin=0.0,
                                   display_mode="l",
                                   axes=ax, cmap=statmap,
                                   colorbar = True, #(i == 1),
                                   )
    coords = load_individual_coords(d)
    N = [len(x) for x in coords.values()][0]

    for ii, voi in enumerate(VOIS):
        gb.add_markers(coords[voi], marker_color=cols[ii],
                       marker="+", marker_size=40)

    font = {'fontname' : 'FreeSans',
            'fontweight' : 'bold',
            'fontsize' : 20}

    #ax.set_title("(%s) %s\n" % (string.ascii_uppercase[i], task_names[d]) 
    #             + r"$N = %d$" % (N), **font)

    ax.set_title("(%s) %s\nN = %d" % (string.ascii_uppercase[i], task_names[d], N),
                 **font)
    
    #plt.rcParams['font.family']=['FreeSans']


## T
    
plt.savefig("uberfigure3.png")
