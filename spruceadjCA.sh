#!/bin/bash -l
#Needs to be run with conda activate python36_geo for gdal
# 2020/07 Chris Waigl cwaigl@alaska.edu


#JUST GET AND PROCESS CANADIAN DATA
source ./spruceadj.config
declare -a SHPEXT=("shp" "shx" "dbf" "prj")
TODAY=`date -j +%Y%m%d`
YEAR=${TODAY:0:4}
MONTH=${TODAY:4:2}
DAY=${TODAY:6:2}

cd $TARGETDIR_CA
echo "*** Working in ${TARGETDIR_CA}"
for ext in "${SHPEXT[@]}"; do
    wget -nc ${URLBASE_CA}fdr.${ext}
    if [[ $? -eq 8 ]]; then
        echo "wget could not retrieve remote file ${URLBASE_CA}fdr.${ext}"; exit 1
    fi
done
zip ${SHPARCHIVESUB}/${TODAY}_fdr.zip fdr.*
ogrinfo fdr.shp -sql "ALTER TABLE fdr ADD COLUMN firedanger integer"
ogrinfo fdr.shp -dialect SQLite -sql "UPDATE fdr SET firedanger = GRIDCODE + 1"
ogrinfo fdr.shp -sql "ALTER TABLE fdr DROP COLUMN GRIDCODE"
ogrinfo fdr.shp -sql "ALTER TABLE fdr ADD COLUMN chardate character(10)"
ogrinfo fdr.shp -dialect SQLite -sql "UPDATE fdr SET chardate = '${YEAR}-${MONTH}-${DAY}'"
ogr2ogr -f 'ESRI Shapefile' -t_srs EPSG:3338 spruceadj_latestCA.shp fdr.shp
zip ${SHPARCHIVESUB}/${TODAY}_fdr_processed.zip spruceadj_latestCA.*
rm -v fdr.*