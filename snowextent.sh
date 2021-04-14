#!/bin/bash -l
#Needs to be run with conda activate python36_geo for gdal
# 2020/04 Chris Waigl cwaigl @alaska.edu

#TARGETDIR="/Volumes/CWMobileSSD/Geodata_fires/2020_COVID_AFS/natice_noaa"
TARGETDIR="snowdata"
GTARCHIVESUB=GeoTIFF_Archive
GTPRODSUB=GeoTIFF_Products
SHPPRODSUB=SHP_Products
DEPLOYSUB=SHP_Upload
DODOWNLOAD=1
DOZIPS=0

YEAR=2019
STARTMONTHDAY=0101
ENDMONTHDAY=0301
STARTDATE=${YEAR}${STARTMONTHDAY}
DAYSBACK=6   # how many days back to generate a timeseries for

if [[ $YEAR -eq 2021 ]]
then
    ENDDATE=`date -j +%Y%m%d`
else
    ENDDATE=${YEAR}${ENDMONTHDAY}
fi

SNOWCLASSES=("no data" "water" "snow-free" "ice" "snow")
URL1="https://usicecenter.gov/File/DownloadProduct?products=%2Fims%2Fims_v3%2Fimstif%2F1km%2F${YEAR}&fName=NIC.IMS_v3_"
#URL1="https://www.natice.noaa.gov/pub/ims/ims_v3/imstif/1km/${YEAR}/NIC.IMS_v3_"
URL2="_1km.tif.gz"

echo $STARTDATE $ENDDATE
cd $TARGETDIR

while [[ ! $STARTDATE > $ENDDATE ]]; do
#for DAY in {23..29}; do
#for INFILE in NIC.IMS_v3_202004{20..29}_1km.tif; do
    YEAR=${STARTDATE:0:4}
    MONTH=${STARTDATE:4:2}
    DAY=${STARTDATE:6:2}
    INFILE=NIC.IMS_v3_${STARTDATE}_1km.tif
    if [[ $DODOWNLOAD -eq 1 && ! -f $INFILE && ! -f ${GTARCHIVESUB}/${INFILE}.gz ]]; then
        echo "Retrieving ${INFILE}.gz from National Ice Center"
        wget -nc --content-disposition "$URL1$STARTDATE$URL2"
        if [[ $? -eq 8 ]]; then
            {echo "wget could not retrieve remote file $URL1$STARTDATE$URL2"; exit 1}
        fi
        gunzip -k ${INFILE}.gz
        mv ${INFILE}.gz ${GTARCHIVESUB}/
    fi
    if [[ -f $INFILE ]]; then
        echo "*** Working on $INFILE" 
        SNIPFILE=snip_${STARTDATE}.tif
        WARPFILE=test_${STARTDATE}.tif
        FINAL=NIC.IMS_v3_${STARTDATE}_1km_AK_EPSG3338.tif
        echo "*** Initial crop"
        gdal_translate -projwin -175.0 50.0 -80.0 55.0 -projwin_srs EPSG:4326 $INFILE $SNIPFILE
        echo "*** Reprojecting"
        gdalwarp -t_srs EPSG:3338 $SNIPFILE $WARPFILE
        echo "*** Final crop"
        gdal_translate -projwin 173.2 77.0 -118.0 46.0 -projwin_srs EPSG:4326 $WARPFILE $FINAL
        GISLAYER=snowcover_${STARTDATE}
        echo "*** Convert to Shapefile"
        gdal_polygonize.py $FINAL -8 -b 1 -f "ESRI Shapefile" $GISLAYER.shp $GISLAYER snowclass
        ogrinfo $GISLAYER.shp -sql "ALTER TABLE $GISLAYER ADD COLUMN refdate date"
        ogrinfo $GISLAYER.shp -sql "ALTER TABLE $GISLAYER ADD COLUMN chardate character(10)"
        ogrinfo $GISLAYER.shp -sql "ALTER TABLE $GISLAYER ADD COLUMN clname character(16)"
        ogrinfo $GISLAYER.shp -dialect SQLite -sql "UPDATE  $GISLAYER SET refdate = '${YEAR}/${MONTH}/${DAY} 12:00:00'"
        ogrinfo $GISLAYER.shp -dialect SQLite -sql "UPDATE  $GISLAYER SET chardate = '${YEAR}-${MONTH}-${DAY}'"
        for i in ${!SNOWCLASSES[@]}; do
            ogrinfo $GISLAYER.shp -dialect SQLite -sql "UPDATE $GISLAYER SET clname = '${SNOWCLASSES[$i]}' WHERE snowclass = '$i'" 
        done
        echo "*** Cleaning up"
        mv $GISLAYER.* ${SHPPRODSUB}/
        mv $FINAL ${GTPRODSUB}/
        rm $WARPFILE
        rm $SNIPFILE
        rm $INFILE
        echo 
    fi
    STARTDATE=`date -j -v+1d -f %Y%m%d $STARTDATE +%Y%m%d`
done

if [ $DOZIPS -eq 1 ]; then
    echo "*** Generating zipped Shapefiles for upload"
    # reset the date to the last one generated
    STARTDATE=`date -j -v-1d -f %Y%m%d $STARTDATE +%Y%m%d`
    rm snowcover_latest.*
    ogr2ogr snowcover_latest.shp ${SHPPRODSUB}/snowcover_${STARTDATE}.shp
    zip snowcover_latest.zip snowcover_latest.*
    cp snowcover_latest.zip ${DEPLOYSUB}/snowcover_latest_${STARTDATE}.zip
    ogr2ogr snowcover_timeseries.shp ${SHPPRODSUB}/snowcover_${STARTDATE}.shp
    while [[ $DAYSBACK -gt 0 ]]; do
        STARTDATE=`date -j -v-1d -f %Y%m%d $STARTDATE +%Y%m%d`
        ogr2ogr snowcover_timeseries.shp -update -append ${SHPPRODSUB}/snowcover_${STARTDATE}.shp
        ((DAYSBACK=DAYSBACK-1))
    done
    zip snowcover_timeseries.zip snowcover_timeseries.*
    cp snowcover_timeseries.zip ${DEPLOYSUB}/snowcover_timeseries_${STARTDATE}.zip
fi