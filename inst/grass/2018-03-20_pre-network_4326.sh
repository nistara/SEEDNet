# ==============================================================================
# Pre-Network work - to enable network creation
# ==============================================================================

# *** GRASS info
# Location: 2018-03-19_west-africa_4326
# MAPSET: pre-network
# Projection used: wgs84
# Datum: wgs84

# Prepping up the GIS data
# ==============================================================================

# *** Convert guf raster to polygon
# ref: https://grass.osgeo.org/grass72/manuals/r.to.vect.html
r.to.vect -s input=guf75_gin_lbr_sle output=guf_poly type=area 
# -s   Smooth corners of area features

# *** Extract urban areas from guf polygon
# ref: https://grass.osgeo.org/grass70/manuals/v.extract.html
v.extract input=guf_poly output=guf_urban -d --overwrite \
	  where="(value = 255)"

# *** Remove donuts/holes in polygons
# ref: https://gis.stackexchange.com/a/140747/104459
# (optional before starting: clean features
v.clean in=guf75_poly_urban out=guf_clean tool=bpol,rmdup
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


# add table to guf_noholes
v.db.addtable map=guf_noholes columns='value INT'
v.db.update map=guf_noholes col=value value=1


# *** Create buffer around polygons
# need to reproject gguf_noholes to LAEA projection 

v.proj location=2018-03-19_west-africa_4326 mapset=pre-network input=guf_noholes



# ==============================================================================

# *** Add 100 m buffer around guf_noholes
v.buffer input=guf_noholes output=guf_buffer type=area distance=100 -t --overwrite

v.out.ogr input=guf_buffer type=area output=guf_buffer.shp
v.in.ogr input=~/projects/ebo-net/data/GIS/in-process/guf_buffer.shp output=guf_buffer_split






v.proj location=2018-03-19_west-africa_4326 mapset=pre-network input=guf_noholes

# *** Convert guf raster to polygon
# ref: https://grass.osgeo.org/grass72/manuals/r.to.vect.html
r.to.vect -s input=guf75_gin_lbr_sle output=guf75_poly type=area

# *** Extract urban areas from guf polygon
# ref: https://grass.osgeo.org/grass70/manuals/v.extract.html
v.extract input=guf75_poly output=guf75_poly_urban -d --overwrite \
	  where="(value = 255)"

# *** Remove donuts/holes in polygons
# ref: https://gis.stackexchange.com/a/140747/104459
# (optional before starting: clean features
v.clean in=guf75_poly_urban out=guf_clean tool=bpol,rmdup
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


# add table to guf_noholes
v.db.addtable map=guf_noholes columns='value INT'
v.db.update map=guf_noholes col=value value=1


# *** Create buffer around polygons
# need to reproject gguf_noholes to LAEA projection 





# ==============================================================================

# *** Add 100 m buffer around guf_noholes
v.buffer input=guf_noholes output=guf_buffer type=area distance=100 -t --overwrite

v.out.ogr input=guf_buffer type=area output=guf_buffer.shp
v.in.ogr input=~/projects/ebo-net/data/GIS/in-process/guf_buffer.shp output=guf_buffer_split
