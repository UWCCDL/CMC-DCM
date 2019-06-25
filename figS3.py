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

font = {'fontname' : 'FreeSans', 'fontweight' : 'normal', 'fontsize' : 10}

f, axes = plt.subplots(6, 4, figsize=(8,9),
                       subplot_kw={'projection': '3d'})

for ii, d in enumerate(sorted(tasks)):
    print("loading... " + d)
    #img = image.threshold_img(d+"/spmT_0001.nii", threshold=7.0)
    #img = image.threshold_img(d+"/spmT_0001.nii",)
    img = image.load_img(d+"/spmT_0001.nii")
    data = img.get_data()
    data[data < 0] = 0.0# Remove negative values
    img = image.smooth_img(img, fwhm=2)

    
    texture2 = surface.vol_to_surf(img, # d+"/spmT_0001.nii", #img,
                                   fs.pial_left)

    texture1 = surface.vol_to_surf(img, #d+"/spmT_0001.nii", #img
                                   fs.pial_right)


    jj = 0
    for views in [("left", "lateral"), ("left", "medial"),
                  ("right", "medial"), ("right", "lateral")]:

        hemi, view = views
        
        bmap = fs.sulc_left
        infl = fs.infl_left
        txt = texture2
        if hemi == "right":
            bmap = fs.sulc_right
            infl = fs.infl_right
            txt = texture1
        
        plotting.plot_surf_stat_map(infl, txt, hemi = hemi,
                                    colorbar = True, view = view,
                                    bg_map = bmap,
                                    alpha = 0.75, axes = axes[ii,jj],
                                    title = "%s, Left" % d)
        if jj == 0:
            axes[ii,jj].set_title("%s\n%s %s" % (task_names[d],
                                                 hemi.title(),
                                                 view.title()),
                                  **font)
        else:
            axes[ii,jj].set_title("\n%s %s" % (hemi.title(), view.title()),
                                  **font)
        jj += 1

plt.savefig("AllVisuals.png")
