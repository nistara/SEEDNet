% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/04_simulation.R
\name{disnet_simulate}
\alias{disnet_simulate}
\title{Main simulation function}
\usage{
disnet_simulate(nsims = 10, nsteps = 1000, sim_input = sim_intermed,
  sim_output_dir = getOption("disnetOutputDir", NA), parallel = FALSE,
  seed = 0)
}
\arguments{
\item{nsims}{The number of simulations to run. Default is 10}

\item{nsteps}{The number of timesteps you'd like each simulation to run
for. Default = 1000. It's set to a large value so that outbreaks can
run their course.}

\item{sim_input}{The file setup/created by disnet_sim_setup, which has
incorprated the foi, infection seeding, and/or vaccination campaign.}

\item{sim_output_dir}{The directory you'd like to save the simulation results to.}
}
\description{
This function wraps up all simulation sub-functins and applies them to
the intermediate sim files (created by `disnet_sim_setup`
}
\examples{
f = system.file("sample_data/network", "g10.RDS", package = "SEEDNet")
g = readRDS(f)
g_comm = disnet_commuting(g)
nodes = igraph::vcount(g_comm)
set.seed(890)
seed_nd = igraph::vertex_attr(g_comm, "name", sample(1:nodes, 1))
for_sim = disnet_sim_setup(g_comm, seed_nd = seed_nd, output_dir = NA)
simres = disnet_simulate(sim_input = for_sim)
}
