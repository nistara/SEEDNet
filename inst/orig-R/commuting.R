# ==============================================================================
# ==============================================================================
## This code calculates the commuting rates between nodes in the graph
##
## There are 1606 nodes, and 2577630 edges (after removing the self edges:
##      (1606 * 1606) - 1606 = 2577630
##      NOTE: they go from 0-1605, not 1-1606
##            the matrix is arranged from smallest distance to largest one
# ==============================================================================
# ==============================================================================
                        
library(igraph)
library(dplyr)


# ==============================================================================
## Read in created Rwanda network graph that was sent to Hugo-------------------
# ==============================================================================
g = read.graph("data/graphml/2016-07-15_rwa-net.graphml", format="graphml")

## Convert graphml object to dataframe for further manipulation
df = igraph::as_data_frame(g, what = "both")

## Node information
nd_verts = df$vertices
nodes = unique(df$edges$from)           #unique nodes

## Edges
nd_edges = df$edges


## Adding population data to edges----------------------------------------------
## -----------------------------------------------------------------------------
pop_from = inner_join(nd_edges, nd_verts, by = c("from" = "name"))["pop"]
nd_edges$pop_from = pop_from$pop

pop_to = inner_join(nd_edges, nd_verts, by = c("to" = "name"))["pop"]
nd_edges$pop_to = pop_to$pop


# ==============================================================================
# Functions for commuting rate 
# ==============================================================================

# commuting_I_fxn
#
# gets commuting rate for each individual node (hence it's for individual nodes)
# Considers a commuting proportion of 11% for the entire population
#
# @param j all the nodes `i` is connected to
#
# @param edges_subset subset of `nd_edges` with all outgoing edges of `i`
#
# @param i the node for which commuting proportion is being calculated

commuting_I_fxn = function(j, edges_subset, i) {
    radius = edges_subset$Total_Length[ edges_subset$to %in% j]
    df_radius = edges_subset[ edges_subset$Total_Length <= radius, ]
    m_i = df_radius$pop_from[1]
    n_j = df_radius$pop_to[ df_radius$to %in% j]
    s_ij = sum(df_radius$pop_to[ df_radius$to != j])
    N_c = 0.11 # using 0.11 as commuting proportion from Simini paper
    N = 1 # to get 0.11 as proportion
    T_i = (N_c/N) # want only rate, not num people. original:  m_i * (N_c/N)
    T_ij = T_i * ( (m_i * n_j) / ((m_i + s_ij) * (m_i + n_j + s_ij)) )
    return(T_ij)
    }


# For all nodes (includes individual node function)
# ------------------------------------------------------------------------------
#
# commuting_II_fxn
# 
# @param i id of the `from` node, for which we want to calculate commuting
#          proportion    
# @param test_edges the dataframe of the edges which contains the distances
#                   between the nodes and the population of each edges's
#                   `from` and `to nodes.

commuting_II_fxn = function(i,test_edges) {
    edges_subset = test_edges[ test_edges$from %in% i, ]
    all_j = edges_subset$to
    print(paste0("working on: ", i))

    comm_rate = lapply(all_j, commuting_I_fxn, edges_subset, i)
    comm_rate = do.call(rbind, comm_rate)
    return(comm_rate)
}

## Commuting function wrapper (includes both individual and all nodes' functions:
# ------------------------------------------------------------------------------
# commuting_fxn
# 
# gets the `from` nodes, and sends them as the parameter for the commuting_II_fxn
# along with the entire dataframe `nd_edges`.
#
# @param df the edge list dataframe (`nd_edges`

commuting_fxn = function(df) {
    i = unique(df$from)
    cr = lapply(i, commuting_II_fxn, df)
    cr = do.call(rbind, cr)
    return(cr)
}


## Testing commuting function---------------------------------------------------
## -----------------------------------------------------------------------------
set.seed(0)
test_comm = data.frame(from = rep(1:3, each = 3),
                       to = c(4:12),
                       pop_from = (rep(sample(1:200, 3), each = 3)),
                       pop_to = (sample(1:200, 9)),
                       Total_Length = (sample(200:300, 9)))

