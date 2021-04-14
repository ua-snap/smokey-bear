#!/bin/bash -l
#Needs to be run with conda activate python36_geo for gdal
# 2020/06 Chris Waigl cwaigl@alaska.edu

bash ./spruceadjAK.sh
bash ./spruceadjCA.sh
bash ./spruceadjmerge.sh