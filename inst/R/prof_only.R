if(FALSE) {
    devtools::install_github("duncantl/CallCounter")
    devtools::install_github("nistara/disnet", "stash1")
}

#library(disnet)
invisible(lapply(list.files("R", full = TRUE), source))
funs = as.vector(lsf.str())

library(CallCounter)


# *** Profiling ----------------------------------------------------------------
if(FALSE)
{
    g = readRDS("~/Drive/projects/ebo-net/data/flu-net_data/flu-g.RDS")
    g = igraph::induced.subgraph(g, c("890", sample(1:1000, 200)))
    saveRDS(g, "inst/sampleData/g_200nds.RDS")
    g = readRDS("inst/sampleData/g_200nds.RDS")
    g_comm = disnet_commuting(g)
    saveRDS(g_comm, "inst/sampleData/g_comm_200nds.RDS")
    for_sim = disnet_sim_setup(g_comm, seed_nd = "890", output_dir = NA)
    saveRDS(for_sim, "inst/sampleData/for_sim_200nds.RDS")
}


for_sim = readRDS("inst/sampleData/for_sim_200nds.RDS")

ctr = countMCalls(funs = funs)
Rprof("inst/r-prof-out/sim_200nds.out")
# run the simulations over the network
simres = disnet_simulate(sim_input = for_sim, sim_output_dir = NA,
                         nsims=100)
Rprof(NULL)
saveRDS(ctr$value(), "ctr_sim_200nds.RDS")

# *** Prof summary--------------------------------------------------------------

summaryRprof("inst/r-prof-out/sim_200nds.out")
ctr$value()


# *** Call stack----------------------------------------------------------------
if(FALSE)
{
    if(FALSE)
    {

        g_callStack = igraph::induced.subgraph(g, c("890", sample(igraph::V(g)$name, 25)))
        saveRDS(g_callStack, "inst/sampleData/g_callStack.RDS")
        g_callStack = readRDS("inst/sampleData/g_callStack.RDS")
        
    }

    g_callStack = readRDS("inst/sampleData/g_callStack.RDS")

    sim = function(g){
        g_comm = disnet_commuting(g)
        for_sim = disnet_sim_setup(g_comm, seed_nd = "890")
        simres = disnet_simulate(sim_input = for_sim, nsims = 2, nsteps = 10)
        return(NULL)
    }


    disnet_callStack = lapply(setNames(funs, funs), function(f, g) {
        print(f)
        # functions
        st = genStackCollector( num = 500)
        trace(f, st$update, print = FALSE)
        sim(g)
        call_stack = ifelse(length(st$value()) == 0, NA, st$value()[[1]])
        # names
        st_names = genStackCollector(callNames, num = 500)
        trace(f, st_names$update, print = FALSE)
        sim(g)
        fun_names = ifelse(length(st_names$value()) == 0, NA, st_names$value()[[1]])
        # return
        list(call_stack = call_stack, fun_names = fun_names)
    }, g_callStack)

    saveRDS(disnet_callStack, "disnet_CallStack.RDS")

}




