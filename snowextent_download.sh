#!/bin/bash -l
#Needs to be run with conda activate python36_geo for gdal
# 2021/03 Chris Waigl cwaigl @alaska.edu
# ONLY downloads of zipped files

TARGETDIR="/Volumes/CWMobileSSD/Geodata_fires/2020_COVID_AFS/natice_noaa"
#TARGETDIR="snowdata"
GTARCHIVESUB=GeoTIFF_Archive
TONOW=0

YEAR=2019
STARTMONTHDAY=0101
ENDMONTHDAY=1231
STARTDATE=${YEAR}${STARTMONTHDAY}

if [[ $TONOW -eq 1 ]]
then
    ENDDATE=`date -j +%Y%m%d`
else
    ENDDATE=${YEAR}${ENDMONTHDAY}
fi

URL1="https://usicecenter.gov/File/DownloadProduct?products=%2Fims%2Fims_v3%2Fimstif%2F1km%2F${YEAR}&fName=NIC.IMS_v3_"
#URL1="https://www.natice.noaa.gov/pub/ims/ims_v3/imstif/1km/${YEAR}/NIC.IMS_v3_"
URL2="_1km.tif.gz"

echo $STARTDATE $ENDDATE
cd $TARGETDIR

while [[ ! $STARTDATE > $ENDDATE ]]; do
    YEAR=${STARTDATE:0:4}
    MONTH=${STARTDATE:4:2}
    DAY=${STARTDATE:6:2}
    INFILE=NIC.IMS_v3_${STARTDATE}_1km.tif
    if [[ ! -f ${GTARCHIVESUB}/${INFILE}.gz ]]; then
        echo "Retrieving ${INFILE}.gz from National Ice Center"
        wget -nc --content-disposition "$URL1$STARTDATE$URL2"
        if [[ $? -eq 8 ]]; then
            {echo "wget could not retrieve remote file $URL1$STARTDATE$URL2"; exit 1}
        fi
        mv ${INFILE}.gz ${GTARCHIVESUB}/
    else 
        echo "Archive already contains ${INFILE}.gz"
    fi
    STARTDATE=`date -j -v+1d -f %Y%m%d $STARTDATE +%Y%m%d`
done
