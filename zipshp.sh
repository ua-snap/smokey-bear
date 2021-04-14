#!/bin/bash -l
#Needs to be run with conda activate python36_geo

TARGETDIR="/Volumes/CWMobileSSD/Geodata_fires/2020_COVID_AFS/natice_noaa"
SHPPRODSUB=SHP_Products
DEPLOYSUB=SHP_Upload

ENDDATE=20200510
DAYSBACK=6   # how many days back to generate a timeseries for

cd $TARGETDIR
echo "*** Working in directory `pwd`"

echo "*** Generating zipped Shapefiles for upload, ${DAYSBACK} days back from ${ENDDATE}"
# reset the date to the last one generated
rm snowcover_latest.*
ogr2ogr snowcover_latest.shp ${SHPPRODSUB}/snowcover_${ENDDATE}.shp
zip snowcover_latest.zip snowcover_latest.*
cp snowcover_latest.zip ${DEPLOYSUB}/snowcover_latest_${ENDDATE}.zip
ogr2ogr snowcover_timeseries.shp ${SHPPRODSUB}/snowcover_${ENDDATE}.shp
while [[ $DAYSBACK -gt 0 ]]; do
    ENDDATE=`date -j -v-1d -f %Y%m%d $ENDDATE +%Y%m%d`
    ogr2ogr snowcover_timeseries.shp -update -append ${SHPPRODSUB}/snowcover_${ENDDATE}.shp
    ((DAYSBACK=DAYSBACK-1))
done
zip snowcover_timeseries.zip snowcover_timeseries.*
cp snowcover_timeseries.zip ${DEPLOYSUB}/snowcover_timeseries_${ENDDATE}.zip
