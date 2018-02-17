################################################################################
# This code:
# 1. Reads in an igraph object (with commuting proportions previously
#      calculated)
# 
# 2. Calculates and attaches  "Effective Population" to graph
#
# 3. Seeds a node with specified number of infectious individuals (taking them
#      out from the Susceptibles and adding to Infectious compartment
#
# 4. Creates the FOI structure/scaffold used to quickly calculate FOI
#      (FOI = Force of Infection, acting on an individual in a node)
#
# 5. Simulates simplified SEIR models
################################################################################



# Libraries
# -----------------------------------------------------------------------------
library(igraph)
library(dplyr)

# ==============================================================================
# Parameter references for pandemic 2009 H1N1:
# ==============================================================================
# Tuite, Ashleigh R., Amy L. Greer, Michael Whelan, Anne-Luise Winter,
# Brenda Lee, Ping Yan, Jianhong Wu, et al. 2010. “Estimated Epidemiologic
# Parameters and Morbidity Associated with Pandemic H1N1 Influenza.”
# CMAJ: Canadian Medical Association Journal =
# Journal de l’Association Medicale Canadienne 182 (2): 131–36.
# 
# Tuite, Ashleigh R., Amy L. Greer, Michael Whelan, Anne-Luise Winter, Brenda
# Lee, Ping Yan, Jianhong Wu, et al. 2010. “Estimated Epidemiologic Parameters
# and Morbidity Associated with Pandemic H1N1 Influenza.” CMAJ: Canadian
# Medical Association Journal = Journal de l’Association Medicale Canadienne
# 182 (2): 131–36.
#
# Longini, Ira M., Jr, Azhar Nizam, Shufu Xu, Kumnuan Ungchusak, Wanna
# Hanshaoworakul, Derek A. T. Cummings, and M. Elizabeth Halloran. 2005.
# “Containing Pandemic Influenza at the Source.” Science 309 (5737): 1083–87.
# 
# 
# currently unused: https://www.ncbi.nlm.nih.gov/pubmed/19545404
# -----------------------------------------------------------------------------

r0 = 1.44 # Pourbohloul
latent_period = 2.62 # Tuite
inf_period = 3.38 # Tuite
mu = 1/inf_period
tau = 3 # Return rate
r_beta = 0.50 # Longini 2005
p_a = 1/3 # Lonigni 2005

beta = (r0 * mu)/((r_beta * p_a) + (1 - p_a)) # from balcan pg 143

# # ranges
# r0_range = seq(1.38, 1.51, length.out = 10)
# beta_range = r0_range/inf_period
# latent_period_range = seq(2.28, 3.12, length.out = 10)
# inf_period_range = seq(2.06, 4.69, length.out = 10)
# ## p_no_traveling= 0.045
# ## p_travel = 1 - p_no_traveling
# ## p_travel = 1    # no restructions on traveling



# ==============================================================================
# Load functions
# ==============================================================================
source("src/R/simulation-fxns.r")


# ==============================================================================
# Read in graph data and get it ready for simulations
# ==============================================================================

# Read graph with commuting info
g = read.graph("data/graphml/2017-08-01_graph-commuting.graphml",
               format = "graphml")


if(FALSE) {
    print("using old pruned by individuals graph.")
          g = read.graph("data/graphml/2016-08-18_graph-pruned-by-ind.graphml",
                         format = "graphml")
}


# ## Not really needed, but helpful initially in understanding graph structure
# verts = igraph::as_data_frame(g, "vertices")
# edges = igraph::as_data_frame(g, "edges")

## neighbors(g, "0", mode = "all") # e.g. of finding neighbors for node "0"


################################################################################
## Calculate effective population and other required variables
################################################################################


## Calculate effective population and add it as a vertex attribute to graph
## -----------------------------------------------------------------------------
g = effpop_takeII(g, tau = 3)


## Calculate sigma by tau values (to avoid recalculation each time)
## -----------------------------------------------------------------------------
## sigma_by_tau refers to the vertex attribute sigma (the proportion of a
##      node's population that is commuting) divided by the tau value (return
##      rate) specified by us

## sigmaProp_by_tau is the edge attribute (commuting_prop) which specifies the
##      proportion of a node's population commuting to another specified node)
##      divided by tau

g = add_sigmas_fxn(g, tau)

## ## For e.g., considering the first edge, we see that its name is "0|4"
## str(E(g)[1])

## ## The proportion of individuals of node "0" commuting to "4" is:
## edge_attr(g, "commuting_prop", index = paste0(0, "|", 4))
## cp = edge_attr(g, "commuting_prop", index = paste0(0, "|", 4))

## ## The above proportion divided by tau is sigmaProp_by_tau:
## cp/3

## ## Which is what we assigned as an edge attribute in the graph
## edge_attr(g, "sigmaProp_by_tau", index = paste0(0, "|", 4))


################################################################################
## Initializing the Time Step list and data frame
################################################################################

## This is a dataframe containing the node names along with their respective
##      compartment values (SEIR). It is used to calculate FOI and passed into
##      the simulations.
##      To begin with, S is the node population, and EIR are all 0
start_TS = start_TS_fxn(g)


