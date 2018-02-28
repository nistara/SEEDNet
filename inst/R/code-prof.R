# devtools::install_github("nistara/CallCounter")
# devtools::install_github("nistara/disnet")

library(disnet)
library(CallCounter)

# ==============================================================================
# Profiling
# ==============================================================================

# ctr and rprof-----------------------------------------------------------------
funs = as.character(ls.str("package:disnet"))

ctr = countMCalls(funs = funs)
g = readRDS("~/Drive/projects/ebo-net/data/flu-g.RDS")
Rprof("prof_disnet_comm.out")
# calculate commuting rates over it
g_comm = disnet_commuting(g)
Rprof(NULL)
saveRDS(ctr$value(), "ctr_disnet_comm.RDS")


ctr = countMCalls(funs = funs)
g_comm = readRDS("~/Drive/projects/ebo-net/data/flu-g_comm.RDS")
Rprof("prof_disnet_setup.out")
# set up the network for simulations
for_sim = disnet_sim_setup(g_comm, seed_nd = "890", output_dir = NA)
Rprof(NULL)
saveRDS(ctr$value(), "ctr_disnet_setup.RDS")


ctr = countMCalls(funs = funs)
for_sim = readRDS("~/Drive/projects/ebo-net/data/flu-g_forsim.RDS")
Rprof("prof_disnet_sim.out")
# run the simulations over the network
simres = disnet_simulate(sim_input = for_sim, sim_output_dir = NA)
Rprof(NULL)
saveRDS(ctr$value(), "ctr_disnet_sim.RDS")


# Call stack--------------------------------------------------------------------
g_subset = igraph::induced.subgraph(g, c("890", sample(1:1000, 10)))

sim = function(g){
    g_comm = disnet_commuting(g)
    for_sim = disnet_sim_setup(g_comm, seed_nd = "890")
    simres = disnet_simulate(sim_input = for_sim, nsims = 2)
    return(NULL)
    }


disnet_CallStack = lapply(setNames(funs, funs), function(f, g) {
    # functions
    st = genStackCollector( num = 500)
    trace(f, st$update, print = FALSE)
    sim(g)
    call_stack = st$value()[[1]]
    # names
    st_names = genStackCollector(callNames, num = 500)
    trace(f, st_names$update, print = FALSE)
    sim(g)
    fun_names = st_names$value()[[1]]
    # return
    list(call_stack = call_stack, fun_names = fun_names)
}, g = g_subset)

saveRDS(disnet_CallStack, "disnet_CallStack.RDS")


# ==============================================================================
# Reading in profiling data
# ==============================================================================
funs = as.character(ls.str("package:disnet"))
ctr = lapply(list.files(pattern = "ctr_"), readRDS)
prof = lapply(list.files(pattern = "prof_"), summaryRprof)
call_stack = readRDS("disnet_CallStack.RDS")
