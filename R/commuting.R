# ==============================================================================
# This code calculates the commuting rates between nodes in the graph
#
# There are 1606 nodes, and 2577630 edges (after removing the self edges:
#      (1606 * 1606) - 1606 = 2577630
#      NOTE: they go from 0-1605, not 1-1606
#            the matrix is arranged from smallest distance to largest one
# ==============================================================================


# Functions for commuting rate (removing nodes with < 10 people)
# ==============================================================================

#' Commuting function
#'
#' `disnet_commuting` gets the `from` nodes, and sends them as the parameter for
#' the disnet_comm2 along with the entire dataframe `nd_edges`.
#' It incoporates both the individual and all nodes' functions
#'
#' @param g The `graphml` (network) object for which to calculate commuting rates
#'
#' @examples
#' f = system.file("sampleData", "g.rds", package = "disnet")
#' g = readRDS(f)
#' disnet_commuting(g)
#' @export

disnet_commuting = function(g)
{
    comm_info = disnet_comm3(g)
    nd_edges = comm_info$nd_edges
    i = unique(nd_edges$from)
    cr = lapply(i, disnet_comm2, nd_edges)
    nd_edges$commuting_prop = do.call(rbind, cr)

    verts_info = comm_info$nd_verts

    # Calculating Sigma (total commuting prop for each node
    verts_info$sigma = aggregate(commuting_prop ~ as.numeric(nd_edges$from),
                                 data = nd_edges, FUN = sum)[["V1"]]

    # rounding commuting proportion to 2 decimal places
    verts_info$sigma = round(verts_info$sigma, 2)

    ## Create graph file
    g_comm = igraph::graph_from_data_frame(nd_edges,
                                           directed = TRUE,
                                           vertices = verts_info)

    if(FALSE){
        # Check that the info is correct in the created graph:
        nd_edges2 = igraph::as_data_frame(g_comm, what = "both")

        # Checking Kigali, the largest node, named "890". Its pop match Kigali's
        nd_edges2$vertices[ nd_edges2$vertices$name == "890", ]

        # head and tail, to make sure the names corroborate with the graph vertices
        head(nd_edges2$vertices, 10)
        tail(nd_edges2$vertices, 10)
        head(nd_edges2$edges)
        head(nd_edges)

        # Save the graph
        write.graph(g_comm, paste0("data/graphml/", Sys.Date(), "_graph-commuting.graphml"),
                    format = "graphml")

    }

    g_comm
}

# ==============================================================================

#' disnet_comm1
#'
#' gets commuting rate for each individual node (hence it's for individual nodes)
#' Considers a commuting proportion of 11% for the entire population
#' @param i the node for which commuting proportion is being calculated
#' @param edges_subset subset of `nd_edges` with all outgoing edges of `i`
#' @param j all the nodes `i` is connected to

disnet_comm1 = function(j, edges_subset, i) {
    radius = edges_subset$Total_Length[ edges_subset$to %in% j]
    df_radius = edges_subset[ edges_subset$Total_Length <= radius, ]
    m_i = df_radius$pop_from[1]
    n_j = df_radius$pop_to[ df_radius$to %in% j]
    s_ij = sum(df_radius$pop_to[ df_radius$to != j])
    N_c = 0.11 # using 0.11 as commuting proportion from Simini paper
    N = 1 # to get 0.11 as proportion
    T_i = (N_c/N) # want only rate, not num people. original:  m_i * (N_c/N)
    T_ij = T_i * ( (m_i * n_j) / ((m_i + s_ij) * (m_i + n_j + s_ij)) )
    T_ij
}

# ==============================================================================

#' disnet_comm2
#'
#' Gets commuting rate for all nodes (includes individual node function)
#'
#' @param i id of the `from` node, for which we want to calculate commuting
#' proportion
#' @param test_edges the dataframe of the edges which contains the distances
#' between the nodes and the population of each edges's
#                   `from` and `to nodes.

disnet_comm2 = function(i,test_edges) {
    edges_subset = test_edges[ test_edges$from %in% i, ]
    all_j = edges_subset$to
    print(paste0("working on node: ", i))

    comm_rate = lapply(all_j, disnet_comm1, edges_subset, i)
    comm_rate = do.call(rbind, comm_rate)
    return(comm_rate)
}

# ==============================================================================

#' disnet_comm3
#'
#' Preps the incoming graph for commuting rate calculation
#'
#' @param g graph whose commuting rate needs to be calculated
#'

disnet_comm3 = function(g){
    
    # Convert graphml object to dataframe for further manipulation
    df = igraph::as_data_frame(g, what = "both")

    # Node information
    nd_verts = df$vertices

    # Remove nodes with less than 10 people in them
    # sum(nd_verts$pop < 10)
    nd_verts = nd_verts[ !nd_verts$pop < 10, ]
    nodes = unique(nd_verts$name)           #unique nodes

    # Edges
    nd_edges = df$edges[ df$edges$from %in% nodes & df$edges$to %in% nodes, ] 

    # Adding population data to edges
    # -----------------------------------------------------------------------------
    pop_from = dplyr::inner_join(nd_edges, nd_verts, by = c("from" = "name"))["pop"]
    nd_edges$pop_from = pop_from$pop

    pop_to = dplyr::inner_join(nd_edges, nd_verts, by = c("to" = "name"))["pop"]
    nd_edges$pop_to = pop_to$pop
    list(nd_verts = nd_verts, nd_edges = nd_edges)
}


