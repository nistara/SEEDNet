---
title: "disnet"
author: "Nistara Randhawa, Duncan Temple Lang"
date: "2018-02-16"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{disnet}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



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

# set up the graph/network for simulations
for_sim = disnet_sim_setup(g_comm)

# run the simulations
simres = disnet_simulate(for_sim)
```

## Sample datasets
- `g.RDS`: The raw graphml/network object which we calculate commuting rates. 

To access the sample dataset:

```r
f = system.file("sampleData", "g.rds", package = "disnet")
g = readRDS(f)
```

**Note**: The steps to convert the ArcGIS output to raw `g` network have not yet been included.


