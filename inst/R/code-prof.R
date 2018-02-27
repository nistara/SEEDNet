library(disnet)
library(igraph)

# For commuting
# ==============================================================================

g = readRDS("~/Drive/projects/ebo-net/data/flu-g.RDS")

ctr = countMCalls(funs = c("disnet_commuting",
                           "disnet_comm1",
                           "disnet_comm2",
                           "disnet_comm3"))

disnet_commuting(g)
                  
