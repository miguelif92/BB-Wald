#######-------LiDAR Analysis-------######
#######-------written by-----------######
#######-----MIGUEL SALAMANCA-------######


#On a first glance, this script works inside an R Project
#Create a project, establish the path and organise the folders as follows:

#-project -> Main folder
# ╠>laz -> Store the .laz files here
# ╠>las -> Store the .las files here   
# ╠>shp -> Store the .shp files here, like tree tops or tree crowns
# ╠>tif -> Store the raster tiles you generate, like CHM, DTM or DSM
# ╠>xls -> Store the .xlsx files you generate
# ╠>img -> Store the charts and figures that will be generated
# ╚>script-> All code or script files lie here, included this one

######### 1. Loading packages#######
library(lidR)     
library(sf)       
library(terra)    
library(tibble)   
library(mapview)  
library(ggplot2)
library(viridis)
library(units)
library(writexl)
library(dplyr)
library(here)
library(report)

# This will show you the root directory of your project
here()

######### 2. Loading vector files #######
aoi <- st_read("shp/aoi.shp") #AOI
forest <- st_read("shp/foreststands.shp") #Forest land cover, it was clipped before
plot <- st_read("shp/plot.shp")


#For border-effect, a 1 m buffer will be generated for forest areas
wald <- st_buffer(forest, dist = 1)
mapview(wald)

######### 3. Loading LAZ files #######
las1 <- readLAS("laz/als_33422-5858.laz", select = "xyzcnr", 
               filter = "-drop_class 12 -drop_class 7 -drop_class 0 -drop_class 1")
las2 <- readLAS("laz/als_33422-5859.laz", select = "xyzcnr", 
                filter = "-drop_class 12 -drop_class 7 -drop_class 0 -drop_class 1")
las3 <- readLAS("laz/als_33422-5860.laz", select = "xyzcnr", 
                filter = "-drop_class 12 -drop_class 7 -drop_class 0 -drop_class 1")
las4 <- readLAS("laz/als_33421-5858.laz", select = "xyzcnr", 
                filter = "-drop_class 12 -drop_class 7 -drop_class 0 -drop_class 1")
las5 <- readLAS("laz/als_33421-5859.laz", select = "xyzcnr", 
                filter = "-drop_class 12 -drop_class 7 -drop_class 0 -drop_class 1")
las6 <- readLAS("laz/als_33421-5860.laz", select = "xyzcnr", 
                filter = "-drop_class 12 -drop_class 7 -drop_class 0 -drop_class 1")

#Clipping LAS to AOI
#Set CRS for all tiles
st_crs(las1) <- 25833
st_crs(las2) <- 25833
st_crs(las3) <- 25833
st_crs(las4) <- 25833
st_crs(las5) <- 25833
st_crs(las6) <- 25833

# Merge LAS Data
merged_las <- rbind(las1, las2, las3, las4, las5, las6)

#Clean RAM
rm(las1, las2, las3, las4, las5, las6)

# Deep clean
gc()

#Clip
wald_las <- clip_roi(merged_las, wald)

######### 4. Noise reduction and filtering #######
clip_lasnr <- classify_noise(wald_las, sor())
las_nr <- classify_noise(merged_las, sor())
gnd <- filter_ground(wald_las)

######### 5. DTM & DSM #######

#DTM
dtm <- rasterize_terrain(las_nr, res = 1, algorithm = knnidw(k = 10L, p = 2))

#DSM
dsm <- rasterize_canopy(las_nr, res= 1, algorithm = dsmtin())

# Deep clean
gc()

######### 6. CHM #######
#Normalization
norm_data <- normalize_height(clip_lasnr, knnidw())


#CHM
chm <- rasterize_canopy(norm_data, res = 1, algorithm = p2r(subcircle = 0.2))

kernel <- matrix(1, 3, 3)
chm <- terra::focal(chm, w = kernel, fun = median, na.rm = TRUE)

# Deep clean
gc()

######### 7. Tree height map #######
# Define a custom function for dynamic window size:
# This function increases the window size as tree height increases.
# It's useful because larger trees need a larger search window when detecting tree tops,
# while smaller trees require a smaller window to avoid false positives.

f <- function(x) { x * 0.1 + 3 }

# Example: if height is 0 → ws = 3; if height is 30 → ws = 6
# This provides a more adaptive approach compared to fixed-size windows.

heights <- seq(0, 35, 1)  # A sample range of tree heights from 0 to 30 meters
ws <- f(heights)          # Apply the function to get window sizes

# Detect tree tops using Local Maximum Filter with dynamic window size function
ttops <- locate_trees(norm_data, lmf(f))

######### 8. Crown segmentation #######

# Apply different segmentation algorithms
algo1 <- dalponte2016(chm, ttops)
algo2 <- li2012()
algo3 <- silva2016(chm, ttops)

# Segment trees using each algorithm
lasD <- segment_trees(norm_data, algo1, attribute = "IDdalponte")
lasLi <- segment_trees(norm_data, algo2, attribute = "IDli")
lasS <- segment_trees(norm_data, algo3, attribute = "IDSilva")

