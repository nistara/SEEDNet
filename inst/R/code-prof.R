if(FALSE) {
    devtools::install_github("duncantl/CallCounter")
    devtools::install_github("nistara/disnet")
}

#library(disnet)
invisible(lapply(list.files("../../R", full = TRUE), source))
library(CallCounter)

# ==============================================================================
# Profiling
# ==============================================================================

# ctr and rprof-----------------------------------------------------------------
funs = as.character(ls.str("package:disnet"))

ctr = countMCalls(funs = funs)
g = readRDS("../sampleData/flu-g.RDS")

drivelink = "https://drive.google.com/drive/folders/1LXWqX_cBLV2pyA_b3kdqHPiyQTcTN_zU?usp=sharing"

g = igraph::induced.subgraph(g, c("890", sample(1:1000, 200)))

Rprof("prof_disnet_comm.out")
# calculate commuting rates over it
g_comm = disnet_commuting(g)
Rprof(NULL)
saveRDS(ctr$value(), "ctr_disnet_comm.RDS")


if( FALSE){
    g_comm = readRDS("~/Drive/projects/ebo-net/data/flu-g_comm.RDS")
}

ctr = countMCalls(funs = funs)
Rprof("prof_disnet_setup.out")
# set up the network for simulations
for_sim = disnet_sim_setup(g_comm, seed_nd = "890", output_dir = NA)
Rprof(NULL)
saveRDS(ctr$value(), "ctr_disnet_setup.RDS")

if(FALSE){
    for_sim = readRDS("~/Drive/projects/ebo-net/data/flu-g_forsim.RDS")
}

ctr = countMCalls(funs = funs)
ctr = countMCalls(funs = c("comp2_i_fxn", "l_ji_fxn", "disnet_foi", "[[.data.frame"))
Rprof(profFile <- "prof_disnet_sim.out")
# run the simulations over the network
simres = disnet_simulate(sim_input = for_sim, sim_output_dir = NA, nsims=20)
Rprof(NULL)
saveRDS(ctr$value(), "ctr_disnet_sim.RDS")


# Call stack--------------------------------------------------------------------

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
}, g)

saveRDS(disnet_CallStack, "disnet_CallStack.RDS")


# ==============================================================================
# Reading in profiling data
# ==============================================================================
if(FALSE){
    funs = as.character(ls.str("package:disnet"))
    ctr = lapply(list.files("inst/r-prof-out",
                            pattern = "ctr_",
                            full.names = TRUE), readRDS)
    prof = lapply(list.files("inst/r-prof-out",
                             pattern = "prof_",
                             full.names = TRUE), summaryRprof)
    call_stack = readRDS("inst/r-prof-out/disnet_CallStack.RDS")
}



