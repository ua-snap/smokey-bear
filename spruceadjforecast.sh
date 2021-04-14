#!/bin/bash -l
#Needs to be run with conda activate python36_geo for gdal
# 2020/07 Chris Waigl cwaigl@alaska.edu

source ./spruceadj.config
STARTDATE=`date -j +%Y%m%d`
ARCHIVEDIR=$STARTDATE

cd ${TARGETDIR_AK}/${FORECASTSUB}
mkdir ${ARCHIVEDIR}

rm spruce_forecastAK_latest.*
for ii in {0..2}; do
    YEAR=${STARTDATE:0:4}
    MONTH=${STARTDATE:4:2}
    DAY=${STARTDATE:6:2}
    wget -nc ${URLBASE_AK}${STARTDATE}_spruce.tiff
    if [[ $? -eq 8 ]]; then
        {echo "wget could not retrieve remote file ${URLBASE_AK}${STARTDATE}_spruce.tiff"; exit 1}
    fi
    gdalwarp -t_srs EPSG:3338 ${STARTDATE}_spruce.tiff spruce_${STARTDATE}_AKAlbers.tiff
    gdal_polygonize.py spruce_${STARTDATE}_AKAlbers.tiff  -8 -b 1 -f "ESRI Shapefile" spruce_${STARTDATE}.shp spruceadj firedanger
    ogrinfo spruce_${STARTDATE}.shp -sql "ALTER TABLE spruce_${STARTDATE} ADD COLUMN chardate character(10)"
    ogrinfo spruce_${STARTDATE}.shp -sql "ALTER TABLE spruce_${STARTDATE} ADD COLUMN predday integer"
    ogrinfo spruce_${STARTDATE}.shp -dialect SQLite -sql "UPDATE spruce_${STARTDATE} SET chardate = '${YEAR}-${MONTH}-${DAY}'"
    ogrinfo spruce_${STARTDATE}.shp -dialect SQLite -sql "UPDATE spruce_${STARTDATE} SET predday = ${ii}"
    ogr2ogr -update -append spruce_forecastAK_latest.shp spruce_${STARTDATE}.shp
    echo "Moving ${STARTDATE} files into archive directory ${ARCHIVEDIR}"
    mv spruce_${STARTDATE}*.* ${ARCHIVEDIR}
    mv ${STARTDATE}_spruce.tiff ${ARCHIVEDIR}
    STARTDATE=`date -j -v+1d -f %Y%m%d $STARTDATE +%Y%m%d`
done

zip spruce_forecastAK_latest.zip spruce_forecastAK_latest.*
