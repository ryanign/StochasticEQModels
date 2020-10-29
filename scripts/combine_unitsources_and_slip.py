#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Oct 29 15:21:57 2020

@author: ryanign
To combine unit sources and stochastic slip.

"""
import numpy as np
import os

maindir = "../"
faults = "MksThrust_Central"
targetMw = 7.7

nsbf = 10    ## number of subfaults
nsce = 5   ## number of scenarios that you want to combine
nstrike = 5  ## number of subfaults along strike
ndip    = 2  ## number of subfaults long downdip

unitsource = os.path.join(maindir,"outputs","Unit_source_data",
                              faults+"_contours")
outdir = os.path.join(maindir,"outputs","ori_displacement_grid")

sbf = 1
for stk in range(nstrike):
    for dip in range(ndip):
        unitsourcefile = faults + "_contours_" + "%i" % (dip+1) + "_" + \
            "%i" % (stk+1) + ".tif"
            
        infile = os.path.join(unitsource,unitsourcefile)
        os.system("gdal_translate %s -of NetCDF tmp.grd" % infile)
        outfile = "disp_" + faults + "_%i.grd" % (sbf)
        outfiled = os.path.join(outdir,outfile)
        os.system("cp tmp.grd %s" % outfiled)
        
        sbf += 1
        
for sce in range(nsce):
    print("Scenario %i" % (sce+1))
    infile = "%s_contours_Mw%2.1f_Scenarios_%i.csv" % (faults,targetMw,(sce+1))
    fsbf = os.path.join(maindir,"stochastic",infile)
    data = np.loadtxt(fsbf,delimiter=",",skiprows=1)
    slip = data.transpose().flatten()
    
    dispdir = os.path.join(maindir,"outputs","ori_displacement_grid")     
    
    disp0 = os.path.join(dispdir,"disp_%s_1.grd" % faults)       
    os.system("gmt grdmath %s 0 MUL = disp.grd=10" % disp0)
    for i in range(nsbf):
        dispf = os.path.join(dispdir,"disp_%s_%i.grd" % (faults,i+1))
        os.system("gmt grdmath %s %f MUL disp.grd ADD = disp.grd=10" % (dispf,slip[i]))
        
        outdir  = os.path.join(maindir,"stochastic","scenarios_grid")
        outfile = os.path.join(outdir,"%s_displacement_%i.grd" % (faults,sce+1))
        os.system("cp disp.grd %s" % (outfile))
            