# Define a function to extract tree metrics
f <- function(z) {
  list(
    Z_mean = mean(z),
    Z_max = max(z),
    Z_std = sd(z),
    Crown_H = max(z) - 0.7 * max(z)
  )
}

# Apply the function to calculate crown metrics
crowns_dalponte <- crown_metrics(lasD, func = ~f(Z), attribute = "IDdalponte", geom = "concave")
crowns_li <- crown_metrics(lasLi, func = ~f(Z), attribute = "IDli", geom = "concave")
crowns_Si <- crown_metrics(lasS, func = ~f(Z), attribute = "IDSilva", geom = "concave")

# Deep clean
gc()

######### 9. Statistical comparison #######
#Calculate crown area
crowns_dalponte$area <- st_area(crowns_dalponte)
crowns_li$area <- st_area(crowns_li)
crowns_Si$area <- st_area(crowns_Si)

#Classify rows according to algorithms
crowns_dalponte$algorithm <- "Dalponte and Coomes (2016)"
crowns_li$algorithm <- "Li et al. (2012)"
crowns_Si$algorithm <- "Silva et al. (2016)"

#Delete IDs
crowns_dalponte <- crowns_dalponte[, -1]
crowns_li <- crowns_li[, -1]
crowns_Si <- crowns_Si[, -1]

#Merge crown dataframes
crown <- rbind(crowns_dalponte, crowns_li, crowns_Si)

crown$algorithm <- as.factor(crown$algorithm)
crown$area <- as.numeric(crown$area)
crown$Z_max <- as.numeric(crown$Z_max)


#Summary Stats
#Area
summary_stats <- crown %>%
  st_drop_geometry() %>%                
  group_by(algorithm) %>%    
  summarise(
    count  = n(),
    mean   = mean(area, na.rm = TRUE),
    median = median(area, na.rm = TRUE),
    sd     = sd(area, na.rm = TRUE),
    max    = max(area, na.rm = TRUE),
    min    = min(area, na.rm = TRUE),
    range  = max - min
  )

print(summary_stats)

write_xlsx(summary_stats, "xls/area_summary.xlsx")

#Height
summary_stats_h <- crown %>%
  st_drop_geometry() %>%                # Drops the spatial part for calculation speed
  group_by(algorithm) %>%    # e.g., Plot_ID or Species
  summarise(
    count  = n(),
    mean   = mean(Z_max, na.rm = TRUE),
    median = median(Z_max, na.rm = TRUE),
    sd     = sd(Z_max, na.rm = TRUE),
    max    = max(Z_max, na.rm = TRUE),
    min    = min(Z_max, na.rm = TRUE),
    range  = max - min
  )

print(summary_stats_h)

write_xlsx(summary_stats_h, "xls/height_summary.xlsx")

#Boxplot for crown area
boxplot_area <- crown %>%
                ggplot(aes(x = algorithm, y = area, fill = algorithm)) +
                geom_boxplot(alpha = 0.7) + 
                labs(
                     title = "Crown area for different algorithms",
                     subtitle = "Comparison of tree segmentation results",
                     x = "Segmentation Algorithm",
                     y = expression(Area~(m^2))) +
                theme_minimal() +
                theme(legend.position = "none")

print(boxplot_area)

ggsave("img/boxplot_area.png", plot = boxplot_area, width = 8, height = 6, dpi = 300)

#Violinplot
violin_area <- crown %>%
               ggplot(aes(x = algorithm, y = area, fill = algorithm)) +
               geom_violin(alpha = 0.7) + 
               labs(
                    title = "Crown area for different algorithms",
                    subtitle = "Comparison of tree segmentation results",
                    x = "Segmentation Algorithm",
                    y = expression(Area~(m^2))) +
               theme_minimal() +
               theme(legend.position = "none")

print(violin_area)

ggsave("img/violin_area.png", plot = violin_area, width = 8, height = 6, dpi = 300)


#Density function for Area for algorithm
density_area <- ggplot(crown, aes(x = area, colour = algorithm)) +
                geom_density(size = 1) +
                labs(
                     title = "Crown area Density Plot", 
                     x = expression(Area~(m^2), 
                     y = "Density")
                     )

print(density_area)

ggsave("img/density_area.png", plot = density_area, width = 8, height = 6, dpi = 300)

#Boxplot for maximum height
boxplot_h <- crown %>%
             ggplot(aes(x = algorithm, y = Z_max, fill = algorithm)) +
             geom_boxplot(alpha = 0.7) + 
             labs(
                  title = "Total height for different algorithms",
                  subtitle = "Comparison of tree segmentation results",
                  x = "Segmentation Algorithm",
                  y = expression("Height [m]") 
                  ) +
             theme_minimal() +
             theme(legend.position = "none")

print(boxplot_h)

ggsave("img/boxplot_h.png", plot = boxplot_h, width = 8, height = 6, dpi = 300)

