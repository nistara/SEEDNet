# disnet
Compiling the existing code and data into a package for better collaboration.

`disnet` has been designed to simulate influenza (for now) over a network created
by combining satellite imagery, population data, and road network information. The intent is to generalize it for other diseases, focusing on Ebola for now.  

## Example datasets
While a smaller example dataset is included in `inst/sampleData`, the bigger examples can be found in this [Google Drive link](https://drive.google.com/open?id=1Mr6PKOlWHHRE_rl9d4-ZgtIO822DpwdM). They include:
1. `g_raw.RDA`: For using with `disnet_commuting()`
2. `g.RDA`: For using with `disnet_sim_setup()`
3. `sim_intermed.RDA`: To run the `disnet_simulation()` function with. 

## Compartmental disease model
Discrete time, stochastic, metatpopulation model. 

In case of influenza, the compartmental model is SEIR:

S - Susceptible
E - Latent
I - Infectious
R - Recovered

## Main functions
1. `disnet_commuting` - Comuting function. Takes in network object (in `graphml` format), and calculates the commuting rates for all outgoing edges in network
   
2. `disnet_sim_setup` - Simulation setup function. Takes in the graph file with commuting rates added to it, and preps it up for runnning simulations. 

3. `disnet_simulate` - Simulation function. This function runs the disease model simulations over the network. 


```r
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

simres2 = disnet_simulate(sim_input = for_sim, sim_output_dir = NA,
parallel = TRUE)
```

## Sample datasets
- `g.RDS`: The raw graphml/network object

To access the sample dataset:

```r
f = system.file("sampleData", "g.rds", package = "disnet")
g = readRDS(f)
```

**Note**: The steps to convert the ArcGIS output to raw `g` network have not yet been included.

