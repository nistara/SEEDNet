# ==============================================================================
# West africa project in LAEA projection
# ==============================================================================

# *** GRASS info
# Location: 2018-03-20_west-africa_laea
# MAPSET: PERMANENT
# Projection used: laea
# Datum: wgs84
# Proj4 string:
# code: g.proj -j -f
# output:
# ------------------------------------------------------------------------------
# +proj=laea +lat_0=55 +lon_0=20 +x_0=0 +y_0=0 +no_defs +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1
# ------------------------------------------------------------------------------


# Importing GIS data
# ==============================================================================

# *** Import vectors------------------------------------------------------------
v.proj location=2018-03-19_west-africa_4326 mapset=PERMANENT input=adm0 output=adm0_laea
v.proj location=2018-03-19_west-africa_4326 mapset=PERMANENT input=adm1 output=adm1_laea
v.proj location=2018-03-19_west-africa_4326 mapset=PERMANENT input=adm2 output=adm2_laea
v.proj location=2018-03-19_west-africa_4326 mapset=PERMANENT \
       input=gin_lbr_sle_roads output=roads_laea


# *** Set region
# g.region vector=adm0@PERMANENT

# *** Import rasters------------------------------------------------------------
# *** First, reproject rasters using GDAL (too slow with r.proj)
# ref: http://www.gdal.org/gdalwarp.html
gdalwarp -t_srs '+proj=laea +lat_0=55 +lon_0=20 +x_0=0 +y_0=0 +no_defs +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1' -overwrite guf75_gin_lbr_sle.tif guf75_laea.tif

gdalwarp -t_srs '+proj=laea +lat_0=55 +lon_0=20 +x_0=0 +y_0=0 +no_defs +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1' -overwrite wa_pop.tif pop_laea.tif

# *** Then, import them
r.in.gdal input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-guf/guf_75_7cntries/guf75_laea.tif output=guf75_laea --overwrite

r.in.gdal input=/Users/nistara/Drive/projects/ebo-net/data/GIS/population/GIN_LBR_SLE_merge/pop_laea.tif output=pop_laea
