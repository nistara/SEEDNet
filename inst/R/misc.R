# ******************************************************************************
# For running test/intermediate R code and analyses
# ******************************************************************************

if(FALSE) {
    load("~/projects/flunetPkg/data/g_raw.rda")
    g = igraph::induced.subgraph(g_raw, sample(1:1000, 100))
    g
    saveRDS(g, "inst/sampleData/g.RDS")
}

# testing export function
y = function(x,
             output_dir = getOption("disnetOutputDir", "disnet_output_dir"))
{
    if(!is.na(output_dir) && !dir.exists(output_dir) ) {
        dir.create(sim_output_dir)
    }    
    if(length(output_dir) > 0 && !is.na(output_dir)) {
        f = file.path(output_dir, sprintf("%d%s.RDS", x, c("", "_info")))
        saveRDS(x, f[1])
        saveRDS(x, f[2])
        f
    } else
        list(sim_setup = x)

}


