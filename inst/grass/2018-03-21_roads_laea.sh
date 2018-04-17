# ==============================================================================
# Cleaning the road layer
# ==============================================================================


# *** GRASS info
# Location: 2018-03-20_west-africa_laea
# MAPSET: roads
# Projection used: laea
# Datum: wgs84

# *** Copy the road layer into current mapset (roads)
g.copy vect='roads_laea@PERMANENT',roads_laea

# *** Checking out road layer info
v.category input=roads_laea option=report

# *** Create road polylines
# ref: https://grass.osgeo.org/grass74/manuals/v.build.polylines.html
v.build.polylines input=roads_laea output=roads_polylines

# *** Clean roads (remove dangles - lines not connected to anything else)
v.clean input=roads_polylines output=roads type=line \
        tool=rmdangle threshold=10000 --overwrite



# *** THE END PRODUCT: roads
