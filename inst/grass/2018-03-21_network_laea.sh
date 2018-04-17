# ==============================================================================
# Creating the network
# ==============================================================================

# *** GRASS info
# Location: 2018-03-20_west-africa_laea
# MAPSET: network
# Projection used: laea
# Datum: wgs84


# To see projection info
# g.proj -p

# To change mapset and location:
# g.mapset mapset=network location=2018-03-20_west-africa_laea

# To see current environment
# g.gisenv

# *** Copy the road layer into current mapset
g.copy vect='roads@roads',roads --overwrite

# *** Export roads and import again (to get separate features)
v.out.ogr -c input=roads type=line \
	  output=~/projects/ebo-net/data/GIS/grass_related/roads/roads.shp

v.in.ogr input=~/projects/ebo-net/data/GIS/grass_related/roads/roads.shp \
	 output=roads --overwrite

# *** Split roads so we have nodes
v.split roads out=roads_split length=1000 --overwrite

# *** Copy the guf layers into curent mapset
g.copy vect='guf_pop@pre-network',guf_pop --overwrite
g.copy vect='guf_pts@pre-network',guf_pts --overwrite


# Sample network with 10 pts
# ==============================================================================
# *** Extracting 10 random pts
v.extract -d input=guf_pts output=test10 random=10
# v.extract -d input=guf_3269 output=test_pts cats=1,2,3,4,5 --overwrite

# *** Checking created random points layer 
# v.db.select test_pts columns=cat
# v.category input=test_pts option=report
v.db.select test10 columns=cat

# *** Creating network
v.net input=roads_split points=test10 \
      output=net10 operation=connect thresh=100

# *** Looking at network info
# v.category input=net10 option=report

# Testing distances with two methods
# ==============================================================================
# *** Method I. v.net.allpairs
v.net.allpairs input=net10 out=roads_net_all10

# Seeing the results
v.db.select roads_net_all10
v.category input=roads_net_all10 option=report

# *** Method II. v.net.path
# echoing pairs and getting distance
echo -e "90 17600 17059\n 90 17600 17059\n 90 17600 17059" | v.net.path net10 out=mypath --overwrite
v.db.select mypath

# *** Comparing both methods
# v.net.allpairs will take time because it's calculating all distances
# Hence, v.net.path is the way to go
# The distance between the pair:  90|17600|17059
# is the same with both methods: 974873.809


# ==============================================================================
# Create the network :gulp:fingers crossed:
# ==============================================================================

# *** First, subset those points with pop >= 10 and dist <= 5 km (5,000 m)
v.extract input=guf_pts output=guf_pts_subset \
	  where="(pop_sum >=10) and (dist <= 5000)" --overwrite


# *** Export guf_pts as csv, so we can get its cat numbers
db.out.ogr input=guf_pts_subset \
	   output=~/projects/ebo-net/data/GIS/grass_related/guf_pts_subset.csv \
	   format=CSV


# *** Create network with subsetted pts
v.net input=roads_split points=guf_pts_subset \
      output=net operation=connect thresh=100 --overwrite

# *** using a text file to feed in pairs
# Testing with first million lines
sed -e '100000q' data/GIS/grass_related/guf_subset_pairs.txt > data/GIS/grass_related/1m.txt

v.net.path net \
	   out=network_path \
	   file=data/GIS/grass_related/1m.txt --overwrite

db.out.ogr input=network_path \
	   output=data/GIS/grass_related/network/dist_1m.csv \
	   format=CSV --overwrite


sed -e '1,1000000d;2000000q' data/GIS/grass_related/guf_subset_pairs.txt > data/GIS/grass_related/1m_2m.txt

# Looks like the row numbers are increasig the file size. it's up from approx 3MB to 16MB
v.net.path net \
	   out=network_path_1m2m \
	   file=data/GIS/grass_related/1m_2m.txt --overwrite

v.db.dropcolumn map=network_path_1m2m columns=id,sp,fdist,tdist

db.out.ogr input=network_path_1m2m \
	   output=data/GIS/grass_related/network/dist_1m2m_drop.csv \
	   format=CSV


# Remove extra columns???
# Perhaps subset columns each time before saving
# It takes a long time to save 1m_2m file as well. sigh. 
# Perhaps do it country by country. Identify boundary areas and b/w countries
# and only calculate those






wc -l ~/projects/ebo-net/data/GIS/grass_related/guf_subset_pairs.csv
head ~/projects/ebo-net/data/GIS/grass_related/pairs.txt