print(test_comm, row.names = FALSE)
 # from to pop_from pop_to Total_Length
 #    1  4      180    115          217
 #    1  5      180    181          268
 #    1  6      180     40          238
 #    2  7       53    177          275
 #    2  8       53    186          248
 #    2  9       53    129          299
 #    3 10       74    123          294
 #    3 11       74     12          235
 #    3 12       74    198          272

test_comm_calc = commuting_fxn(test_comm)


## For node 1 to node 6: row 3
m_i = 180
n_j = 40
T_i = 0.11 # 180 OR 0.11 DEPENDING ON FORMULA 
sum(test_comm$pop_to[ test_comm$Total_Length <= 238 &
                     test_comm$from == 1]) - n_j
s_ij = 115
T_ij1 = T_i * ( (m_i * n_j) / ((m_i + s_ij) * (m_i + n_j + s_ij)))
T_ij1
T_ij1 == test_comm_calc[3]

## For node 3 to node 10: row 7
m_i = 74
n_j = 123
T_i = 0.11 # 74 OR 0.11 DEPENDING ON FORMULA 
s_ij = 12 + 198
T_ij2 = T_i * ( (m_i * n_j) / ((m_i + s_ij) * (m_i + n_j + s_ij)))
T_ij2 == test_comm_calc[7]


# ==============================================================================
# Calculate commuting rate for dataset
# ==============================================================================
commuting_proportion = commuting_fxn(nd_edges)
nd_edges$commuting_prop = commuting_proportion

## SAVE FILE!!!
saveRDS(nd_edges, paste0("Data/", Sys.Date(), "_w-comm-prop.rds"))


## NOTE: Need to round off the population values since they're in decimal places
##       and that's clearly not possible in real life.
##       Figure out if I should round off before calculating comm rate or after
##       Ideally before. Since code is written it can be edited and re-executed!


## Select only those edges that have commuting rate > 0.001 (Hugo)
##                                OR individuals >= 1 (Mine)
## -----------------------------------------------------------------------------
# pruned_by_prop = nd_edges[ nd_edges$commuting_prop > 0.001, ]
pruned_by_ind = nd_edges[ (nd_edges$commuting_prop * nd_edges$pop_from) >= 1, ]

# saveRDS(pruned_by_prop, paste0("Data/", Sys.Date(), "_w-comm-prop-pruned.rds"))
saveRDS(pruned_by_ind, paste0("Data/", Sys.Date(), "_w-comm-ind-pruned.rds"))



################################################################################
## Add vert info (including commuting prop - sigma - to data
################################################################################

## Get nodes present in pruned data
pruned_verts = data.frame(name = as.character(
                              sort(
                                  as.numeric(
                                      unique(unlist(
                                          pruned_by_ind[ , c("from", "to")]))))),
                          stringsAsFactors = FALSE)


## Add node specific info from original data
pruned_verts_info = inner_join(pruned_verts, nd_verts, by = "name")



## Calculating Sigma (total commuting prop for each node------------------------
## -----------------------------------------------------------------------------
sigma_edges_fxn = function(edges) {
    from = unique(edges$from)
    sigma = lapply(from, function(from, edges) {
                            df = edges[ edges$from %in% from, ]
                            s = sum(df$commuting_prop)
                            df = data.frame(name = from,
                                            sigma = s,
                                            stringsAsFactors = FALSE)
        return(df)
    }, edges)
    sigma_df = do.call(rbind, sigma)
    return(sigma_df)
}


pruned_verts_sigma = sigma_edges_fxn(pruned_by_ind)

pruned_verts_info = left_join(pruned_verts_info, pruned_verts_sigma, "name")
pruned_verts_info$sigma[ is.na(pruned_verts_info$sigma) ] = 0



################################################################################
## Create and save graph file
################################################################################

