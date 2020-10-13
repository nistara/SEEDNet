# ==============================================================================
# * Read in commuting data
# ==============================================================================
g_comm_f = list.files("inst/sample_data/commuting", pattern = "100",
                      full.names = TRUE)

g_comm = readRDS(g_comm_f)


# ==============================================================================
# * Disease parameters
# ==============================================================================
seed_nd = "890"

params = list(r0 = r0,
              latent_period = latent_period,
              inf_period = inf_period,
              tau = tau,
              r_beta = r_beta,
              p_a = p_a,
              vacc = FALSE,
              seed_nd = seed_nd,
              seed_no = 1)



# ==============================================================================
# * Set up the pre-simulation network and data
# ==============================================================================

output_dir = "inst/sample_data/pre-sim/890"
if(!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

disnet_sim_setup(g_comm,
                 r0 = params$r0,
                 latent_period = params$latent_period,
                 inf_period = params$inf_period,
                 tau = params$tau,
                 r_beta = params$r_beta,
                 p_a = params$p_a,
                 vacc = params$vacc,
                 seed_nd = params$seed_nd,
                 seed_no = params$seed_no,
                 output_dir = output_dir)



# ==============================================================================
# * Set up vaccination scenarios
# ==============================================================================
vacc_eff = c(60, 80)
vacc_cov = 60

if(FALSE) {
    comb = expand.grid(vacc_eff, vacc_cov)
    # Resultant file names correspond to the effectively vaccinated proportions
    vacc_prop = (comb$Var1 * comb$Var2)/10000
}

seed_nd = "890"
vacc_nd = "890"

params$vacc = TRUE
params$vacc_nd = vacc_nd
params$vacc_eff = vacc_eff
params$vacc_cov = vacc_cov


# ** Create sim setup files-----------------------------------------------------
disnet_sim_setup(g_comm,
                 r0 = params$r0,
                 latent_period = params$latent_period,
                 inf_period = params$inf_period,
                 tau = params$tau,
                 r_beta = params$r_beta,
                 p_a = params$p_a,
                 seed_nd = params$seed_nd,
                 seed_no = params$seed_no,
                 vacc = params$vacc,
                 vacc_nd = params$vacc_nd,
                 vacc_eff = params$vacc_eff,
                 vacc_cov = params$vacc_cov,
                 output_dir = output_dir)


# ** Create sim setup files for multiple vaccination nodes----------------------
vacc_nd = c("890", "7", "78")
params$vacc_nd = vacc_nd

disnet_sim_setup(g_comm,
                 r0 = params$r0,
                 latent_period = params$latent_period,
                 inf_period = params$inf_period,
                 tau = params$tau,
                 r_beta = params$r_beta,
                 p_a = params$p_a,
                 seed_nd = params$seed_nd,
                 seed_no = params$seed_no,
                 vacc = params$vacc,
                 vacc_nd = params$vacc_nd,
                 vacc_eff = params$vacc_eff,
                 vacc_cov = params$vacc_cov,
                 output_dir = output_dir)

# ==============================================================================
# * Load pre-sim files
# ==============================================================================
presim_files = list.files("inst/sample_data/pre-sim/890", full.names = TRUE)
presim_l = lapply(presim_files, readRDS)
names(presim_l) = gsub(".RDS", "", basename(presim_files))


# ==============================================================================
# * Check pre-sim output
# ==============================================================================
# Load commuting info to check for nodes/vertices
g_comm = readRDS(list.files("inst/sample_data/commuting",
                                   pattern = "100",
                                   full.names = TRUE))

# ** Check pre-sim components
lapply(presim_l, function(presim) {
    all.equal(names(presim), c("start_TS", "vert_list", "j_out", "params"))
})


# ** Check seed nodes
lapply(presim_l, function(g_presim) {
    start_TS = g_presim$start_TS
    seed_nd = start_TS$name[ start_TS$I > 0]
    seed_nd == "890"
})


# ** Check start_TS is a dataframe
lapply(presim_l, function(presim) {
    class(presim$start_TS) == "data.frame"
})


# ** Check length of start_TS wrt nodes/verts
lapply(presim_l, function(presim, g_comm) {
    dfv = igraph::as_data_frame(g_comm, "vertices")
    all(presim$start_TS$name %in% dfv$name)
}, g_comm)


# ** Check vaccination nodes
# Note: this approach might need to be modified later depending on how the
# pre-sim output name evolves
vacc_nds_l = lapply(names(presim_l), function(presim_name) {
    presim_name_split = strsplit(presim_name, "_")[[1]]
    vacc = presim_name_split[ grepl("vacc", presim_name_split) ]
    if( length(vacc) > 0 ) {
        vacc = as.numeric(strsplit(vacc, "-")[[1]])
        vacc = vacc[ !is.na(vacc) ]
    } else {
        vacc = NA
    }
})

lapply(seq_along(presim_l), function(n, presim_l, vacc_nds_l) {
    vacc_nds = vacc_nds_l[[ n ]]

    if( all(!is.na(vacc_nds)) ) {
        presim_startTS = presim_l[[ n ]]$start_TS
        vacc_startTS =  presim_startTS[ presim_startTS$name %in% vacc_nds, ]
        all(vacc_startTS$R > 0)
    } else {
        "Not applicable"
    }
    
}, presim_l, vacc_nds_l)


# ** Check parameters

latent_period = 2.62
inf_period = 3.38
mu = 1/inf_period

lapply(presim_l, function(presim, latent_period, inf_period) {

    chk = vector("list", length = 3)
    names(chk) = c("exit_latent_I", "exit_latent_Ia", "mu")
    chk$exit_latent_I = ((1/latent_period) * (1 - p_a))
    chk$exit_latent_Ia =  ((1/latent_period) * p_a)
    chk$mu = 1/inf_period

    all.equal(chk, presim$params)

}, latent_period, inf_period)


# ==============================================================================
# * Parameter references (for pandemic 2009 H1N1):
# ------------------------------------------------------------------------------
r0 = 1.44
latent_period = 2.62
inf_period = 3.38
mu = 1/inf_period
tau = 3
r_beta = 0.50
p_a = 1/3

beta = (r0 * mu)/((r_beta * p_a) + (1 - p_a))

# Pourbohloul B, Ahued A, Davoudi B, et al. Initial human transmission dynamics
# of the pandemic (H1N1) 2009 virus in North America. Influenza Other Respi
# Viruses 2009; 3: 215–22.
# 
# Tuite, Ashleigh R., Amy L. Greer, Michael Whelan, Anne-Luise Winter,
# Brenda Lee, Ping Yan, Jianhong Wu, et al. 2010. “Estimated Epidemiologic
# Parameters and Morbidity Associated with Pandemic H1N1 Influenza.”
# CMAJ: Canadian Medical Association Journal =
# Journal de l’Association Medicale Canadienne 182 (2): 131–36.
# 
# Tuite, Ashleigh R., Amy L. Greer, Michael Whelan, Anne-Luise Winter, Brenda
# Lee, Ping Yan, Jianhong Wu, et al. 2010. “Estimated Epidemiologic Parameters
# and Morbidity Associated with Pandemic H1N1 Influenza.” CMAJ: Canadian
# Medical Association Journal = Journal de l’Association Medicale Canadienne
# 182 (2): 131–36.
#
# Longini, Ira M., Jr, Azhar Nizam, Shufu Xu, Kumnuan Ungchusak, Wanna
# Hanshaoworakul, Derek A. T. Cummings, and M. Elizabeth Halloran. 2005.
# “Containing Pandemic Influenza at the Source.” Science 309 (5737): 1083–87.
# 
# ==============================================================================