# ==============================================================================
# R code
# ==============================================================================
library(rgrass7)

# net = readVECT(vname = "net")

# execGRASS("g.list", type="vector", intern=TRUE)

# system("wc -l ~/projects/ebo-net/data/GIS/grass_related/guf_subset_pairs.txt")

N = as.numeric(
    R.utils::countLines(
	"~/projects/ebo-net/data/GIS/grass_related/guf_subset_pairs.txt"))

step = 100000
block = seq(step, N, by = step)

file_path = "/Users/nistara/projects/ebo-net/data/GIS/grass_related/guf_subset_pairs.txt"

cmds = sprintf("tail -n %d %s | head -n %d > tmp.txt", block, file_path, step)

if((N - tail(block, 1)) > 0)
{
    cmds[ length(cmds) + 1] =
    sprintf("head -n %d %s > tmp.txt", N - tail(block, 1), file_path)
      block = c(block, 1)
}
  

lapply(seq_along(cmds), function(n, cmds) {
	   system(cmds[ n ])
	   execGRASS('v.net.path',
		     parameters = list(
			 input = 'net',
			 file = "/Users/nistara/projects/ebo-net/tmp.txt",
			 output ='tmp_net'),
		     flags = 'overwrite')

	   net_dist = execGRASS('v.db.select',
				parameters = list(
				    map = 'tmp_net',
				    columns = 'fcat,tcat,cost'),
				flags = 'c',
				intern = TRUE)

	   df = do.call(rbind,
			lapply(strsplit(net_dist, "\\|"), as.numeric))
	   df = df[ df[,3] != 0, ]
	   df = df[ is.finite( df[,3]), ]

	   out_file = sprintf("/Users/nistara/projects/ebo-net/data/GIS/net-dist/dist_%d.csv", n)
			     
	   write.table(df, out_file, row.names = FALSE, col.names=FALSE)
	   return(cmds[n])
       }, cmds)



# # Parallel
# N = as.numeric(
#     R.utils::countLines(
# 	"~/projects/ebo-net/data/GIS/grass_related/guf_subset_pairs.txt"))
# 
# step = 100000
# block = seq(step, N, by = step)
# 
# file_path = "/Users/nistara/projects/ebo-net/data/GIS/grass_related/guf_subset_pairs.txt"
# 
# cmds = sprintf("tail -n %d %s | head -n %d > tmp%d.txt", block,
# 	       file_path,
# 	       step,
# 	      seq_along(block))
# 
# if((N - tail(block, 1)) > 0)
# {
#     cmds[ length(cmds) + 1] =
#     sprintf("head -n %d %s > tmp%d.txt",
# 	    N - tail(block, 1),
# 	    file_path,
# 	   length(block) + 1)
#       block = c(block, 1)
# }
  

# library(parallel)
# # Calculate the number of cores
# no_cores <- detectCores() - 2
# 
# # Initiate cluster
# cl <- makeCluster(no_cores, type="FORK")
# 
# parLapply(cl, seq_along(cmds), function(n, cmds) {
# 	   system(cmds[ n ])
# 
# 	   execGRASS('v.net.path',
# 		     parameters = list(
# 			 input = 'net',
# 			 file = sprintf("/Users/nistara/projects/ebo-net/tmp%d.txt",
# 					n),
# 			 output = sprintf("tmp_net_%d", n)),
# 		     flags = 'overwrite')
# 
# 	   net_dist = execGRASS('v.db.select',
# 				parameters = list(
# 				    map = sprintf("tmp_net_%d", n),
# 				    columns = 'fcat,tcat,cost'),
# 				flags = 'c',
# 				intern = TRUE)
# 
# 	   execGRASS('g.remove',
# 		     parameters = list(
# 			 name = sprintf("tmp_net_%d", n),
# 			 type = 'vector'),
# 		    flags = 'f')
# 
# 	   df = do.call(rbind,
# 			lapply(strsplit(net_dist, "\\|"), as.numeric))
# 	   df = df[ df[,3] != 0, ]
# 	   df = df[ is.finite( df[,3]), ]
# 
# 	   out_file = sprintf("/Users/nistara/projects/ebo-net/data/GIS/net-dist/dist_%d.csv", n)
# 			     
# 	   write.table(df, out_file, row.names = FALSE, col.names=FALSE)
# 
# 	   system(sprintf("rm tmp%d.txt", n))
# 	   
# 	   return(cmds[n])
#        }, cmds)
# 
# 
# stopCluster(cl)




