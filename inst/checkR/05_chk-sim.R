# ==============================================================================
# Read in pre-sim files, run simulations, and check results
# ==============================================================================


# ** Simulation info
seed_inf_no = 1
seed_row = 890


# ** Set number of simulations and timesteps
nsims = 50
nsteps = 100


# ** set up future_lapply for parallelizing simulation runs
# ------------------------------------------------------------------------------
parallel = FALSE


# * Read in saved sim-setup files and specify simulation parameters
# ==============================================================================
presim_file = list.files("inst/sample_data/pre-sim/890",
                          pattern = "seed-1-in-890",
                          full.names = TRUE)

for_sim = readRDS(presim_file)



# Set directory to save sim results in------------------------------------------
sim_output_dir = sprintf("inst/sample_data/simres/%s-sims_seed-%s-in-nd%s/",
                         nsims, seed_inf_no, seed_row)


# * Run simulations
# ==============================================================================
disnet_simulate(sim_input = for_sim,
                sim_output_dir = sim_output_dir,
                nsims = nsims,
                nsteps = nsteps,
                parallel = parallel)

simres = disnet_simulate(sim_input = for_sim,
                nsims = nsims,
                nsteps = nsteps,
                parallel = parallel)

sims = lapply(simres, `[[`, 1)
sims_info = lapply(simres, `[[`, 2)


# ** Check no. of simulations
# ------------------------------------------------------------------------------
length(simres) == nsims


# ** Check max number of timesteps
# ------------------------------------------------------------------------------
# Should not exceed nsteps
all(sapply(sims, length) <= nsteps)

# Note: the following check might be modified later if the info
# data is exported as a data.frame/matrix from the getgo
# Right now those sims that didn't take off are numeric vector entities
# vs matrices for those that lasted a day or longer
all(sapply(sims_info, function(sim_info, nsteps) {
    if( class(sim_info) == "matrix" ) {
        df = sim_info

    } else {
        df = as.matrix(t(sim_info))
    }
    nrow(df) <= nsteps
}, nsteps))


# ** Check that each simres result is a data frame
# ------------------------------------------------------------------------------
all(sapply(sims, function(sim)
    all(sapply(sim, function(sim_step) class(sim_step) == "data.frame"))))


# ** Check that each simres result has the correct nodes
# ------------------------------------------------------------------------------
g_comm_f = list.files("inst/sample_data/commuting", pattern = "100",
                      full.names = TRUE)
g_comm = readRDS(g_comm_f)
nodes = igraph::as_data_frame(g_comm, "vertices")$name

all(sapply(sims, function(sim, nodes) {
    all(sapply(sim, function(sim_step, nodes) {
        all(sim_step$name %in% nodes)
        }, nodes))
}, nodes))


# ** Check that each simres length is the same as sim_info
# ------------------------------------------------------------------------------
# Note: the following check might be modified later if the info
# data is exported as a data.frame/matrix from the getgo
# Right now those sims that didn't take off are numeric vector entities
# vs matrices for those that lasted a day or longer

all(sapply(simres, function(simres_ind) {
    info = simres_ind$info
    sims = simres_ind$timeStep
    if( class(info) == "matrix" ) {
        info_df = info
    } else {
        info_df = as.matrix(t(info))
    }
    nrow(info_df) == length(sims)
}))



    

        


