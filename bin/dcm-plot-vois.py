#!/usr/bin/env python

import nilearn
from nilearn import plotting
from matplotlib.pyplot import cm
from matplotlib.colors import to_rgba
import numpy
from numpy import linspace
import sys


HLP_MSG="""
Usage
-----
  $ dcm-plot-vois.sh <voi_xyz_1> <voi_xyz_2> .. <voi_xyz_M>

Where:
   
  <voi_xyz_X> is the text file containing the subject-by-subject
    coordinates of each voi, as returned by the extract-voi-data.sh
    script.

The script will generate a single PNG file, named 'vois.png', with 
the position of each individual VOI coordinate marked inside a glass 
brain. Each VOI will be marked in a different color.
"""

if __name__ == "__main__":

    if len(sys.argv[1:]) == 0:
        print(HLP_MSG)
    else:
        vois = {}
        for filename in sys.argv[1:]:
    
            # Opens file and extract MNI coordinates
            # ----------------------------------------------------------
    
            f = open(filename, "r")
            tokens = [line.split() for line in f.readlines()[1:]]
            coords = [x[2:5] for x in tokens]
            mni = [[float(y) for y in x] for x in coords]
            name = tokens[0][1]
            vois[name] = mni

    
        #cols = cm.tab10(linspace(0,1,len(vois.keys())))
        #cols = cm.rainbow(linspace(0,1,len(vois.keys())))
        #cols = cm.brg(linspace(0,1,len(vois.keys())))
        cols = [list(to_rgba(x)) for x in ["#cc00cc", "#ff9900", "#ff3333", "#00cc33", "#00ccff"]]

        # Adds transparency
        # ----------------------------------------------------------
        
        for c in cols:
            c[3] = 0.5  # Sets alpha
            
            
        # Plots and saves
        # ----------------------------------------------------------
            
        # Calculates the proper size of the marker
        L = [len(vois[x]) for x in vois.keys()]
        N = numpy.max(L)
        
        msize = 100

        if N < 20:
            msize = 50
        elif N < 50:
            msize = 25
        elif N < 100:
            msize = 10
        else:
            msize = 10

        print("L=%s, N=%s, msize=%d" % (L, N, msize))


        display=plotting.plot_glass_brain(None)
        for i, v in enumerate(sorted(vois.keys())):
            display.add_markers(vois[v], marker_color=cols[i],
                                marker_size=msize, marker="+")

        display.savefig("vois.png", dpi=300)
        display.close()


# End 
