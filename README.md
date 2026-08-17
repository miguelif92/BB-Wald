# BB-Wald

As a case application, ALS data from a region in Brandenburg Federal State were analysed through RStudio by using mainly the lidR package ecosystem to perform a comprehensive Airborne Laser Scanning (ALS) workflow for forest structure assessment in Brandenburg. The processing begins with the ingestion and filtering of multiple .laz tiles, applying a spatial reference system of EPSG:25833 and cleaning noise via Statistical Outlier Removal (SOR). Core data processing involves the generation of high-resolution Digital Terrain Models (DTM), Digital Surface Models (DSM), and Canopy Height Models (CHM) using algorithms such as K-Nearest Neighbour Inverse Distance Weighting (KNN-IDW) and Delaunay Triangulation (DSM-TIN).

Individual tree analysis is executed through height normalization followed by a Local Maximum Filter (LMF) with a dynamic window size to identify tree tops. The methodology emphasizes a comparative evaluation of three distinct crown segmentation algorithms: Dalponte & Coomes (2016), Li et al. (2012), and Silva et al. (2016). Statistical rigor is ensured through ANOVA and Tukey Post-Hoc tests to determine significant differences in crown area and height metrics across the different segmentation methods. The analysis concludes with the generation and export of tree geometries as ESRI™ Shapefiles (.shp) and raster products as GeoTIFFs (.tif), integrating spatial vector data with sf and raster processing with terra to provide a reproducible bridge between raw LiDAR point clouds and actionable dendrometric statistics.

Results derived from the entire analysis workflow will be presented as a sampling plot level due to volume and storage restrictions. For more information, check the posted script.


Appelhans, T., Detsch, F., Reudenbach, C. & Woellauer, S. (2025). mapview: Interactive Viewing of Spatial Data in R. <https://doi.org/10.32614/CRAN.package.mapview>, R package version 2.11.4.

Balestra, M., Marselis, S., Sankey, T. T., Cabo, C., Liang, X., Mokroš, M., Peng, X., Singh, A., Sterenczak, K., Vega, C., Vincent, G. and Hollaus, M. (2024). LiDAR data fusion to improve forest attribute estimates: A review. Current Forestry Reports, 10(3), 281-297. <https://doi.org/10.1007/s40725-024-00223-7>

Dalponte, M., & Coomes, D. A. (2016). Tree‐centric mapping of forest carbon density from Airborne Laser Scanning and hyperspectral data. Methods in Ecology and Evolution, 7(10), 1236–1245. <https://doi.org/10.1111/2041-210X.12575>

Di Stefano, F., Chiappini, S., Gorreja, A., Balestra, M., & Pierdicca, R. (2021). Mobile 3D SCAN LIDAR: A literature review. Geomatics, Natural Hazards and Risk, 12(1), 2387–2429. <https://doi.org/10.1080/19475705.2021.1964617>

Garnier, S., Ross, N., Rudis, R., Camargo, P., Sciaini, M. & Scherer, C. (2023). viridis(Lite) - Colorblind-Friendly Color Maps for R. <https://doi.org/10.5281/zenodo.4678327>, viridisLite package version 0.4.2.

Garnier, S., Ross, N., Rudis, R., Camargo, P., Sciaini, M. & Scherer, C. (2024). viridis(Lite) - Colorblind-Friendly Color Maps for R. <https://doi.org/10.5281/zenodo.4679423>, viridis package version 0.6.5.

Hijmans, R (2025). terra: Spatial Data Analysis. <https://doi.org/10.32614/CRAN.package.terra>, R package version 1.8-86.

Landesvermessung und Geobasisinformation Brandenburg. (2024). Laserscandaten: Einzelkacheln mit 1m Gitterweite im LAZ-Format. Retrieved from <https://data.geobasis-bb.de/geobasis/daten/als/laz/>

Li, W., Guo, Q., Jakubowski, M. K., & Kelly, M. (2012). A new method for segmenting individual trees from the Lidar Point Cloud. *Photogrammetric Engineering & Remote Sensing, 78*(1), 75–84. <https://doi.org/10.14358/PERS.78.1.75>

Makowski, D., Lüdecke, D., Patil, I., Thériault, R., Ben-Shachar, M. & Wiernik, B. (2023). “Automated Results Reporting as a Practical Tool to Improve Reproducibility and Methodological Best Practices Adoption.” CRAN. <https://doi.org/10.32614/CRAN.package.report>, <https://easystats.github.io/report/>.

Müller K (2025). here: A Simpler Way to Find Your Files. <https://doi.org/10.32614/CRAN.package.here>, R package version 1.0.2.

Müller, K. & Wickham, H. (2025). tibble: Simple Data Frames. <https://doi.org/10.32614/CRAN.package.tibble>, R package version 3.3.0.

Ooms, J. (2025). writexl: Export Data Frames to Excel 'xlsx' Format. <https://doi.org/10.32614/CRAN.package.writexl>, R package version 1.5.4.

Pebesma, E. & Bivand, R. (2023). Spatial Data Science: With applications in R. Chapman and Hall/CRC. <https://doi.org/10.1201/9780429459016>, <https://r-spatial.org/book/>.

Pebesma, E. (2018). Simple Features for R: Standardized Support for Spatial Vector Data. *The R Journal, 10*(1), 439-446. <https://doi.org/10.32614/RJ-2018-009>.

Pebesma, E., Mailund, T. & Hiebert, J. (2016). Measurement Units in R. *R Journal, 8*(2), 486-494. <https://doi.org/10.32614/RJ-2016-061>.

Roussel, J., Auty, D., Coops, N. C., Tompalski, P., Goodbody, T. R., Meador, A. S., Bourdon, J., de Boissieu, F. & Achim, A. (2020). lidR: An R package for analysis of Airborne Laser Scanning (ALS) data. Remote Sensing of Environment, 251, 112061. ISSN 0034-4257, <https://doi.org/10.1016/j.rse.2020.112061>. Roussel, J., Auty, D. (2026). Airborne LiDAR Data Manipulation and Visualization for Forestry Applications. R package version 4.2.2.

Silva, C. A., Hudak, A. T., Vierling, L. A., Loudermilk, E. L., O’Brien, J. J., Hiers, J. K., Jack, St. B., Gonzalez-Benecke, C., Lee, H., Falkowski, M. J., Khosravipour, A. (2016). Imputation of Individual Longleaf Pine (Pinus palustris Mill.) Tree Attributes from Field and LiDAR Data. *Canadian Journal of Remote Sensing, 42*(5), 554–573. <https://doi.org/10.1080/07038992.2016.1196582>

Wickham, H. (2016). ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York. ISBN 978-3-319-24277-4, <https://ggplot2.tidyverse.org>.

Wickham H, François R, Henry L, Müller K, Vaughan D (2023). dplyr: A Grammar of Data Manipulation. <https://doi.org/10.32614/CRAN.package.dplyr>, R package version 1.1.4.
