# ==============================================================================
#
# This code calculates the commuting rates between nodes in the graph
#
# ==============================================================================

g_sizes = c(5, 10, 100)

# Read in sample dataset
# ==============================================================================
g = lapply(g_sizes, function(g_size)
    readRDS(sprintf("inst/sample_data/network/g%d.RDS", g_size)))

# Calculate commuting rates over network
# ==============================================================================
comm_rate = 0.11

g_comm = lapply(g, function(ind_g, comm_rate) {
    disnet_commuting(ind_g, N_c = comm_rate)
}, comm_rate)


# Save new graph files with embedded commuting info
# ==============================================================================
out_dir = "inst/sample_data/commuting"
if(!dir.exists(out_dir)) dir.create(out_dir)

lapply(seq_along(g_comm), function(n, g_comm, g_sizes, out_dir) {
    f_out = sprintf("%s/g%d_comm.RDS", out_dir, g_sizes[[n]])
    saveRDS(g_comm[[n]], f_out)
}, g_comm, g_sizes, out_dir)