#Violin
violin_h <- crown %>%
            ggplot(aes(x = algorithm, y = Z_max, fill = algorithm)) +
            geom_violin(alpha = 0.7) + 
            labs(
                 title = "Total height for different algorithms",
                 subtitle = "Comparison of tree segmentation results",
                 x = "Segmentation Algorithm",
                 y = expression("Height [m]") 
                 ) +
            theme_minimal() +
            theme(legend.position = "none")

print(violin_h)

ggsave("img/violin_h.png", plot = violin_h, width = 8, height = 6, dpi = 300)

#Density function for Height for algorithm
density_h <- ggplot(crown, aes(x = Z_max, colour = algorithm)) +
             geom_density(size = 1) +
             labs(title = "Height Density Plot", x = "Height [m]", y = "Density")

print(density_h)

ggsave("img/density_h.png", plot = density_h, width = 8, height = 6, dpi = 300)

#Scatterplot
scat <- ggplot(crown, aes(x = area, y = Z_max, color = algorithm)) + 
        geom_point(size = 1, alpha = 0.5) + 
        facet_wrap(~algorithm, ncol = 3) + 
        labs(
             title = "Relation between crown area and total height",
             x = expression("Area"~(m^2)),
             y = "Height [m]"
            ) +
        geom_smooth(method = "lm", color = "black", se = FALSE, size = 0.5) +
        theme_minimal() +
        theme(legend.position = "none")

print(scat)

ggsave("img/scatterplot.png", plot = scat, width = 8, height = 6, dpi = 300)

# Deep clean
gc()

##ANOVA
#Crown area
#ANOVA
anova_crown <- aov(area ~ algorithm, data = crown)
summary(anova_crown)

#PostHoc Test
TukeyHSD(anova_crown)


#Height
#ANOVA
anova_h <- aov(Z_max ~ algorithm, data = crown)
summary(anova_h)

#PostHoc Test
TukeyHSD(anova_h)

# Deep clean
gc()


######### 10. Export results #######

# Export tree tops as shapefile
write_sf(obj = st_zm(ttops),  # Remove Z and M dimensions
         dsn = "shp/test_ttops.shp",
         layer = 'test_ttops',
         driver = 'ESRI Shapefile')

# Export crown polygons
write_sf(obj = crowns_dalponte,
         dsn = "shp/test_crowns3.shp",
         layer = 'test_crowns3',
         driver = 'ESRI Shapefile')

write_sf(obj = crowns_li,
         dsn = "shp/test_crowns_li.shp",
         layer = 'test_crowns_li',
         driver = 'ESRI Shapefile')

write_sf(obj = crowns_Si,
         dsn = "shp/test_crowns_Si.shp",
         layer = 'test_crowns_Si',
         driver = 'ESRI Shapefile')

# Export Rasters as GeoTIFF
#CHM
terra::writeRaster(chm, "tif/chm.tif", overwrite=TRUE)

#DSM
terra::writeRaster(dsm, "tif/dsm.tif", overwrite=TRUE)

#DTM
terra::writeRaster(dtm, "tif/dtm.tif", overwrite=TRUE)

######### 11. Analysing LAS at a sample plot level #######

#Clipping LAS files
plot_las <- clip_roi(merged_las, plot)

plot_wald_nr <- clip_roi(wald_las, plot)

plot_las_nr <- clip_roi(las_nr, plot)

plot_norm <- clip_roi(norm_data, plot)

#Plot LAS
plot(plot_las)
plot(plot_wald_nr)
plot(plot_las_nr)
plot(plot_norm)

#Intersect the vector files
plot_crowns_dal <- st_join(crowns_dalponte, plot, left = FALSE)
plot_crowns_li <- st_join(crowns_li, plot, left = FALSE)
plot_crowns_sil <- st_join(crowns_Si, plot, left = FALSE)
plot_ttops <- st_join(ttops, plot, left = FALSE, join = st_within)

######### 12. Export clipped files #######
#Merged LAS
writeLAS(plot_las, "las/merged_las.las")

#Forest LAS
writeLAS(plot_wald_nr, "las/wald_las.las")

#Noise reduction LAS 
writeLAS(plot_las_nr, "las/clip_lasnr.las")

#Normalised LAS
writeLAS(plot_norm, "las/plot_norm.las")

#Export Vector files
write_sf(obj = plot_crowns_dal,
         dsn = "shp/plot_test_crowns3.shp",
         layer = 'plot_test_crowns3',
         driver = 'ESRI Shapefile'
)

write_sf(obj = plot_crowns_li,
         dsn = "shp/plot_test_li.shp",
         layer = 'plot_test_crowns_li',
         driver = 'ESRI Shapefile'
)

write_sf(obj = plot_crowns_sil,
         dsn = "shp/plot_test_si.shp",
         layer = 'plot_test_crowns_si',
         driver = 'ESRI Shapefile'
)


write_sf(obj = plot_ttops,
         dsn = "shp/plot_ttops.shp",
         layer = 'plot_ttops',
         driver = 'ESRI Shapefile'
)

######### 13. Package citation #######
cite_packages()