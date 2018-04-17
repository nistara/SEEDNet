# ==============================================================================
# Pre-Network work - to enable network creation
# ==============================================================================

# *** GRASS info
# Location: 2018-03-20_west-africa_laea
# MAPSET: pre-network
# Projection used: laea
# Datum: wgs84
# Proj4 string:
# code: g.proj -j -f
# output:
# ------------------------------------------------------------------------------
# +proj=laea +lat_0=55 +lon_0=20 +x_0=0 +y_0=0 +no_defs +a=6378137 +rf=298.257223563 +towgs84=0.000,0.000,0.000 +to_meter=1
# ------------------------------------------------------------------------------


# Prepping up the GIS data
# ==============================================================================

# *** Import guf poly from 4326 location
v.proj location=2018-03-19_west-africa_4326 mapset=pre-network input=guf_poly   


# *** Extract urban areas from guf polygon
# ref: https://grass.osgeo.org/grass70/manuals/v.extract.html
v.extract input=guf_poly output=guf_urban -d --overwrite \
	  where="(value = 255)"


# *** Add 100 m buffer around guf_noholes
v.buffer input=guf_urban output=guf_buffer type=area distance=100 -t --overwrite


# *** Remove donuts/holes in polygons
# ref: https://gis.stackexchange.com/a/140747/104459
# (optional before starting: clean features
v.clean in=guf_buffer out=guf_clean tool=bpol,rmdup
v.build map=guf_clean

# 1. Add centroids to the holes
v.centroids in=guf_clean out=guf_with_centroids
# 2. Drop the current table and and one that includes the 
#    areas that now have centroids and a value column that
#    you will use to dissolve the areas
v.db.droptable map=guf_with_centroids -f
v.db.addtable map=guf_with_centroids columns='value INT'
# 3. Update this "value" column with the same value everywhere
v.db.update map=guf_with_centroids col=value value=1
# 4. Now combine the areas by dissolving them together
v.dissolve in=guf_with_centroids out=guf_noholes column=value

# *** Export guf_noholes and import again (to get separate features)
v.out.ogr input=guf_noholes type=area output=guf_noholes.shp
v.in.ogr input=~/projects/ebo-net/data/GIS/grass_related/guf_noholes.shp output=guf

# *** Extract guf polys which fall within admi boundaries - imp
# IMP: Because we created a buffer around the guf poly. It may extend into the sea!
# clean adm0  map first
v.clean in=adm0_laea out=adm_clean tool=bpol,rmdup --overwrite
v.build map=adm_clean --overwrite
# ref: https://grass.osgeo.org/grass72/manuals/v.overlay.html
v.overlay binput=guf ainput=adm_clean operator=and output=guf_adm_overlay --overwrite

# *** Zonal statistics
# To get pop raster values from guf vector
v.rast.stats guf_adm_overlay raster=pop_laea \
	     column_prefix=pop method=sum,minimum,maximum,average,range,stddev \
	     --verbose --overwrite

# There are some guf polygons that don't have the underlying pop raster (because
# the polygons extend beyond country boundaries). 
# Note: probably want to watch out for this if looking at different data sources

# *** Extract guf polygons with underlying pop data
v.extract input=guf_adm_overlay output=guf_pop where="(pop_sum > 0)"

# *** Check guf polygins with 0 pop sum
v.extract input=guf_adm_overlay output=guf_pop_0 where="(pop_sum = 0)"
# It turns out the pop value in the underlying raster is 0, and the poly is very
# small. Hence the poly pop value is 0.

# *** Drop columns not of interest in guf_pop
v.info -c guf_pop
db.columns guf_pop

v.db.dropcolumn map=guf_pop columns=a_cat,a_ID_0,a_NAME_ENGLI,a_NAME_FAO,a_NAME_LOCAL,a_NAME_OBSOL,a_NAME_VARIA,a_NAME_NONLA,a_NAME_FRENC,a_NAME_SPANI,a_NAME_RUSSI,a_NAME_ARABI,a_NAME_CHINE,a_WASPARTOF,a_CONTAINS,a_SOVEREIGN,a_ISO2,a_WWW,a_FIPS,a_ISON,a_VALIDFR,a_VALIDTO,a_POP2000,a_SQKM,a_POPSQKM,a_DEVELOPING,a_CIS,a_Transition,a_OECD,a_WBREGION,a_WBINCOME,a_WBDEBT,a_WBOTHER,a_CEEAC,a_CEMAC,a_CEPLG,a_COMESA,a_EAC,a_ECOWAS,a_IGAD,a_IOC,a_MRU,a_SACU,a_UEMOA,a_UMA,a_PALOP,a_PARTA,a_CACM,a_EurAsEC,a_Agadir,a_SAARC,a_ASEAN,a_NAFTA,a_GCC,a_CSN,a_CARICOM,a_EU,a_CAN,a_ACP,a_Landlocked,a_AOSIS,a_SIDS,a_Islands,a_LDC,b_cat,b_cat_

# ==============================================================================
# Connecting guf with roads
# ==============================================================================

# *** Copy the road layer into current mapset
g.copy vect='roads@roads',roads --overwrite

# *** Add columns to guf_pop layer in prep for distance to roads
v.db.addcolumn guf_pop columns="to_x double precision,to_y double precision,dist double precision"

v.info -c guf_pop
# -c Print types/names of table columns for specified layer instead of info and exit

# *** Determine nearest distance of guf polygons to roads
v.distance from=guf_pop to=roads \
	   upload=to_x,to_y,dist \
	   column=to_x,to_y,dist --overwrite

# *** Save distance layer to csv so we can bring it in as a vector
db.out.ogr input=guf_pop \
	   output=~/projects/ebo-net/data/GIS/grass_related/guf_pop.csv --overwrite

# *** Load guf road dist csv
# IMP: First delete cat column from csv.
# ref: https://grass.osgeo.org/grass75/manuals/v.in.ascii.html
# import: skipping the header line, categories generated automatically,
# column names defined with type:
v.in.ascii in=~/projects/ebo-net/data/GIS/grass_related/guf_pop.csv \
	   out=guf_pts separator=comma \
	   columns="a_ISO TEXT,a_NAME_ISO TEXT,a_UNREGION1 TEXT,a_UNREGION2 TEXT,pop_sum DOUBLE PRECISION,pop_minimum DOUBLE PRECISION,pop_maximum DOUBLE PRECISION,pop_average DOUBLE PRECISION,pop_range DOUBLE PRECISION,pop_stddev DOUBLE PRECISION,to_x DOUBLE PRECISION,to_y DOUBLE PRECISION,dist DOUBLE PRECISION" \
	   x=11 y=12 skip=1

# verify column types
v.info -c guf_pts

# Getting connections between guf points and roads
v.distance from=guf_pop to=roads out=connections upload=dist column=dist --overwrite

# *** THE END PRODUCT: guf_pop, guf_pts, and connections




