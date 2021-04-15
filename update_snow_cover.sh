# Downloads data from upstream source,
# Updates layer in GeoServer,
# Rebuilds TileCache layer.
set -x

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	ymd=$( date -d "yesterday" '+%Y%m%d' )
	year=$( date -d "yesterday" '+%Y' )
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ymd=$( date -v-1d +%Y%m%d )
    year=$( date -v-1d +%Y )
else
	echo "OS unknown?"
	exit 1
fi

fname="NIC.IMS_v3_${ymd}_1km.tif"
tname="snow_cover_3338.tif"
wget -nc -P /tmp --content-disposition "https://usicecenter.gov/File/DownloadProduct?products=%2Fims%2Fims_v3%2Fimstif%2F1km%2F${year}&fName=${fname}.gz"
gunzip -f /tmp/$fname
gdal_translate -projwin -175.0 50.0 -80.0 55.0 -projwin_srs EPSG:4326 /tmp/$fname /tmp/snow_cover_crop.tif
gdalwarp -overwrite -t_srs EPSG:3338 /tmp/snow_cover_crop.tif /tmp/snow_cover_warp.tif
gdal_translate -projwin 173.2 77.0 -118.0 46.0 -projwin_srs EPSG:4326 /tmp/snow_cover_warp.tif /tmp/$tname
