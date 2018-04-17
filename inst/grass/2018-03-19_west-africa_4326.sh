# ==============================================================================
# GRASS GIS workflow for West Africa
# ==============================================================================

# *** List vector and raster files
g.list vect
g.list rast


# Import GIS data
# ==============================================================================
# Originally done through gui, and then I attempted shell scripting to make it
# simpler and easily reproducible

# *** Import ROADS
v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-roads/gin_lbr_sle_trs_roads_wfp_201409/gin_lbr_sle_trs_roads_wfp_201409.shp layer=gin_lbr_sle_trs_roads_wfp_201409 output=gin_lbr_sle_roads

# *** Import ADMIN BOUNDARIES
files=`find ~/Drive/projects/ebo-net/data/GIS/west-africa-adm -maxdepth 2 | grep  'GIN\|SLE\|LBR' | grep _adm[0-9].shp$`
# echo "$files"

for f in $files
do
    f_in=`dirname $f`
    s=`basename $f`
    f_out=`echo "${s/.shp}"`
    v.in.ogr input=$f_in layer=$f_out output=$f_out
done

# # the above to replace following individual commands
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/SLE_adm_shp layer=SLE_adm0 output=SLE_adm0
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/SLE_adm_shp layer=SLE_adm1 output=SLE_adm1
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/SLE_adm_shp layer=SLE_adm2 output=SLE_adm2
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/SLE_adm_shp layer=SLE_adm3 output=SLE_adm3
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/GIN_adm_shp layer=GIN_adm0 output=GIN_adm0
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/GIN_adm_shp layer=GIN_adm1 output=GIN_adm1
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/GIN_adm_shp layer=GIN_adm2 output=GIN_adm2
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/GIN_adm_shp layer=GIN_adm3 output=GIN_adm3
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/LBR_adm_shp layer=LBR_adm0 output=LBR_adm0
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/LBR_adm_shp layer=LBR_adm1 output=LBR_adm1
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/LBR_adm_shp layer=LBR_adm2 output=LBR_adm2
# # There were warnings for the above
# v.in.ogr input=/Users/nistara/Drive/projects/ebo-net/data/GIS/west-africa-adm/LBR_adm_shp layer=LBR_adm3 output=LBR_adm3


# *** Import WORLDPOP (population data)---
r.in.gdal input=/Users/nistara/Drive/projects/ebo-net/data/GIS/population/GIN-POP/GIN14adjv1.tif output=GIN2014
r.in.gdal input=/Users/nistara/Drive/projects/ebo-net/data/GIS/population/LBR-POP/LBR14adjv1.tif output=LBR2014
r.in.gdal input=/Users/nistara/Drive/projects/ebo-net/data/GIS/population/SLE-POP/SLE14adjv1.tif output=SLE2014


# ==============================================================================
# Cleaning v.in.ogr files
# ==============================================================================

files=`find ~/grassdata/2018-03-19_west-africa_4326/PERMANENT/vector -maxdepth 1 | grep adm`

for file in $files  
do
    f=`basename $file`
    f_out="${f}_clean"
    echo $f_out
    v.clean input=$f output=$f_out tool=bpol,rmdupl type=boundary
done

# ref:
# https://stackoverflow.com/a/2536052/5443003
# http://mywiki.wooledge.org/ParsingLs
# https://superuser.com/a/418490
# https://gis.stackexchange.com/a/75084/104459
# https://grass.osgeo.org/grass74/manuals/v.clean.html
# From above ref: The import of areas with v.in.ogr -c (no cleaning) requires a subsequent run of v.clean to update the map to a topologically valid structure (removal of duplicate collinear lines etc). The tools used for that are bpol and rmdupl.


# ==============================================================================
# Combining files
# ==============================================================================

# *** Combine ADM files
# ref:
# https://stackoverflow.com/a/5928254/5443003

for i in {0..2}
do
    files=`find ~/grassdata/2018-03-19_west-africa_4326/PERMANENT/vector -maxdepth 1 | grep adm${i}_clean`
    f=`basename $files`
    s=`echo ${f[@]}`
    in_files=`echo "${s// /,}"`
    # echo "$in_files"
    f_out="adm${i}"
    # echo "$f_out"
    v.patch input=$in_files out=$f_out -e 
    # -e above is so that tables are also added
done


# *** Combine WORLDPOP raster files
# ref:
# https://grass.osgeo.org/grass74/manuals/r.patch.html

MAPS=`g.list type=raster sep=, pat="*2014"`
g.region raster=$MAPS
r.patch in=$MAPS out=worldpop_gin_lbr_sle


# ==============================================================================
# View topological errors if you want to 
# ==============================================================================

d.mon start=wx0 # first, start monitor
# check errors for adm0
# ref: https://grass.osgeo.org/grass75/manuals/d.mon.html
# ref: https://grass.osgeo.org/grass74/manuals/v.clean.html

v.build -e map=adm0 error=adm0_build_errors
v.clean -c input=adm0 output=adm0_clean error=adm0_cleaning_errors tool=rmdupl,snap,rmbridge,chbridge,bpol,prune threshold=0 --overwrite

# The vector maps can be visualized together with the original data by the following set of display commands:
d.vect map=adm0 color=26:26:26 fill_color=77:77:77 width=2
d.vect map=adm0_clean color=26:26:26 fill_color=22:22:22 width=2
d.vect map=adm0_build_errors color=255:33:36 fill_color=none width=5 icon=basic/point size=30
d.vect map=adm0_cleaning_errors color=255:33:36 fill_color=none width=5 icon=basic/point size=30


# ==============================================================================
# miscellaneous
# ==============================================================================

# *** how to remove files
# ref: https://grass.osgeo.org/grass74/manuals/g.remove.html
g.remove -f pattern=adm_0* type=vector
