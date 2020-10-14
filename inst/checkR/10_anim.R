# ==============================================================================
# * Workspace
# ==============================================================================
library(RColorBrewer)
library(doBy)
library(dplyr)
library(gtools)
library(raster)
library(sf)
library(ggmap)
library(tmap)
library(data.table)
library(tidyr)
library(hrbrthemes)
library(cowplot)
library(stringr)
library(magick)
library(patchwork)

extrafont::loadfonts()

out_dir = "inst/sample_data/results/animation-plots"
if( !dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# * Read in sim data and choose simulation for animation
# ==============================================================================
sim_dir = "inst/sample_data/simres/50-sims_seed-1-in-nd890/"

sims = get_sims(sim_dir, silent = FALSE)
sim_info = get_sim_info(sim_dir)
sim_l = get_sim_l(sim_info)
inf_info = get_inf_info(sims, sim_info, sim_l, threshold_nds = 10)
outbrks_info = get_outbrks_info(sim_info, inf_info)
outbrks_l = get_sim_l(outbrks_info)
mean_outbrk_l = mean(outbrks_l)

set.seed(0)
sim_n = sample(which(sim_l > (mean_outbrk_l - 10) &
                     sim_l < (mean_outbrk_l + 10)), 1)
sim_l[ sim_n ]

sim_file = file.path(sim_dir, paste0(sim_n, ".RDS"))
sim = readRDS(sim_file)


# Load Rwanda polygon map
# ==============================================================================
rwa = readRDS("inst/sample_data/rwa_map.RDS")


# Get vert info
# ==============================================================================
g = readRDS("inst/sample_data/network/g100.RDS")
verts = igraph::as_data_frame(g, "vertices")


# All plots
# ==============================================================================
sims = mapply(cbind, sim, "day" = seq_along(sim), SIMPLIFY = F) %>%
    rbindlist(fill = TRUE)

sims = dplyr::left_join(sims, verts[ , c("name", "lat", "lon")], by = "name")

max(sims$day)
sum(sims$R[ sims$day %in% max(sims$day) ])

sim_df = sims %>%
    mutate_at(vars("lat", "lon"), as.numeric) %>%
    mutate(total_I = I + Ia,
           pt_size = sqrt(total_I/5000))

sim_sf = sim_df %>%
    st_as_sf(coords = c('lon', 'lat'), crs = 4326)


n = seq(1, length(sim), by = 5)
if(max(n) < length(sim)) n = c(n, length(sim))
                              
for(i in n) {
    # Plot map
    df = sim_sf %>%
        filter(day %in% i & total_I > 0)
    map = ggplot() +
        geom_sf(data = rwa, fill = "#D3B3A2", color = NA ) +
        geom_sf(data = df, size = df$pt_size * 2, col = "#992828") +
        theme_void() +
        ggtitle(paste0("Day: ", i))
    # Plot curves
    curves = sim_df %>%
        filter(day <= i) %>%
        dplyr::select(S, total_I, R, day) %>%
        group_by(day) %>%
        summarize_all(list(sum)) %>%
        pivot_longer(cols = S:R) %>%
        ggplot() +
        geom_line(aes(x = day, y = value, color = name)) +
        xlab("Days") +
        ylab("No. of Individuals") +
        scale_color_manual(values = c("#275599", "#279955", "#C13165"),
                           labels = c("Recovered", "Susceptible", "Infectious")) +
        theme_ipsum(base_size = 12, axis_title_size = 12, axis_text_size = 10) +
        labs(color = "Infection status") +
        coord_cartesian(xlim = c(0, 290))
    # Join the map and curve plots
    p = map + curves
    out_p = file.path(out_dir, paste0(i, ".png"))
    cowplot::save_plot(out_p, p,
                       base_height = 3,
                       base_width = 8)
}


# Create gif
# ==============================================================================
# list file names and read in
imgs = str_sort(list.files(out_dir, full.names = TRUE), numeric = TRUE)
img_list = lapply(imgs, image_read, density = "500x500")
img_list = lapply(img_list, image_scale, "750")

# join the images together
img_joined = image_join(img_list)

# animate at 5 frames per second
img_animated = image_animate(img_joined, fps = 5)

# view animated image
img_animated

# save to disk
image_write(image = img_animated,
            path = "inst/sim_anim.gif")
