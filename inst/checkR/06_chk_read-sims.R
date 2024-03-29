

results_dir = paste0("inst/sample_data/results")
if(!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

nd = 890

sim_dir = "inst/sample_data/simres/50-sims_seed-1-in-nd890"

sim_dir_split = strsplit(sim_dir, "/")[[1]]
sim_name = sim_dir_split[ length(sim_dir_split) ]
out_dir = file.path(results_dir, sim_name)
if(!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Read in the info files for each simulation--------------------------------
sim_info = get_sim_info(sim_dir)

# Get the duration of each simulation---------------------------------------
sim_l = get_sim_l(sim_info)

# Read in individual simulation files---------------------------------------
sims = get_sims(sim_dir, silent = FALSE)

# Comparing outbreak info across simulations--------------------------------
inf_info = get_inf_info(sims, sim_info, sim_l, threshold_nds = 10)
sim_summ_inf = get_sim_summ(inf_info)

# Subsetting outbreaks------------------------------------------------------
# choosing those that belong to type 3, based upon inf_info
outbrks_info = get_outbrks_info(sim_info, inf_info)
outbrks_l = get_sim_l(outbrks_info)
outbrks = get_outbrks(sims, inf_info)

# Saving outbreak info and simulation results summaries---------------------
saveRDS(inf_info, paste0(out_dir, "/inf-info_", sim_name, ".RDS"))
saveRDS(sim_summ_inf, paste0(out_dir, "/sim-summ-inf_", sim_name, ".RDS"))
saveRDS(outbrks_info, paste0(out_dir, "/outbrks-info_", sim_name, ".RDS"))
saveRDS(outbrks_l, paste0(out_dir, "/outbrks-l_", sim_name, ".RDS"))

# Remove big sims file------------------------------------------------------
rm(sims)
gc()

# nd_names = outbrks[[1]][[1]]$name
nd_inf_info = nd_inf_fxn(outbrks)

# NOTE: I ran the code below with pr=0, and it gave the same order importance
# while taking significantly longer (because it had to do the
# calculations for all the nodes, not just the imp ones which were observed
# in the actual outbreaks)
nd_inf_times_pr0p3 = inf_times_fxn(outbrks, nd_inf_info, pr=0.3)
nd_inf_times = inf_times_fxn(outbrks, nd_inf_info, pr = 0)

print("Saving results")
saveRDS(nd_inf_info, paste0(out_dir, "/nd-inf-info", "_", sim_name, ".RDS"))
saveRDS(nd_inf_times, paste0(out_dir, "/nd-inf-times", "_", sim_name, ".RDS"))

gc()