## Create graph file
g_comm = graph_from_data_frame(pruned_by_ind,
                               directed = TRUE,
                               vertices = pruned_verts_info)


## Check that the info is correct in the graph:
## -----------------------------------------------------------------------------
df_comm = igraph::as_data_frame(g_comm, what = "both")

## Checking Kigali, the largest node, named "890". Its pop match Kigali's
df_comm$vertices[ df_comm$vertices$name == "890", ]

## head and tail, to make sure the names corroborate with the graph vertices
head(df_comm$vertices)
tail(df_comm$vertices)
head(df_comm$edges)
head(pruned_by_ind)


## Save the graph
## -----------------------------------------------------------------------------
write.graph(g_comm, paste0("Data/", Sys.Date(), "_graph-pruned-by-ind.graphml"),
            format = "graphml")



# ******************************************************************************
# ******************************************************************************
# ******************************************************************************
# ******************************************************************************
# ******************************************************************************


# ==============================================================================
# EDIT: 2017-08-01 Commuting rate after emoving nodes with <10 people in them
# ==============================================================================

# NOTE: the edges aren't pruned. All edges between nodes with at least 10
# people in them are kept, and commuting rate calculated. 10 was chosen
# as the cut-off number on my own, not in reference to anything.
# Node pruning was done because originally there were nodes with less than
# 1 people in them.

# Read original graph object
g = read.graph("data/graphml/2016-07-15_rwa-net.graphml", format="graphml")

# Convert graphml object to dataframe for further manipulation
df = igraph::as_data_frame(g, what = "both")

# Node information
nd_verts = df$vertices

# Remove nodes with less than 10 people in them
# sum(nd_verts$pop < 10)
nd_verts = nd_verts[ !nd_verts$pop < 10, ]
nodes = unique(nd_verts$name)           #unique nodes

# setdiff(df$vertices$name, nodes)

# Edges
nd_edges = df$edges[ df$edges$from %in% nodes & df$edges$to %in% nodes, ] 


## Adding population data to edges
## -----------------------------------------------------------------------------
pop_from = inner_join(nd_edges, nd_verts, by = c("from" = "name"))["pop"]
nd_edges$pop_from = pop_from$pop

pop_to = inner_join(nd_edges, nd_verts, by = c("to" = "name"))["pop"]
nd_edges$pop_to = pop_to$pop

commuting_proportion = commuting_fxn(nd_edges)
nd_edges$commuting_prop = commuting_proportion

# saving above file
saveRDS(nd_edges, paste0("Data/", Sys.Date(), "_w-comm-prop.rds"))


# Getting total sigma
# ------------------------------------------------------------------------------
# df_comm = nd_edges # saved as date_w-comm-prop.rds
df_comm = readRDS("data/graphml/2017-08-01_w-comm-prop.rds")
verts_info = nd_verts


# Calculating Sigma (total commuting prop for each node 
# ==============================================================================

verts_info$sigma = aggregate(commuting_prop ~ as.numeric(df_comm$from),
                             data = df_comm, FUN = sum)[["V1"]]

# rounding commuting proportion to 2 decimal places
verts_info$sigma = round(verts_info$sigma, 2)

# Create and save graph file
# ==============================================================================

## Create graph file
g_comm = graph_from_data_frame(df_comm,
                               directed = TRUE,
                               vertices = verts_info)


## Check that the info is correct in the graph:
## -----------------------------------------------------------------------------
df_comm2 = igraph::as_data_frame(g_comm, what = "both")

## Checking Kigali, the largest node, named "890". Its pop match Kigali's
df_comm2$vertices[ df_comm2$vertices$name == "890", ]

## head and tail, to make sure the names corroborate with the graph vertices
head(df_comm2$vertices, 10)
tail(df_comm2$vertices, 10)
head(df_comm2$edges)
head(df_comm)


## Save the graph
## -----------------------------------------------------------------------------
write.graph(g_comm, paste0("data/graphml/", Sys.Date(), "_graph-commuting.graphml"),
            format = "graphml")
