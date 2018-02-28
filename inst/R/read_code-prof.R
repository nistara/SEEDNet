# ==============================================================================
# Script to load code profiling results
# ==============================================================================

# THE RESULTS FOLDER: disnet/inst/r-prof-out/

# The results of "ctr" and "prof" are dividied into 3 sections:
# ------------------------------------------------------------------------------
# 
# 1. Commuting calculation part:
# g_comm = disnet_commuting(g)
#
# 2. Pre-simulation setup part:
# for_sim = disnet_sim_setup(g_comm, seed_nd = "890")
#
# 3. Simulation part:
# simres = disnet_simulate(sim_input = for_sim, nsims = 2)
#

# Function counter
ctr = lapply(list.files("inst/r-prof-out",
                        pattern = "ctr_",
                        full.names = TRUE), readRDS)
length(ctr)


prof = lapply(list.files("inst/r-prof-out",
                         pattern = "prof_",
                         full.names = TRUE), summaryRprof)
length(prof)


# Results of genStackCollector
# ------------------------------------------------------------------------------

# Call stack information generated for each function (n = 19) called in the code.
# And for each function, there exists the call stack, and the function
# names (callNames) that called the function. 
call_stack = readRDS("inst/r-prof-out/disnet_CallStack.RDS")
names(call_stack)
names(call_stack[[1]])
