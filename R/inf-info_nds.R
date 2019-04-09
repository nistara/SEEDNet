# ==============================================================================
# Node specific infection probabilities
# ==============================================================================

# A. Ways to look at a node's culpability of being infected:
# ------------------------------------------------------------------------------
# 1a. Average duration of infection - done in getting the order bit
#
# 2a. Average number of days node is infected across all outbreaks
# 
# 3a. Average proportion of outbreak time that a node is infected
# Go through every timestep (TS) from each simulation and assign 1 to those
# nodes that were infected. Finally cbind all these columns and take the
# average. This gives the proportion of the days when a node was infected.
# If in doubt about the above method, consider this:
if(FALSE){
    
    table(sapply(1:100, function(x) {
        n = sample(999:9999, 1)
        t = sample(0:1, n, replace = T)
        (sum(t)/n) == mean(t)
    }))
    
}
# Then, take the average of the above proportions across all simulations.
# This gives the average duration that a node was infected across all simulations
# ------------------------------------------------------------------------------
#
# 
# B. Ways to look at the extent of infectious individuals a node generates
# ------------------------------------------------------------------------------
# 1b. Average number of infected individuals in a node during an outbreak
# Considering the no. infected to be the difference between the initital R and
# final R (to account for prior R via vaccines, etc)
# R here stands for Recovered (and immune as a result of vaccination)
#


# ------------------------------------------------------------------------------
# The function
# ------------------------------------------------------------------------------
nd_inf_fxn = function(outbrks, nd_names){

    is_nd_inf = lapply(outbrks, function(outbrk){
        do.call(cbind,
                lapply(outbrk, function(TS) {
                    nd_inf = ifelse( (TS$I + TS$Ia) > 0, 1, 0)
                }))
    })

    # av number of days that node was infected during outbreaks
    av_inf_days = rowMeans(do.call(cbind,
                                   lapply(is_nd_inf, function(outbrk){
                                       rowSums(outbrk)
                                   })))

    # av prop of time that node was infected during outbreaks
    av_inf_durprop = rowMeans(do.call(cbind,
                                      lapply(is_nd_inf, function(outbrk){
                                          rowMeans(outbrk)
                                      })))

    # av number of infectious individuals
    av_inf = round(rowMeans(do.call(cbind,
                                    lapply(outbrks, function(outbrk) {
                                        TS_beg = outbrk[[1]]
                                        TS_end = outbrk[[length(outbrk)]]
                                        TS_end$R - TS_beg$R
                                    }))))

    # av prop of infectious individuals
    av_infprop = rowMeans(do.call(cbind,
                                    lapply(outbrks, function(outbrk) {
                                        TS_beg = outbrk[[1]]
                                        TS_end = outbrk[[length(outbrk)]]
                                        nd_inf = TS_end$R - TS_beg$R
                                        nd_inf/sum(nd_inf)
                                    })))

    # resulting nd specific dataframe
    data.frame(name = nd_names,
               av_inf_days = av_inf_days,
               av_inf_durprop = av_inf_durprop,
               av_inf = av_inf,
               av_infprop = av_infprop,
               stringsAsFactors = FALSE)
    
}


# ==============================================================================
# Getting start and stop times
# ==============================================================================

# Steps:
# - for each node, go through each simulation and add the I & Ia, then cbind the
#   columns along with the node name.
# - that gives us a list of dataframes consisting of node names and whether they
#   were infected. Each row corresponds to a unique simulation, and each column
#   represents whether they were infected at each timesteps.
# - dplyr::bind_rows helps binding rows with different numbers, assigning NAs to
#   once outbreaks were over (since the dimensions of the dataframe extent to
#   the maximum outbreak length( max(sim_l) #  375 )

inf_times_fxnI = function(outbrks, nd_names) {

    nd_infs = lapply(outbrks, function(outbrk, nd_names) {
        nd_infs = lapply(outbrk, function(TS) {
            nd_inf = TS$I + TS$Ia
        })
        data.frame(name = nd_names, do.call(cbind, nd_infs))
    }, nd_names)

    nd_infs = do.call(dplyr::bind_rows, nd_infs)
    nd_infs = split(nd_infs, nd_infs$name)
    names(nd_infs) = sort(nd_names)
    nd_infs[match(nd_names, names(nd_infs))]
}


