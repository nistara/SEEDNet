
SEEDNet
=======

[![Build Status](https://travis-ci.com/nistara/SEEDNet.svg?token=NzZHVjGpzy5BDLtSKxLg&branch=master)](https://travis-ci.com/github/nistara/SEEDNet)

`SEEDNet` has been designed to simulate outbreaks over a network created by combining satellite imagery, population data, and road network information. It is versatile in that it can be used for any metapopulation model on networks with distance and population data.

![](https://raw.githubusercontent.com/nistara/SEEDNet/master/inst/sim_anim.gif?token=AC4OAU77IVHOLJXC5Y37NLS7R7OVI)

Installation
------------

Run the following:

``` r
remotes::install_github("nistara/SEEDNet")
```

``` r
library("SEEDNet")
```

Compartmental disease model
---------------------------

Discrete time, stochastic, metatpopulation model.

In case of influenza, the compartmental model is SEIR:

S - Susceptible E - Latent I - Infectious R - Recovered

Main functions
--------------

1.  `disnet_commuting` - Comuting function. Takes in network object (in `graphml` format), and calculates the commuting rates for all outgoing edges in network

2.  `disnet_sim_setup` - Simulation setup function. Takes in the graph file with commuting rates added to it, and preps it up for runnning simulations.

3.  `disnet_simulate` - Simulation function. This function runs the disease model simulations over the network.

``` r
library("disnet")

# Read in sample graph/network
f = system.file("sampleData", "g.rds", package = "disnet")
g = readRDS(f)

# calculate commuting rates over it
g_comm = disnet_commuting(g)

# select random node to seed infection in
set.seed(890)
nodes = igraph::vcount(g_comm)
seed_nd = igraph::vertex_attr(g_comm, "name", sample(1:nodes, 1))

# set up the network for simulations
for_sim = disnet_sim_setup(g_comm, seed_nd = seed_nd, output_dir = NA)

# run the simulations over the network
simres = disnet_simulate(sim_input = for_sim, sim_output_dir = NA)
```

Sample datasets
---------------

-   `g.RDS`: The raw graphml/network object

To access the sample dataset:

``` r
f = system.file("sampleData", "g.rds", package = "disnet")
g = readRDS(f)
```

Contributing and Support
------------------------

If you would like to contribute to this software, please submit a pull request to the [GitHub repository](https://github.com/nistara/SEEDNet). Feel free to report issues, provide feedback, suggest improvements, and ask questions by [opening a new issue](https://github.com/nistara/SEEDNet/issues).
