# disnet
Compiling the existing code and data into a package for better collaboration.

## From the vignette:

`disnet` has been designed to simulate influenza over a network created
by combining satellite imagery, population data, and road network information. 

## Main functions

1. `disnet_commuting` - Comuting function. Takes in network object (in `graphml` format, and calculates the commuting rates for all outgoing edges in network
   
2. `disnet_sim_setup` - Simulation setup function. Takes in the graph file with commuting rates added to it, and preps it up for runnning simulations. 
   *NOTE*: This function will create a folder in `supplement/data/intermed` to save the resulting data. You can specify a different folder. 

3. `disnet_simulate` - Simulation function. This function runs the simulations
   *NOTE*: This function will create a folder in `supplement/data/simulation-results` (unless you specify a different folder) in your working directory, so it can save the simulation results. 


```r
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


## Sample datasets
- `g.RDS`: The raw graphml/network object which we calculate commuting rates. 

To access the sample dataset:

```r
f = system.file("sampleData", "g.rds", package = "disnet")
g = readRDS(f)
```

**Note**: The steps to convert the ArcGIS output to raw `g` network have not yet been included.