################################################################################
## Seeding node of interest
################################################################################

## Takes in the inititalized start_TS dataframe, the node to be seeded, along
##      with the number of infectious individuals. It removes individuals from
##      the S to I compartments.

start_TS = seed_nd_fxn(start_TS, "890", 1)

# # checking;
# seed_row = which(start_TS$name == "890")
# start_TS[seed_row, ]

# Total population at this time:
# sum(start_TS[ , c("S", "I")])
# 1002672


################################################################################
## Force of infection: May the force be with you ^^
################################################################################

## Getting vert specific info for FOI:
## -----------------------------------------------------------------------------
## This is done to simplify foi calculations. "vert_info" contains:
## 
##      1. name: node name
##         ---- 
## 
##      2. eff_pop: effective population
##         ------ 
## 
##      3. sigma_by_tau: the total commuting proportion for a node (sigma)
##         ------------  divided by the return rate (tau)
## 
##      4. b_by_n: the beta coefficient divided by the effective population
##         ------
## 
##      5. sigma_by_tau_p1:  sigma_by_tau + 1
##         ---------------  (p1 stands for plus 1)


vert_info = get_vertInfo_fxn(g, beta)


## j_in information for lambda_jj part of FOI formula
## -----------------------------------------------------------------------------
## For each incoming edge to j (the "i"s in lambda_jj part of FOI formula),
## essentially, the second component info for lambda_jj:
##      1. name of neighbors commuting to node
##      2. sigma_by_tau_p1: sigma_by_tau + 1
##      3. sigmaProp_by_tau: proportion of neighbor pop commuting to node

j_in = j_in_fxn(vert_info, g)



## j_out information for lambda_ji part of FOI formula
## -----------------------------------------------------------------------------
## For each outgoing edge from j (the "i"s in the lambda_ji part of FOI formula):
##      1. name of neighbors to which node is commuting to
##      2. sigmaProp_by_tau: proportion of node pop commuting to neighbor

j_out = j_out_fxn(vert_info, g)



## component 1 and 2 (sub)
## -----------------------------------------------------------------------------
## essentially the scaffold, to which "I" information is added to yield FOI
comp1_sub = 1/vert_info$sigma_by_tau_p1
comp2_sub = lapply(setNames(j_in, names(j_in)), comp2_sub_fxn)




## Defining vert_list, which contains all information needed for FOI
## -----------------------------------------------------------------------------
vert_list = list(vert_info = vert_info,
                 comp1_sub = comp1_sub,
                 comp2_sub = comp2_sub,
                 j_in = j_in,
                 j_out = j_out)


start_TS$foi = foi_fxn(start_TS, vert_list, j_out)


# ==============================================================================
# Saving pre-simulation parameters
# ==============================================================================
# To make it easier to load sim inputs and run simulations, instead of loading
# the graph and running the above each time

# NOTE: If the infection parameters change, the above will have to be run again!
# coz of beta, which is in the formula

if(FALSE) {
    params = list(
        exit_latent_I = ((1/latent_period) * (1 - p_a)),
        exit_latent_Ia =  ((1/latent_period) * p_a),
        mu = 1/inf_period)


    sim_input = list(
        start_TS = start_TS,
        vert_list = vert_list,
        j_out = j_out,
        params = params)


    sim_input_name = sprintf("sim-input_%s.RDS", "2017-08-01_graph-commuting")

    saveRDS(sim_input, paste0("data/intermed-sim/", sim_input_name))
}


# ==============================================================================
# Simulations
# ==============================================================================

# Read in saved simulation parameters-------------------------------------------
# last sim_input_name was "sim-input_2017-08-01_graph-commuting.RDS"
sim_input = readRDS("data/intermed-sim/sim-input_2017-08-01_graph-commuting.RDS")

# Set number of simulations and timesteps---------------------------------------
nsims = 1000
nsteps = 1000

# Other simulation info---------------------------------------------------------
seed_inf_no = 1
seed_row = 890

# Set directory to save sim results in------------------------------------------
sim_dir = sprintf("data/simulations/%s_%s-sims_seed-%s-in-nd%s/",
                  Sys.Date(), nsims, seed_inf_no, seed_row)

# Simulations-------------------------------------------------------------------
sims = sim_fxn(nsims, nsteps, sim_input, sim_dir)


# Saving sim results------------------------------------------------------------
saveRDS(sims, sprintf("data/simulations/%s_%s-sims_seed-%s-in-nd%s.rds",
                      Sys.Date(), nsims, seed_inf_no, seed_row))



# 
# 
# sim1 = sims[1:1000]
# sim2 = sims[1001:2000]
# 
# saveRDS(sim1, sprintf("Data/simulations/%s_seed-%s-in-nd-%s-1to1000.rds",
#                       Sys.Date(), seed_inf_no, seed_row))
# 
# saveRDS(sim2, sprintf("Data/simulations/%s_seed-%s-in-nd-%s.rd-1001to2000s",
#                       Sys.Date(), seed_inf_no, seed_row))



# ## miscellaneous
# length(sims[[1]])
# t = sims[[1]][[100]]
# table(t$I)
# which(t$I > 0)
# which(t$E > 0)