inf_times_fxnII = function(n, nd_infs, nd_inf_info, pr=0.3){
    nd_infs = nd_infs[[n]]
    nd_inf_info = nd_inf_info[[n]]
    nd_infs[ nd_inf_info$av_inf_durprop >= pr ]
}

    
inf_times_fxnIII = function(nd_infs, type = "max"){
    inf_times = lapply(nd_infs, function(df, type) {
        df = df[ , -1]
        rownames(df) = NULL

        inf_info = apply(df, 1, function(sim) {
            sim = sim[ !is.na(sim) ]
            sim = ifelse(sim > 0, 1, 0)
            inf_start = which(diff(c(0, sim)) == 1)
            inf_stop = which(diff(c(sim, 0)) == -1)
            inf_len = (inf_stop - inf_start + 1)
            
            if(length(inf_start) == 0){
                 data.frame(inf_start = 0,
                                   inf_stop = 0,
                                   inf_len = 0)
                } else {
                    if(type %in% "max"){
                        data.frame(inf_start = inf_start[ which.max(inf_len) ],
                                   inf_stop = inf_stop[ which.max(inf_len) ],
                                   inf_len = max(inf_len))
                    } else {
                        if(type %in% "first"){
                            data.frame(inf_start = inf_start[1],
                                       inf_stop = inf_stop[1],
                                       inf_len = inf_len[1] )
                        }
                    }
                }
        })

        inf_info = do.call(rbind, Map(cbind, sim = rownames(df), inf_info))
        inf_info
    }, type)
    
    inf_times = Map(cbind, name = names(nd_infs), inf_times)
    names(inf_times) = names(nd_infs)
    all_times = do.call(rbind, inf_times)
    times = lapply(split(all_times, all_times$sim), function(sim) {
        rownames(sim) = NULL
        sim = sim[ sim$inf_start != 0, ]
        sim = sim[ order(sim$inf_start), ]
        sim$order = 1:nrow(sim)
        sim
    })
    times = do.call(rbind, times)
    times = split(times, times$name)
    times = lapply(times, function(df) {
        data.frame(order_mean = mean(df$order),
                   order_median = median(df$order),
                   order_mode = Mode(df$order),
                   order_sd = sd(df$order),
                   start_mean = mean(df$inf_start),
                   start_sd = sd(df$inf_start),
                   start_median = median(df$inf_start),
                   start_mode = Mode(df$inf_start),
                   len_mean = mean(df$inf_len),
                   len_sd = sd(df$inf_len),
                   len_median = median(df$inf_len),
                   stringsAsFactors = FALSE)
    })
    times = do.call(rbind,
                    Map(cbind, times,
                        name = names(times), stringsAsFactors = FALSE))
    times = times[ order(times$start_median), ]
    rownames(times) = NULL
    times
}



inf_times_fxn = function(outbrks, nd_names, nd_inf_info, type = "max", pr = 0.3){
    nd_infs = lapply(outbrks, inf_times_fxnI, nd_names)
    inf_timesII = lapply(seq_along(nd_infs), inf_times_fxnII,
                         nd_infs, nd_inf_info, pr)
    lapply(inf_timesII, inf_times_fxnIII, type)
}



inf_times_obs_fxn = function(inf_times) {
    obs_order = data.frame(city = c("Kigali", "Gisenyi", "Muhanga",
                                             "Musanze", "Cyangugu", "Cyangugu",
                                             "Cyangugu", "Huye", "Kibungo",
                                             "Kibungo"),
                              name = c("890", "1239", "620",
                                              "1451", "162", "174",
                                              "180", "78", "510", "539"),
                              stringsAsFactors = FALSE)
    obs_order$obs_order = as.numeric(
                                 factor(obs_order$city,
                                        levels = unique(obs_order$city)))
    lapply(inf_times, function(df, obs) dplyr::left_join(df, obs_order, by = "name"))
}


inf_times_for_plot = function(outbrks,
                              nd_names,
                              nd_inf_info,
                              type = "max",
                              pr = 0.3)
{
    nd_infs = lapply(outbrks, inf_times_fxnI, nd_names)
    inf_timesII = lapply(seq_along(nd_infs), inf_times_fxnII,
                         nd_infs, nd_inf_info, pr)
        lapply(inf_timesII, inf_times_fxnIII_for_plot, type)
    
}

inf_times_fxnIII_for_plot = function(nd_infs, type = "max")
{

    inf_times = lapply(nd_infs, function(df, type) {
        df = df[ , -1]
        rownames(df) = NULL

        inf_info = apply(df, 1, function(sim) {
            sim = sim[ !is.na(sim) ]
            sim = ifelse(sim > 0, 1, 0)
            inf_start = which(diff(c(0, sim)) == 1)
            inf_stop = which(diff(c(sim, 0)) == -1)
            inf_len = (inf_stop - inf_start + 1)
            
            if(length(inf_start) == 0){
                 data.frame(inf_start = 0,
                                   inf_stop = 0,
                            inf_len = 0)
                } else {
                    if(type %in% "max"){
                        data.frame(inf_start = inf_start[ which.max(inf_len) ],
                                   inf_stop = inf_stop[ which.max(inf_len) ],
                                   inf_len = max(inf_len))
                    } else {
                        if(type %in% "first"){
                            data.frame(inf_start = inf_start[1],
                                       inf_stop = inf_stop[1],
                                       inf_len = inf_len[1])
                        }
                    }
                }
        })

        inf_info = do.call(rbind, Map(cbind, sim = rownames(df), inf_info,
                                      stringsAsFactors = FALSE))
        inf_info
    }, type)
    
    inf_times = Map(cbind, name = names(nd_infs), inf_times, stringsAsFactors = FALSE)
    names(inf_times) = names(nd_infs)
    all_times = do.call(rbind, inf_times)
    times = lapply(split(all_times, all_times$sim), function(sim) {
        rownames(sim) = NULL
        sim = sim[ sim$inf_start != 0, ]
        sim = sim[ order(sim$inf_start), ]
        sim$order = 1:nrow(sim)
        sim
    })
    times = do.call(rbind, times)

    obs_order = data.frame(city = c("Kigali", "Gisenyi", "Muhanga",
                                             "Musanze", "Cyangugu", "Cyangugu",
                                             "Cyangugu", "Huye", "Kibungo",
                                             "Kibungo"),
                              name = c("890", "1239", "620",
                                              "1451", "162", "174",
                                              "180", "78", "510", "539"),
                              stringsAsFactors = FALSE)
    obs_order$obs_order = as.numeric(
                                 factor(obs_order$city,
                                        levels = unique(obs_order$city)))

    obs_city_times = dplyr::left_join(obs_order, times, by = "name")
    obs_city_times
}


