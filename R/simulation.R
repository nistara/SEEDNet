#' Main simulation function
#'
#' This function wraps up all simulation sub-functins and applies them to
#' the intermediate sim files (created by `disnet_sim_setup`
#'
#' @param nsims The number of simulations to run. Default is 10
#' @param nsteps The number of timesteps you'd like each simulation to run
#' for. Default = 1000. It's set to a large value so that outbreaks can
#' run their course.
#' @param sim_input The file setup/created by disnet_sim_setup, which has
#' incorprated the foi, infection seeding, and/or vaccination campaign.
#' @param sim_output_dir The directory you'd like to save the simulation results to.
#'
#' @examples
#' f = system.file("sampleData", "g.rds", package = "disnet")
#' g = readRDS(f)
#' g_comm = disnet_commuting(g)
#' nodes = igraph::vcount(g_comm)
#' set.seed(890)
#' seed_nd = igraph::vertex_attr(g_comm, "name", sample(1:nodes, 1))
#' for_sim = disnet_sim_setup(g_comm, seed_nd = seed_nd, output_dir = NA)
#' simres = disnet_simulate(sim_input = for_sim)

#' @export

disnet_simulate = function(nsims = 10,
                   nsteps = 1000,
                   sim_input = sim_intermed,
                   sim_output_dir = getOption("disnetOutputDir", NA),
                   parallel = FALSE)
{
    # create directory to store results in
    if(!is.na(sim_output_dir) && !dir.exists(sim_output_dir)) {
        dir.create(sim_output_dir)
    }
    # start simulation message
    message("\nStarting simulations\n")
    # set seed to ensure replicability
# Clark: Let the user set the seed before they call this function.
    set.seed(0)
    # simulations
    this_lapply = if(parallel) parallel::mclapply else lapply

# Clark: Better to use replicate() or parallel::clusterEvalQ() to avoid
# passing the objects start_TS, etc.

    sim_res = this_lapply(1:nsims, disnet_sim_lapply,
                     nsteps,
                     start_TS = sim_input$start_TS,
                     vert_list = sim_input$vert_list,
                     j_out = sim_input$j_out,
                     params = sim_input$params,
                     sim_dir = sim_output_dir)
    return(sim_res)
}

# For testing
if(FALSE){
nsims = 1
nsteps = 10
sim_input = for_sim
sim_output_dir = getOption("disnetOutputDir", "disnet_output_dir")

sim = 1
nsteps = 10
start_TS = sim_input$start_TS
vert_list = sim_input$vert_list
j_out = sim_input$j_out
params = sim_input$params
sim_dir = NA
}
