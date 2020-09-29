# ==============================================================================
#
# This code checks commuting info
#
# ==============================================================================

g_comm_f = list.files("inst/sample_data/commuting", full.names = TRUE)

comm_chk = function(n, dfe) {
    from = dfe$name[ n ]
    to = dfv$name[ n ]

    radius = dfe$Total_Length[ dfe$from %in% from &
                               dfe$to %in% to ]

    df_radius = dfe[ dfe$from %in% from & dfe$Total_Length <= radius, ]
    m_i = df_radius$pop_from[1]
    n_j = df_radius$pop_to[ df_radius$to %in% to]
    s_ij = sum(df_radius$pop_to[ df_radius$to != to])
    N = 1 # to get 0.11 as proportion
    N_c = 0.11
    T_i = (N_c/N) # want only rate, not num people. original:  m_i * (N_c/N)
    T_ij = T_i * ( (m_i * n_j) / ((m_i + s_ij) * (m_i + n_j + s_ij)) )

    all.equal(T_ij, dfe$commuting_prop[ dfe$from %in% from & dfe$to %in% to ])
}


all_comm_chk = lapply(g_comm_f, function(g_comm) {
    cat(paste0("\n", g_comm, "\n"))
    g_comm = readRDS(g_comm)
    dfe = igraph::as_data_frame(g_comm, "edges")
    sapply(seq_len(nrow(dfe)), comm_chk, dfe)
})

lapply(all_comm_chk, all)

