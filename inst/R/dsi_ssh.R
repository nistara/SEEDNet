if(FALSE) {
    devtools::install_github("duncantl/CallCounter")
    devtools::install_github("nistara/disnet")
}

library(igraph)

invisible(lapply(list.files("R", full = TRUE), source))

# *** read in data and make a subset of it
g = readRDS("inst/sampleData/flu-g.RDS")

g = igraph::induced.subgraph(g, c("890", sample(1:1000, 200)))

# *** calculate commuting rates over it
g_comm = disnet_commuting2(g)

# *** set up the network for simulations
for_sim = disnet_sim_setup(g_comm, seed_nd = "890", output_dir = NA)

t = Sys.time()
# *** run the simulations over the network and calc time for it too
simres = disnet_simulate(sim_input = for_sim, sim_output_dir = NA, nsims=500)
Sys.time() -  t

# using comp2_i_fxn: time = Time difference of 6.249922 mins
# usinf master branch: time = 
