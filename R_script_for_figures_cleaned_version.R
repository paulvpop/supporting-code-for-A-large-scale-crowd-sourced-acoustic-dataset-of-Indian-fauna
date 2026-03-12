-------------------
## Chloropleth ####
-------------------
  
# R script for producing the data for figure 1

----------------------------
###### Getting started #####
----------------------------
  
# Set the working directory to where all the files are stored (If you have your files in different folder, set the directory to a higher level and then use relative paths to
# where the files are located, when loading those files to the R environment)

setwd("~/Bioacoustics dataset paper/figures")

#Load in the necessary library sf
library(sf)

# Load in a shapefile with all the state and union territory boundaries whose 
# geometry issues have been already fixed

shapefile <- st_read("./shapefile_fixed/shapefile_valid.shp")   

#Plot the India shapefile
plot(shapefile[1])

#Load in the necessary libraries
library(dplyr)

----------------------
#### Data preparation for Type A  #####
----------------------
  
# Read in the type A metadata csv:
type_a <- read.csv("type_A_metadata.csv")
# Check the structure
str(type_a)

# Select necessary columns
type_a <- type_a %>% select(c("media_file_name", "binary_hash", "latitude","longitude","recording_date",
                              "media_length_sec", "state", "ecoregion"))

#Check if the number of the media_file_name is the same as the number of binary_hash 
#(should be same)
length(unique(type_a$media_file_name))
#[1] 1710
length(unique(type_a$binary_hash))
#[1] 1709
#Since they are not the same, binary_hash can be used for deduplication

# You can save this data if you want:
write.csv(type_a, "type_a.csv")

# Check the statewise distribution of recordings for type A:
table(type_a$state)

# Convert type_a to an sf object (points)
type_a_sf <- st_as_sf(type_a, 
                      coords = c("longitude", "latitude"),
                      crs = 4326)  # WGS84 coordinate system

# Make sure shapefile has the same CRS (coordinate reference system)
if (st_crs(shapefile) != st_crs(type_a_sf)) {
  shapefile_valid <- st_transform(shapefile, st_crs(type_a_sf))
}

# Check if there are points outside any state (NA values)
missing_points <- sum(is.na(type_a_sf$state) | type_a_sf$state == "")
if (missing_points > 0) {
  message(paste(missing_points, "points are not within any state polygon"))
}

# Replace the name "Andaman and Nicobar" with "Andaman & Nicobar Islands" and
# "Jammu and Kashmir" with "Jammu & Kashmir" to save space in the figure
# in the state column. Also rename "Delhi" to "NCT of Delhi".
type_a_sf$state[type_a_sf$state == "Andaman and Nicobar Islands"] <- "Andaman & Nicobar Islands"
type_a_sf$state[type_a_sf$state == "Jammu and Kashmir"] <- "Jammu & Kashmir"

# The duplicate files need to be removed to extract the correct recording duration.
# Since the binary_hash is a 64 character hexadecimal string, the distinct operation
# from dplyr will take time. Use data table for this operation instead and then 
# convert it back to an sf object.
library(data.table)

# Convert to data.table (temporary)
type_a_dt <- as.data.table(type_a_sf)
# Deduplicate using binary_hash
type_a_sf_unique <- type_a_dt[, .SD[1], by = binary_hash] %>% st_as_sf()

# Total minutes of recordings in Type A data:
(sum(type_a_sf_unique$media_length_sec))/60
#[1] 3311.362

# Summarize media_length_sec by state
result_a <- type_a_sf_unique %>%
  as.data.frame() %>%  # Convert back to dataframe for faster aggregation
  group_by(state) %>%
  summarise(total_media_length_sec = sum(media_length_sec, na.rm = TRUE)) %>%
  arrange(desc(total_media_length_sec))

# View the result
print(result_a)

#Add columns for time in hours (to 2 decimals) and minutes, with both minutes and 
# and seconds rounded to remove decimals
result_a <- result_a %>% mutate(total_media_length_min = ceiling(total_media_length_sec/60),
                                #Using ceiling above to include data which is less than 1
                                # which will be rounded to 1 minute
                                total_media_length_hr = round(total_media_length_sec/3600,2),
                                total_media_length_sec = round(total_media_length_sec, 0))

#Add the names of the states not in the result from the shapefile_valid$ST_NM

#First fix a typo in the India shapefile:
shapefile$ST_NM[shapefile$ST_NM == "Arunanchal Pradesh"] <- "Arunachal Pradesh"

# Get the exact order of states from shapefile_valid
state <- unique(shapefile$ST_NM)

# Create a data frame with states in the correct order
all_states <- data.frame(state)

# Full join to include all states (including the ones without any recordings)
result_complete_a <- all_states %>%
  # Add all the states/UTs
  full_join(result_a, by = "state") %>%
  # Replace NA with 0 for the media length columns
  mutate(
    total_media_length_sec = ifelse(is.na(total_media_length_sec), 0, total_media_length_sec),
    total_media_length_min = ifelse(is.na(total_media_length_min), 0, total_media_length_min),
    total_media_length_hr = ifelse(is.na(total_media_length_hr), 0, total_media_length_hr)
  )

# View the result
print(result_complete_a)

# Save it as a csv if you want after sorting by recording duration/media length
res_a <- result_complete_a %>%
  arrange(desc(total_media_length_sec))  # Optional: sort by media length

write.csv(res_a, "type_a_summary.csv")
rm(res_a)

# Now it needs to be saved as a dbf to be used as a shapefile
# install.packages("foreign")
library(foreign)

# Create a version with appropriate column names (10 chars max due to dbf format
# limitations)
colnames(result_complete_a) <- c("ST_NM", "TOT_SEC", "TOT_MIN", "TOT_HR")

write.dbf(result_complete_a, "type_a.dbf")

# Now make a copy of the valid_shapefile
# Put it in a seperate folder for type a shapefile
# Replace the .dbf with the one downloaded 
# Rename all the other file types (.shp, .shx, etc) with the name of the .dbf (type_a)
# Now, it is ready to be used for creating a chloropleth in QGIS

--------------------
#### Data preparation for Type B ####
--------------------

# Load the Type B metadata
type_b <- read.csv("type_B_metadata.csv") 

# Check structure
str(type_b)

# Select the relevant columns
type_b <- type_b %>% select(c("media_file_name", "binary_hash", "latitude","longitude",
                              "recording_date","sci_name","media_length_sec",
                              "taxa_info","state","ecoregion"))

# Check if the media_file_name is unique compared to the binary_hash
length(unique(type_b$media_file_name))
#[1] 10073
length(unique(type_b$binary_hash))
#[1] 9755

# They are not. So, use the binary_hash as it is unique

# Load the necessary libraries
library(jsonlite)

# Parse the JSON strings (this would likely take a many seconds)
parsed_data <- lapply(type_b$taxa_info, fromJSON)

# Convert to dataframe and bind to original (this would likely take a few seconds)
df_parsed_b <- bind_rows(parsed_data)

# Remove 'parsed_data' as it is a huge object
rm(parsed_data)

# Check the structure
str(df_parsed_b)

# Combine selected columns with the original dataframe (excluding the original
# taxa_info column)
type_b <- cbind(type_b %>% select(-taxa_info), df_parsed_b %>% 
                  select(c(rank, kingdom, phylum, class, order, family, genus, speciesKey)))
#Save file
write.csv(type_b, "type_b.csv")

# Convert type_b to an sf object (points)
type_b_sf <- st_as_sf(type_b, 
                      coords = c("longitude", "latitude"),
                      crs = 4326, # WGS84 coordinate system
                      remove = FALSE)  # To prevent the removal of the latitude
                                       # and longitude columns which will be
                                       # needed later

# Check if there are points outside any state (NA or empty values). 
missing_points <- sum(is.na(type_b_sf$state) | type_b_sf$state == "" | type_b_sf$state == "UNKNOWN")
if (missing_points > 0) {
  message(paste(missing_points, "points are not within any state polygon"))
}
# 2 points are not within any state polygon
# These are two recordings with no coordinate or state information. Nothing can
# be done about them.

# View a few rows of the object
head(type_b_sf)

# Replace the name "Andaman and Nicobar" with "Andaman & Nicobar Islands" to save 
# space in the figure in the state column (no data from Jammu and Kashmir in Type B
# data)
type_b_sf$state[type_b_sf$state == "Andaman and Nicobar Islands"] <- "Andaman & Nicobar Islands"

# The duplicate files need to be removed to extract the correct recording duration.
# Since the binary_hash is a 64 character hexadecimal string, the distinct operation
# from dplyr will take time. Use data table for this operation instead and then 
# convert it back to an sf object.
library(data.table)

# Convert to data.table (temporary)
type_b_dt <- as.data.table(type_b_sf)
type_b_sf_unique <- type_b_dt[, .SD[1], by = binary_hash] %>% st_as_sf()

# Summarize media_length_sec by state
result_b <- type_b_sf_unique %>%
  as.data.frame() %>%  # Convert back to dataframe for faster aggregation
  group_by(state) %>%
  summarise(total_media_length_sec = sum(media_length_sec, na.rm = TRUE)) %>%
  arrange(desc(total_media_length_sec))  # Optional: sort by highest total

# View the result
print(result_b)

# Remove the row for which state data is not available (unfortunately). This 
# is around 71 seconds:
result_b <- result_b %>%
                 filter(state != "UNKNOWN")

#Add columns for time in hours (to 2 decimals) and minutes, with both minutes and 
# and seconds rounded to remove decimals
result_b <- result_b %>% mutate(total_media_length_min = ceiling(total_media_length_sec/60),
                                #Using ceiling above to include data which is less than 1
                                # which will be rounded to 1 minute
                                total_media_length_hr = round(total_media_length_sec/3600,2),
                                total_media_length_sec = round(total_media_length_sec, 0))

# Add the names of the states not in the result from the shapefile_valid$ST_NM (using
# the all_states object from type A)

# Full join to include all states
result_complete_b <- all_states %>%
  full_join(result_b, by = "state") %>%
  # Replace NA with 0 for the media length columns
  mutate(
    total_media_length_sec = ifelse(is.na(total_media_length_sec), 0, total_media_length_sec),
    total_media_length_min = ifelse(is.na(total_media_length_min), 0, total_media_length_min),
    total_media_length_hr = ifelse(is.na(total_media_length_hr), 0, total_media_length_hr)
  ) 

# View the result
print(result_complete_b)

# Save it as a csv if you want after sorting by recording duration/media length
res_b <- result_complete_b %>%
  arrange(desc(total_media_length_sec))  # Sort by media length

write.csv(res_b, "type_b_summary.csv")
rm(res_b)

# Now it needs to be saved as a dbf to be used as a shapefile

# Create a version with appropriate column names (10 chars max due to dbf format
# limitations)
colnames(result_complete_b) <- c("ST_NM", "TOT_SEC", "TOT_MIN", "TOT_HR")

# Save it
write.dbf(result_complete_b, "type_b.dbf")

# Now make a copy of the valid_shapefile
# Put it in a seperate folder for type a shapefile
# Replace the .dbf with the one downloaded 
# Rename all the other file types (.shp, .shx, etc) with the name of the .dbf (type_b)
# Now, it is ready to be used for creating a chloropleth in QGIS

# Total number of states covered by both Type A and Type B data =
length(union(result_a$state, result_b$state))
#[1] 25

# The states themselves
union(result_a$state, result_b$state)

-------------------
## Bubble plot ####
-------------------
  
-------------------------
#### Getting started ####
-------------------------
  
#Load in the geometry-fix ecoregions shapefile clipped to India
ecoregions <- st_read("ecoregions.gpkg")   

#Plot ecoregions
plot(ecoregions[2])

---------------------
#### Data preparation for Type A #####
---------------------
  
# Use the type_a_sf_unique object from the chloropleth stage
  
# Make sure shapefile has the same CRS (coordinate reference system)
if (st_crs(ecoregions) != st_crs(type_a_sf_unique)) {
    ecoregions <- st_transform(ecoregions, st_crs(type_a_sf_unique))
  }

# Check if there are points outside any ecoregion (NA values or empty)
missing_points <- sum(is.na(type_a_sf_unique$eco_name) | type_a_sf_unique$eco_name == "")
if (missing_points > 0) {
  message(paste(missing_points, "points are not within any state polygon"))
}
# All are inside

#Find out all the ecoregions which contains type A data:
unique(type_a_sf_unique$ecoregion) 

# Note that "Indian Ocean" was added and not part of the original terrestrial 
# ecoregions classification. So, the data falls under 23 ecoregions + Indian Ocean

# Summarize media_length_sec by ecoregion
result_ecoregions_a <- type_a_sf_unique %>%
  as.data.frame() %>%  # Convert back to dataframe for faster aggregation
  group_by(ecoregion) %>%
  summarise(total_media_length_sec = sum(media_length_sec, na.rm = TRUE)) %>%
  arrange(desc(total_media_length_sec))  # Optional: sort by highest total

# View the result
print(result_ecoregions_a)

# Find out the total duration of recording available in type A data:

# In seconds
sum(result_ecoregions_a$total_media_length_sec)

# In minutes
sum(result_ecoregions_a$total_media_length_sec)/60

# In hours
sum(result_ecoregions_a$total_media_length_sec)/3600

# Proportion of the ecoregion with the maximum amount of recordings
# (South Western Ghats montane rain forests) 
(max(result_ecoregions_a$total_media_length_sec)/
    sum(result_ecoregions_a$total_media_length_sec))*100

# The actual amount of minutes from South Western Ghats montane rain forests:
max(result_ecoregions_a$total_media_length_sec)/60

#Add columns for time in hours (to 2 decimals) and minutes, with both minutes and 
# and seconds rounded to remove decimals
result_ecoregions_a <- result_ecoregions_a %>% mutate(total_media_length_min = ceiling(total_media_length_sec/60),
                                                      #Using ceiling above to include data which is less than 1
                                                      # which will be rounded to 1 minute
                                                      total_media_length_hr = round(total_media_length_sec/3600,2),
                                                      total_media_length_sec = round(total_media_length_sec, 0))

# View the result
head(result_ecoregions_a)

#Add the names of the ecoregions not in the result from the ecoregions$ECO_NAME

# Get all unique ecoregions from the shapefile
all_ecoregions <- data.frame(ecoregion = unique(ecoregions$ECO_NAME))

# Full join to include all ecoregions
result_ecoregions_a <- all_ecoregions %>%
  full_join(result_ecoregions_a, by = "ecoregion") %>%
  # Replace NA with 0 for the media length columns
  mutate(
    total_media_length_sec = ifelse(is.na(total_media_length_sec), 0, total_media_length_sec),
    total_media_length_min = ifelse(is.na(total_media_length_min), 0, total_media_length_min),
    total_media_length_hr = ifelse(is.na(total_media_length_hr), 0, total_media_length_hr)
  ) %>%
  arrange(desc(total_media_length_sec))  # Optional: sort by media length

# Save this table
write.csv(result_ecoregions_a, "type_a_summary_ecoregions.csv")

# Add the column with the most recurring coordinate for an ecoregion (and not
# the centroid as there is at least one ecoregion which completely encloses
# another ecoregion):

# Find the most recurring coordinate (this is optimized for large datasets)
most_frequent_geom_a <- type_a_sf_unique %>%
  st_drop_geometry() %>%
  # Create coordinate ID
  mutate(
    coords = st_coordinates(type_a_sf_unique),
    coords_id = paste0(round(coords[,1], 5), "_", round(coords[,2], 5))
  ) %>%
  group_by(ecoregion) %>%
  # Find most frequent coordinate ID
  count(coords_id) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>%
  # Extract coordinates from ID
  mutate(
    lon = as.numeric(sub("_.*", "", coords_id)),
    lat = as.numeric(sub(".*_", "", coords_id))
  ) %>%
  select(ecoregion, lon, lat)

# Change the coordinates for the Indian Ocean as it is too close to the Andaman
# Islands and won't be very clearly visible in the map. Change it to a little
# further away from the coast even if that was not the area where the animals
# were recorded from
most_frequent_geom_a$lat[most_frequent_geom_a$ecoregion == "Indian Ocean"] <- 11.585339
most_frequent_geom_a$lon[most_frequent_geom_a$ecoregion == "Indian Ocean"] <- 93.972708

# Convert to sf
most_frequent_geom_a <- st_as_sf(most_frequent_geom_a, 
                                 coords = c("lon", "lat"),
                                 crs = st_crs(type_a_sf_unique))

# Join with result_ecoregions_a
result_ecoregions_a <- result_ecoregions_a %>%
  left_join(most_frequent_geom_a, by = "ecoregion")

#Convert to sf object
result_ecoregions_a <- st_as_sf(result_ecoregions_a)

---------------------
#### Data preparation for Type B #####
---------------------
  
# Use the type_b_sf_unique object from the chloropleth stage

# Check if there are points outside any ecoregion (NA values) or empty)
missing_points <- sum(is.na(type_b_sf_unique$ecoregion) | type_b_sf_unique$ecoregion == "" | type_b_sf_unique$ecoregion == "#N/A")
if (missing_points > 0) {
  message(paste(missing_points, "points are not within any state polygon"))
}
# 2 points are not within any state polygon 
#(the same two recordings as shown in the chloropleth stage)

# If you want to verify, you can view which points are have eco_name as NA,
# and how many seconds/minutes each recording is
type_b_sf_unique %>% 
  filter(is.na(type_b_sf_unique$ecoregion)| type_b_sf_unique$ecoregion == "" | type_b_sf_unique$ecoregion == "#N/A") %>%
  select(media_file_name, sci_name, state, ecoregion, media_length_sec) %>%
  View()

# These have no coordinate or state information associated with it. So, they need
# to be removed as they can't be used.

# Remove the row for which no coordinate or state information is available (unfortunately)
# This around 71 seconds of data
type_b_sf_unique <- type_b_sf_unique %>%
  filter(!(ecoregion == "#N/A"))

#Find out all the ecoregions which contains type B data:
unique(type_b_sf_unique$ecoregion)  

#Check if all the NAs have gone:
if (any(is.na(type_b_sf_unique$ecoregion))) {
  message("Ecoregion names still have NA")
} else {
  message("No ecoregions are missing names")
}
# No ecoregions are missing names

# Summarize media_length_sec by ecoregion
result_ecoregions_b <- type_b_sf_unique %>%
  as.data.frame() %>%  # Convert back to dataframe for faster aggregation
  group_by(ecoregion) %>%
  summarise(total_media_length_sec = sum(media_length_sec, na.rm = TRUE)) %>%
  arrange(desc(total_media_length_sec))  # Optional: sort by highest total

# View the result
print(result_ecoregions_b)

# Find out the total duration of recording available in type B data:

# In seconds
sum(result_ecoregions_b$total_media_length_sec)

# In minutes
sum(result_ecoregions_b$total_media_length_sec)/60

# In hours
sum(result_ecoregions_b$total_media_length_sec)/3600

# Proportion of the ecoregion with the maximum amount of recordings
# (East Deccan moist deciduous forests) 
(max(result_ecoregions_b$total_media_length_sec)/
    sum(result_ecoregions_b$total_media_length_sec))*100

# The actual amount from East Deccan moist deciduous forests in minutes
max(result_ecoregions_b$total_media_length_sec)/60

#Add columns for time in hours (to 2 decimals) and minutes, with both minutes and 
# and seconds rounded to remove decimals
result_ecoregions_b <- result_ecoregions_b %>% mutate(total_media_length_min = ceiling(total_media_length_sec/60),
                                                      #Using ceiling above to include data which is less than 1
                                                      # which will be rounded to 1 minute
                                                      total_media_length_hr = round(total_media_length_sec/3600,2),
                                                      total_media_length_sec = round(total_media_length_sec, 0))

# View the result
head(result_ecoregions_b)

# Full join to include all ecoregions
result_ecoregions_b <- all_ecoregions %>%
  full_join(result_ecoregions_b, by = "ecoregion") %>%
  # Replace NA with 0 for the media length columns
  mutate(
    total_media_length_sec = ifelse(is.na(total_media_length_sec), 0, total_media_length_sec),
    total_media_length_min = ifelse(is.na(total_media_length_min), 0, total_media_length_min),
    total_media_length_hr = ifelse(is.na(total_media_length_hr), 0, total_media_length_hr)
  ) %>%
  arrange(desc(total_media_length_sec))  # Optional: sort by media length

# Save it
write.csv(result_ecoregions_b, "type_b_summary_ecoregions.csv")

# Using dplyr on the sf object
# Create a table for minutes by each unique set of coordinates
type_b2 <- type_b_sf_unique %>%
  st_drop_geometry() %>%  # Remove geometry for grouping
  # Group by coordinates
  group_by(latitude, longitude) %>%
  summarise(
    media_length_sec_sum = sum(media_length_sec, na.rm = TRUE),
    count = n(),  # Count no. of media at each location
    .groups = "drop"
  ) %>%
  mutate(media_length_minutes_sum = ceiling(media_length_sec_sum/60)) %>%
  # Convert to sf
  st_as_sf(coords = c("longitude", "latitude"), 
           crs = 4326,  # Use EPSG code or define CRS directly
           remove = FALSE)

# View result
head(type_b2)

#Clean out zeroes and na
type_b2 <- type_b2 %>%
  filter(
    !is.na(latitude),
    !is.na(longitude),
    latitude != 0,           # Remove zero latitude
    longitude != 0,          # Remove zero longitude
    media_length_minutes_sum!= 0      # Remove zero media length 
  )
head(type_b2)

# Perform spatial join - assign each point to an ecoregion (without the duplicates)
pts_with_ecoregions_b <- st_join(type_b2, ecoregions, join = st_within)

# Add the column with the most recurring coordinate for an ecoregion (and not
# the centroid as there is at least one ecoregion which completely encloses
# another ecoregion):

# Ensure points_with_ecoregions is an sf object
if (!inherits(pts_with_ecoregions_b, "sf")) {
  pts_with_ecoregions_b <- st_as_sf(pts_with_ecoregions_b)
}

# Getting the most recurring coordinate (by media_length_sum_sec) - 
# optimized version for large datasets
most_frequent_geom_b <- pts_with_ecoregions_b %>%
  st_drop_geometry() %>%
  # Create coordinate ID
  mutate(
    coords_id = paste0(longitude, "_", latitude)
  ) %>%
  group_by(ECO_NAME) %>%
  # Find coordinate with highest media_length_sec_sum
  slice_max(media_length_sec_sum, n = 1, with_ties = FALSE) %>%
  select(ECO_NAME, 
         lon = longitude, 
         lat = latitude)

# "Andaman Islands rain forests" is missing the most frequent coordinates since
# the coordinate(s) lie outside of the ecoregions boundary
# Manually find one coordinate (ideally the most frequent) that fall within this
# ecoregion. Manually add these data:
most_frequent_geom_b$lat[is.na(most_frequent_geom_b$ECO_NAME)] <- 11.503500
most_frequent_geom_b$lon[is.na(most_frequent_geom_b$ECO_NAME)] <- 92.70170

# Replace NA with "Andaman Islands rain forests"
most_frequent_geom_b$ECO_NAME[is.na(most_frequent_geom_b$ECO_NAME)] <-  "Andaman Islands rain forests"

# Convert to sf
most_frequent_b_sf <- st_as_sf(most_frequent_geom_b, 
                               coords = c("lon", "lat"),
                               crs = st_crs(pts_with_ecoregions_b))

# Rename "ECO_NAME" to "ecoregion"
most_frequent_b_sf <- most_frequent_b_sf %>% rename(ecoregion = ECO_NAME)

# Join with result_ecoregions_b
result_ecoregions_b <- result_ecoregions_b %>%
  left_join(most_frequent_b_sf, by = "ecoregion")

#Convert to sf object
result_ecoregions_b <- st_as_sf(result_ecoregions_b)

-----------------------
### Plotting ####
-----------------------

##### Getting started ####
# Load the necessary packages:
library(ggplot2) # For plotting
library(RColorBrewer) # For colour-blind friendly palette selection
library(ggrepel) # For spacing text
library(ggspatial)  # For scale bar and north arrow

### For creating the palette

# For colouring, first identify which ecoregions have data
ecoregions_with_data_a <- ecoregions %>%
  filter(ECO_NAME %in% result_ecoregions_a$ecoregion[result_ecoregions_a$total_media_length_min > 0])

ecoregions_with_data_b <- ecoregions %>%
  filter(ECO_NAME %in% result_ecoregions_b$ecoregion[result_ecoregions_b$total_media_length_min > 0])

# As Indian Ocean is missing here, we would need the boundary for it.
# Load the shapefile available from here: https://doi.org/10.5281/zenodo.10778079
# (Worldwide Geographic Division: Continents and Oceans/Seas Shapefile by Guilherme Mataveli)
world <- st_read("World_Geographic_Regions/World_Geographic_Regionst.shp")

#Check the regions available in this object
world$Region

# Filter to just the Indian Ocean
ind_oc <- world %>% filter(Region == "Indian Ocean")
# Plot it
plot(ind_oc[3])

# Remove the large world object
rm(world)
# Clean up memory
gc()

# Prepare ind_oc to match the ecoregions data structure
ind_oc <- ind_oc %>%
  mutate(ECO_NAME = "Indian Ocean") %>%  # Add ECO_NAME column
  select(ECO_NAME, geometry) %>% # Keep only necessary columns
  rename(geom = geometry) %>% # Rename geometry to geom to match the eocregions format
  st_zm(drop = TRUE, what = "ZM")  # Drop Z and M dimensions

# Combine with ecoregions_with_data_a
ecoregions_with_data_a <- bind_rows(ecoregions_with_data_a,ind_oc)

# To get the same set of colours for ecoregions of both the type A and type B,
# the ecoregions_with_data object for both type A and type B should be merged
merged_eco_with_data <- union(ecoregions_with_data_a, ecoregions_with_data_b)

# So,  a total of 28 ecoregions + Indian Ocean had data contributions
# Check the names of these
unique(merged_eco_with_data$ECO_NAME)

# Create a proper named vector of colors (for colourblind friendly palette 
# for ecoregions)
num_ecoregions <- n_distinct(merged_eco_with_data$ECO_NAME)

# If you want, you check which palettes in RColorBrewer are colorblind friendly
# RColorBrewer::display.brewer.all(colorblindFriendly = TRUE)

# Using Okabe-Ito palette (colorblind friendly)
base_okabe_ito <- palette.colors(9, palette = "Okabe-Ito")

# Get unique ecoregion names in a consistent order
ecoregion_names <- sort(merged_eco_with_data$ECO_NAME)  # Sort for consistency

# Generate colors for all ecoregions (okabe_ito)
# Interpolate to get more colors
color_palette <- colorRampPalette(base_okabe_ito, space = "Lab", 
                                  interpolate = "spline")
ecoregion_colors <- color_palette(num_ecoregions)

# Create a named vector - this is crucial.
color_vector <- setNames(ecoregion_colors, ecoregion_names)

# Check the colour of Indian Ocean and change it:
color_vector["Indian Ocean"] <- "#F0FFFF"  # Azure

### Calculations for the scale bar

#Calculate the real world distance at your map's latitude

#install.packages("geosphere", repos = "https://cran.r-project.org", type = "source")   
library(geosphere)

# Calculate scale
x_range <- c(67.5, 97.5)
y_range <- c(5.5, 38)
central_lat <- mean(y_range)  # ~21.75°N

# Distance for 1° longitude at central latitude
p1 <- c(mean(x_range), central_lat)
p2 <- c(mean(x_range) + 1, central_lat)
dist_per_degree <- distGeo(p1, p2)  # in meters

# Want 1000 km scale bar
scale_km <- 1000
scale_m <- scale_km * 1000
scale_degrees <- scale_m / dist_per_degree

# Position scale bar in bottom right
x_start <- 86
x_end <- x_start + scale_degrees
y_pos <- 6
tick_height <- 0.6

# Create tick positions (0, 500, 1000 km)
tick_pos <- c(
  x_start,                          # 0 km
  x_start + (scale_degrees / 2),    # 500 km  
  x_start + scale_degrees            # 1000 km
)

### Import the custom SVG north arrow

# Load necessary packages
#install.packages("magick")
#install.packages("rsvg")
library(magick)
library(rsvg)

# Read SVG and convert to black
north_arrow <- image_read_svg("north-arrow-century-gothic.svg", width = 100)

# Convert to black 
north_arrow <- north_arrow %>%
  image_colorize(opacity = 100, color = "black")

# Convert to raster for ggplot
north_arrow <- as.raster(north_arrow)

##### Plot Type A ecoregions map ####
  
#Type A with the title changed to just Type A
bubble_map_type_a <- ggplot() +
  # Plot ALL ecoregions first in white (background)
  geom_sf(data = ecoregions, fill = "white", color = "darkgray", alpha = 1,
          linewidth = 0.1) +
  # Dummy layer for legend - all ecoregions (transparent)
  geom_sf(data = st_as_sf(merged_eco_with_data),  # Use ALL ecoregions, not just those with data
          aes(fill = ECO_NAME),  
          color = NA, 
          alpha = 0,  # Transparent - won't show on map
          show.legend = FALSE) +
  # Overlay ONLY ecoregions with data using their eco_name column
  geom_sf(data = ecoregions_with_data_a,  
          aes(fill = ECO_NAME),  # Use the ECO_NAME column
          color = NA, 
          alpha = 0.7,
          show.legend = FALSE) +
  # Add the bubbles
  geom_sf(data = result_ecoregions_a %>% filter(total_media_length_min > 0), 
          aes(size = total_media_length_min),
          #fill = "#EFBF04",  # Fixed color for bubbles
          fill = NA,  # No color for bubbles (transparent)
          shape = 21,
          alpha = 0.7,
          color = "black") + 
  # Add the individual points (from type_a_sf)
  geom_sf(
    data = type_a_sf,
    size = 0.5,
    color = "white",
    fill = NA,
    alpha = 0.3,
    shape = 16
  ) +
  # Add labels only for ecoregions with data
  geom_label_repel(data = result_ecoregions_a %>% 
                     filter(total_media_length_min > 0) %>%
                     st_coordinates() %>% 
                     as.data.frame() %>% 
                     bind_cols(result_ecoregions_a %>% 
                                 filter(total_media_length_min > 0) %>% 
                                 st_drop_geometry()),
                   aes(x = X, y = Y, label = total_media_length_min),
                   size = 5,
                   alpha = 0.65,
                   family = "Century Gothic",
                   force = 2,
                   label.padding = 0.25,
                   box.padding = 0.5,
                   point.padding = 0.5,
                   min.segment.length = 0,
                   max.overlaps = Inf,
                   seed = 269) +
  # Color scale for ecoregions (use a categorical palette)
  scale_fill_manual(
    values = color_vector,
    name = "Ecoregions with data",
    guide = guide_legend(override.aes = list(size = 3, alpha = 1),
                         ncol = 1
    )
  ) +
  #Size scale for bubbles
  scale_size_continuous(
    range = c(3, 20),
    breaks = pretty(result_ecoregions_a$total_media_length_min[result_ecoregions_a$total_media_length_min > 0], n = 5),
    guide = "none"
  ) +
  labs(x = '',
       y = '',
       title = "Type A") +
  theme_bw() +
  theme(
    plot.title = element_text(
      family = "Century Gothic",
      size = 17, face = "bold", hjust = 0.5
    ),
    axis.text = element_text(family = "Century Gothic", size = 13), 
    panel.border = element_blank(),
    panel.grid = element_blank()
  ) +
  # Add custom gridlines AFTER the shapefiles
  geom_sf(data = st_graticule(lat = seq(8, 37, by = 2.5),
                              lon = seq(70, 95, by = 2.5),
                              crs = st_crs(ecoregions)),
          color = "gray80",  # Light gray gridlines
          linewidth = 0.2,
          alpha = 0.5) +
  # Use coord_sf() with limits
  coord_sf(
    xlim = c(67.5, 97.5),
    ylim = c(5.5, 38),
    expand = FALSE
  ) +
  # Add scale_x/y_continuous inside coord_sf() for proper labeling
  scale_x_continuous(
    breaks = seq(70, 95, by = 2.5), # Align the grid labels with the custom gridlines
    labels = ~paste0(.x, "°E")
  ) +
  scale_y_continuous(
    breaks = seq(8, 37, by = 2.5),
    labels = ~paste0(.x, "°N")
  ) +
  # # Add map elements
  # Scale bar line
  geom_segment(aes(x = x_start, y = y_pos, 
                   xend = x_end, yend = y_pos),
               color = "black", linewidth = 0.25) +
  # Upward ticks
  geom_segment(aes(x = tick_pos, 
                   y = y_pos,  # Start at the line
                   xend = tick_pos, 
                   yend = y_pos + tick_height),  # End above the line
               color = "black", linewidth = 0.25) +
  # Labels
  geom_text(aes(x = tick_pos, y = y_pos + 1.5,
                label = c("0", "500", "1000 km")),
            family = "Century Gothic", size = 4)+
  # North arrow
  # Add to plot
  annotation_raster(
    north_arrow,
    xmin = 95, xmax = 96.5,
    ymin = 34.2, ymax = 36.5
  )

bubble_map_type_a

##### Plot Type B ecoregions map ####

# Type B with north arrow, scale bar, latitude, and legends removed; and titled
# changed to just Type B
bubble_map_type_b <- ggplot() +
  # Plot ALL ecoregions first in white (background)
  geom_sf(data = ecoregions, fill = "white", color = "darkgray", alpha = 1,
          linewidth = 0.1) +
  # Overlay ONLY ecoregions with data using their ECO_NAME column
  geom_sf(data = ecoregions_with_data_b, 
          aes(fill = ECO_NAME),  # Use the ECO_NAME column
          color = NA, 
          alpha = 0.7,
          show.legend = FALSE) +
  # Add the bubbles
  geom_sf(data = result_ecoregions_b %>% filter(total_media_length_min > 0), 
          aes(size = total_media_length_min),
          #fill = "#EFBF04",  # Fixed color for bubbles
          fill = NA,  # No fill color for bubbles
          shape = 21,
          alpha = 0.7,
          color = "black") + 
  # Add the individual points (from type_b2)
  geom_sf(
    data = type_b2,
    size = 0.5,
    color = "white",
    fill = NA,
    alpha = 0.3,
    shape = 16,
    #stroke = 0.5
  ) +
  # Add labels only for ecoregions with data
  geom_label_repel(data = result_ecoregions_b %>% 
                     filter(total_media_length_min > 0) %>%
                     st_coordinates() %>% 
                     as.data.frame() %>% 
                     bind_cols(result_ecoregions_b %>% 
                                 filter(total_media_length_min > 0) %>% 
                                 st_drop_geometry()),
                   aes(x = X, y = Y, label = total_media_length_min),
                   size = 5,
                   alpha = 0.65,
                   family = "Century Gothic",
                   force = 2,
                   label.padding = 0.25,
                   box.padding = 0.5,
                   point.padding = 0.5,
                   min.segment.length = 0,
                   max.overlaps = Inf,
                   seed = 269) +
  # Color scale for ecoregions (use a categorical palette)
  scale_fill_manual(
    values = color_vector,
    name = "Ecoregions with data",
    guide = guide_legend(override.aes = list(size = 3),
                         ncol = 1
    )
  ) +
  #Size scale for bubbles
  scale_size_continuous(
    range = c(3, 20),
    breaks = pretty(result_ecoregions_b$total_media_length_min[result_ecoregions_b$total_media_length_min > 0], n = 5),
    guide = "none"
  ) +
  labs(x = '',
       y = '',
       title = "Type B") +
  theme_bw() +
  theme(
    plot.title = element_text(
      family = "Century Gothic",
      size = 17, face = "bold", hjust = 0.5
    ),
    axis.text = element_text(family = "Century Gothic", size = 13),
    panel.border = element_blank(),
    panel.grid = element_blank()
  ) +
  # Add custom gridlines AFTER the shapefiles
  geom_sf(data = st_graticule(lat = seq(8, 37, by = 2.5),
                              lon = seq(70, 95, by = 2.5),
                              crs = st_crs(ecoregions)),
          color = "gray80",  # Light gray gridlines
          linewidth = 0.2,
          alpha = 0.5) +
  # Use coord_sf() with limits
  coord_sf(
    xlim = c(67.5, 97.5),
    ylim = c(5.5, 38),
    expand = FALSE
  ) +
  # Add scale_x/y_continuous inside coord_sf() for proper labeling
  scale_x_continuous(
    breaks = seq(70, 95, by = 2.5), # Align the grid labels with the custom gridlines
    labels = ~paste0(.x, "°E")
  ) +
  scale_y_continuous(
    breaks = seq(8, 37, by = 2.5)
  ) +
  theme(
    axis.text.y = element_blank(),  # Remove y-axis labels
    axis.ticks.y = element_blank()   # Remove y-axis ticks too
  )

bubble_map_type_b

# Create a separate legend plot
legend_plot <- ggplot() +
  # Dummy layer to generate the legend
  geom_sf(data = st_as_sf(merged_eco_with_data),
          aes(fill = ECO_NAME),  
          color = NA, 
          alpha = 0) +
  scale_fill_manual(
    values = color_vector,
    name = "Ecoregions with data",
    guide = guide_legend(
      override.aes = list(size = 4, alpha = 1),
      ncol = 3,
      title.position = "top",
      title.hjust = 0.5,
      byrow = TRUE,
      label.position = "right"
    )
  ) +
  theme_void() +
  theme(
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.direction = "horizontal",
    legend.justification = "center",
    legend.title = element_text(family = "Century Gothic", size = 16, face = "bold", hjust = 0.5),
    legend.text = element_text(family = "Century Gothic", size = 15),
    legend.key.size = unit(1.2, "lines"),
    legend.key = element_rect(fill = "white", color = NA)
  )

##### Create the combined plot #### 

#install.packages("gridExtra")
library(gridExtra)

ecoregions_plot <- grid.arrange(bubble_map_type_a, bubble_map_type_b, 
                               legend_plot,
                               nrow = 4,
                               layout_matrix = rbind(c(1,1,1,1,2,2,2,2), 
                                                     c(1,1,1,1,2,2,2,2),
                                                     c(1,1,1,1,2,2,2,2), 
                                                     c(3,3,3,3,3,3,3,3)))

ggsave("ecoregions_plot.png", ecoregions_plot, width = 17, height = 13, dpi = 300, 
       bg = "white")

# Taxonomic plots ####

### Non-aves ####

#### Data preparation for Type A ####

# Read in the annotation data for type A
# install.packages(data.table)
library(data.table)
anno_type_a <- as.data.frame(fread("anno.csv"))

# See the structure
str(anno_type_a)
 
# Fix the JSON strings by replacing double quotes
annota <- anno_type_a %>%
  mutate(taxa_info = gsub('""', '"', taxa_info))

# Match any whitespace in the taxa_info and quote variations, and filter them out
# For example: {""rank"": null, ""class"": null, ""genus"": null, ""order"": null, ""family"": null, ""phylum"": null, ""status"": null, ""kingdom"": null, ""classKey"": null, ""genusKey"": null, ""orderKey"": null, ""usageKey"": null, ""familyKey"": null, ""matchType"": ""NONE"", ""phylumKey"": null, ""confidence"": 100, ""kingdomKey"": null, ""speciesKey"": null, ""canonicalName"": null, ""scientificName"": null, ""acceptedUsageKey"": null}
annota <- annota %>%
  filter(!grepl('"rank"\\s*:\\s*null\\s*,', taxa_info))
# The above step removes all the non-organism annotations like noise and wind.

#Remove Homo sapiens (Humans) from the data to keep it to only wild species
annota <- annota %>%
  filter(!grepl("Homo sapiens", sci_name))

#Parse it:
parsed_data <- lapply(annota$taxa_info, fromJSON)

# Convert to dataframe and bind to original
df_parsed_a <- bind_rows(parsed_data)

# Remove the object 'parsed_data' as it is large
rm(parsed_data)

# Combine with original dataframe (excluding the original taxa_info column)
ta <- cbind(annota %>% select(-taxa_info), df_parsed_a %>% 
              select(c(rank, kingdom, phylum, class, order, family, genus, confidence, speciesKey)))

# Select only those rows which are unique species for a given media_file_name
# (to make it comparable to type B)
ta_distinct <- ta %>%
  distinct(`media_file_name`, sci_name, .keep_all = TRUE)

# Filter to only non-aves
non_aves_type_a <- ta_distinct %>%
  filter(!grepl("Aves", `class`))

# Prepare the necessary data
# Create class counts
class_counts_a <- non_aves_type_a %>%
  count(class, name = "count") %>%
  mutate(class = ifelse(is.na(class), "Unknown", class)) %>%
  arrange(desc(count))

# Create order counts within each class
order_counts_a <- non_aves_type_a %>%
  mutate(
    class = ifelse(is.na(class), "Unknown", class),
    order = ifelse(is.na(order), "Unknown", order)
  ) %>%
  count(class, order, name = "count") %>%
  arrange(class, desc(count))

print(order_counts_a)
#              class          order count
# 1  Actinopterygii   Siluriformes     1
# 2        Amphibia          Anura   257
# 3         Insecta     Orthoptera    62
# 4         Insecta      Hemiptera    16
# 5         Insecta    Hymenoptera     5
# 6         Insecta        Unknown     4
# 7         Insecta        Diptera     1
# 8         Insecta    Trichoptera     1
# 9        Mammalia       Primates    59
# 10       Mammalia     Chiroptera    38
# 11       Mammalia       Rodentia    24
# 12       Mammalia      Carnivora     8
# 13       Mammalia        Sirenia     6
# 14       Mammalia   Artiodactyla     2
# 15       Mammalia Perissodactyla     1
# 16       Reptilia       Squamata     1
# 17        Unknown        Unknown     7

#Remove the row with both class and order given as unknown
order_counts_a <- order_counts_a %>% filter(class != "Unknown")

# Create data with class total, class %, and label for the figure 
order_counts_nested_a <- order_counts_a %>%
  group_by(class) %>%
  mutate(
    class_total = sum(count),
    class_percent = count / class_total * 100,
    order_label_large = paste0(order, ": ", count, "\n (", round(class_percent, 2), "%)"),
    order_label_small = paste0(order, ": ", count, " (", round(class_percent, 2), "%)"),
    cumulative = cumsum(count), # For calculating the correct positions for each 
    #segment/label in the bar plot
    label_position = cumulative - count/2  # Center of each segment
  ) %>%
  ungroup()

# Check the structure
str(order_counts_nested_a)

#### Data preparation for Type B ####

# Filter to only non-aves
non_aves_type_b <- type_b_sf %>%
                   st_drop_geometry() %>%
                   filter(!grepl("Aves", `class`))

#Remove the row with class and order and given as unknown
non_aves_type_b <- non_aves_type_b %>% filter(class != "Unknown")

# Prepare the data
# Create class counts
class_counts_b <- non_aves_type_b %>%
  count(class, name = "count") %>%
  mutate(class = ifelse(is.na(class), "Unknown", class)) %>%
  arrange(desc(count))

print(class_counts_b)

# Create order counts within each class
order_counts_b <- non_aves_type_b %>%
  mutate(
    class = ifelse(is.na(class), "Unknown", class),
    order = ifelse(is.na(order), "Unknown", order)
  ) %>%
  count(class, order, name = "count") %>%
  arrange(class, desc(count))

print(order_counts_b)

# Create data with class total, class %, and label for the figure 
order_counts_nested_b <- order_counts_b %>%
  group_by(class) %>%
  mutate(
    class_total = sum(count),
    class_percent = count / class_total * 100,
    order_label_large = paste0(order, ": ", count, "\n (", round(class_percent, 2), "%)"),
    order_label_small = paste0(order, ": ", count, " (", round(class_percent, 2), "%)"),
    cumulative = cumsum(count), # For calculating the correct positions for each 
    #segment/label in the bar plot
    label_position = cumulative - count/2  # Center of each segment
  ) %>%
  ungroup()

# Check the structure:
str(order_counts_nested_b)

#### Plotting #####

##### Getting started #####

# Setting colour 
# First, create a proper named vector of colors (for colourblind friendly palette)
#For type A and B combined
num_orders <- n_distinct(union(order_counts_b$order, order_counts_a$order))

# Choose a colorblind friendly palette

# Okabe-Ito palette
base_okabe_ito <- palette.colors(9, palette = "Okabe-Ito")

# Get unique ecoregion names in a consistent order
order_names <- sort(unique(union(order_counts_b$order, order_counts_a$order)))

# Generate colors for all orders (okabe_ito)
# Interpolate to get more colors
color_palette <- colorRampPalette(base_okabe_ito, space = "Lab", 
                                  interpolate = "spline")
order_colors <- color_palette(num_orders)

# Create a named vector - this is crucial.
color_vector_order <- setNames(order_colors, order_names)

##### Plot Type A non-aves stacked bar-plot #####

non_aves_a <- ggplot(order_counts_nested_a, 
                                     aes(x = reorder(class, -class_total), 
                                         y = count, 
                                         fill = reorder(order, -count))) +
  geom_bar(stat = "identity", position = position_stack(reverse = TRUE), color = "black",
           show.legend = FALSE) +
  
  # For largest segments: normal labels
  geom_text(data = order_counts_nested_a %>% filter(class_percent > 10),
            aes(label = order_label_large,
                y = label_position),  #Use calculated position
            color = "white", size = 5.2, fontface = "bold",
            family = "Century Gothic") +
  
  # For medium segments: small labels
  geom_text(data = order_counts_nested_a %>% 
            filter(class_percent > 4 & class_percent < 10),
            aes(label = order_label_small,
                y = label_position),  #Use calculated position
            color = "white", size = 3.2, fontface = "bold",
            family = "Century Gothic") +
  
  # For small segments: ggrepel callouts
  geom_text_repel(data = order_counts_nested_a %>% 
                  filter(class_percent < 4 & count > 0 | class_total < 5),
                  aes(label = order_label_small,
                      y = cumulative),  # Use top of segment
                  direction = "y",  # Keep vertical
                  nudge_y = max(order_counts_nested_a$class_total) * 0.05,  # Move up
                  segment.size = 0.3,
                  segment.color = "gray50",
                  box.padding = 0.3,
                  point.padding = 0,
                  min.segment.length = 0,
                  size = 3.7,
                  color = "black",
                  #fontface = "bold",
                  family = "Century Gothic") +
  scale_fill_manual(
    values = color_vector_order,
    name = "Order",
    guide = guide_legend(override.aes = list(size = 3),
                         ncol = 1)
  )+
  labs(
    title = "Type A",
    x = "Class",
    y = "Summed label count of species within each recording falling within an order",
    caption = paste("Total count:", sum(order_counts_nested_a$count))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(
      family = "Century Gothic",
      size = 16, hjust = 0.5
    ),
    axis.title = element_text(
      family = "Century Gothic",
      size = 16
    ),
    plot.caption = element_text(
      family = "Century Gothic",
      size = 12, face = "plain", hjust = 1  # hjust = 1 for right-aligned
    ),
    axis.text = element_text(family = "Century Gothic", size = 14), 
    panel.border = element_blank(),
    panel.grid = element_blank()
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))  # Add some space at top

non_aves_a

##### Plot Type B non-aves stacked bar-plot #####

# Create the nested stacked bar plot
non_aves_b <- ggplot(order_counts_nested_b, 
                                     aes(x = reorder(class, -class_total), 
                                         y = count, 
                                         fill = reorder(order, -count))) +
  geom_bar(stat = "identity", position = position_stack(reverse = TRUE), color = "black",
           show.legend = FALSE) +
  
  # For largest segments: normal labels
  geom_text(data = order_counts_nested_b %>% filter(class_percent > 5),
            aes(label = order_label_large,
                y = label_position),  #Use calculated position
            color = "white", size = 5.4, fontface = "bold",
            family = "Century Gothic") +
  
  # For medium segments: small labels
  geom_text(data = order_counts_nested_b %>% 
              filter(class_percent < 5  & class_percent > 0),
            aes(label = order_label_small,
                y = label_position),  #Use calculated position
            color = "white", size = 4.1, fontface = "bold",
            family = "Century Gothic") +
  
  scale_fill_manual(
    values = color_vector_order,
    name = "Order",
    guide = guide_legend(override.aes = list(size = 3),
                         ncol = 1)
  )+
  labs(
    title = "Type B",
    x = "Class",
    caption = paste("Total count:", sum(order_counts_nested_b$count))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(
      family = "Century Gothic",
      size = 16, face = "bold", hjust = 0.5
    ),
    axis.title = element_text(
      family = "Century Gothic",
      size = 16
    ),
    plot.caption = element_text(
      family = "Century Gothic",
      size = 12, face = "plain", hjust = 1  # hjust = 1 for right-aligned
    ),
    axis.text = element_text(family = "Century Gothic", size = 14), 
    panel.border = element_blank(),
    panel.grid = element_blank(),
    axis.title.y = element_blank()
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))  # Add some space at top

non_aves_b

##### Create the combined plot #####

# Horizontal
combined_non_aves <- non_aves_a + non_aves_b +
                     plot_layout(nrow = 1)

# Save
ggsave("combined_plots_orders_horiztonal_it5.png", combined_non_aves, width = 18, 
       height = 11, dpi = 300)

### Aves - order and class ####

#### Data preparation for Type A ####

# Filter to only aves
aves_type_a <- ta_distinct %>%
               filter(grepl("Aves", `class`))

# Create order counts within each class
family_counts_aves_a <- aves_type_a %>%
  mutate(
    order = ifelse(is.na(order), "Unknown", order),
    family = ifelse(is.na(family), "Unknown", family)
  ) %>%
  count(order, family, name = "count") %>%
  arrange(order, desc(count)) %>%
  filter(!order == "Unknown")%>%
  group_by(order) %>%
  mutate(
    order_total = sum(count),
    family_percent = count / order_total * 100,
    family_label = paste0(family,"\n",round(family_percent, 2), "%")
  ) %>%
  ungroup()

total_order_count_a <- sum(family_counts_aves_a$count)

family_counts_aves_a <- family_counts_aves_a %>% 
                        group_by(order)  %>%
                        mutate(
                        order_percent = order_total / total_order_count_a * 100,
                        order_label = paste0(order, " (", round(order_percent, 2), "%)")
                        ) %>%
                        ungroup() 

#### Data preparation for Type B ####

# Filter to only aves
aves_type_b <- type_b_sf %>%
               st_drop_geometry() %>%
               filter(grepl("Aves", `class`))

# Create order counts within each class
family_counts_aves_b <- aves_type_b %>%
  mutate(
    order = ifelse(is.na(order), "Unknown", order),
    family = ifelse(is.na(family), "Unknown", family)
  ) %>%
  count(order, family, name = "count") %>%
  arrange(order, desc(count)) %>%
  filter(!order == "Unknown")%>%
  group_by(order) %>%
  mutate(
    order_total = sum(count),
    family_percent = count / order_total * 100,
    family_label = paste0(family,"\n",round(family_percent, 2), "%")
  ) %>%
  ungroup()

total_order_count_b <- sum(family_counts_aves_b$count)

family_counts_aves_b <- family_counts_aves_b %>% 
  group_by(order)  %>%
  mutate(
    order_percent = order_total / total_order_count_b * 100,
    order_label = paste0(order, " (", round(order_percent, 2), "%)")
  ) %>%
  ungroup() 

#### Plotting #####

##### Getting started #####

# Create a proper named vector of colors (for both type A and type B combined)
num_orders <- n_distinct(union(family_counts_aves_a$order, family_counts_aves_b$order))

# Choose a colorblind friendly palette
#RColorBrewer Set3 (good for categorical)
order_colors <- colorRampPalette(brewer.pal(12, "Set3"))(num_orders)

# Get unique order names in a consistent order
# Sort for consistency
order_names <- sort(unique(union(family_counts_aves_a$order, family_counts_aves_b$order)))

# Create a named vector - this is crucial.
color_vector_order <- setNames(order_colors, order_names)

# For getting the legend with all the names:
merged_aves_with_data <- union(family_counts_aves_a, family_counts_aves_b)

##### Plotting Type A aves treemap ####

# Load the treemapify library (in addition to ggplot2 already loaded)
#install.packages("treemapify")
library(treemapify)

treemap_aves_a <- ggplot(family_counts_aves_a, 
                  aes(area = sqrt(count),  # TRANSFORMATION APPLIED HERE
                      fill = order,
                      subgroup = order,
                      subgroup2 = family,
                      label = family_label)) +
  geom_treemap() +
  geom_treemap_subgroup_border(color = "black", size = 2) +
  geom_treemap_subgroup2_border(color = "black", size = 0.8) +
  
  theme_minimal() +
  theme(
    plot.title = element_text(
      family = "Century Gothic",
      size = 18, hjust = 0.5
    ),
    legend.position = "right",
    legend.title = element_text(family = "Century Gothic", size = 14), 
    legend.text = element_text(family = "Century Gothic", size = 12),
    legend.key.size = unit(1.2, "lines")
  ) +
  
  # Use smaller text that reflows within boxes
  geom_treemap_text(
    color = "black",
    place = "center",
    grow = TRUE,        # Allow text to shrink for small boxes
    min.size = 2,       # Minimum text size (pts)
    padding.x = grid::unit(1, "mm"),  # Small padding
    padding.y = grid::unit(1, "mm"),
    family = "Century Gothic"
  ) +
  
  labs(
    title = "Type A"
  ) +
  scale_fill_manual(
    values = color_vector_order,
    name = "Order",
    labels = unique(family_counts_aves_a$order_label),
    guide = guide_legend(override.aes = list(size = 3),
                         ncol = 1
    ))

treemap_aves_a

##### Plotting Type B aves treemap ####

treemap_aves_b <- ggplot(family_counts_aves_b, 
                         aes(area = sqrt(count),  # TRANSFORMATION APPLIED HERE
                             fill = order,
                             subgroup = order,
                             subgroup2 = family,
                             label = family_label)) +
  geom_treemap() +
  geom_treemap_subgroup_border(color = "black", size = 2) +
  geom_treemap_subgroup2_border(color = "black", size = 0.8) +
  
  theme_minimal() +
  theme(
    plot.title = element_text(
      family = "Century Gothic",
      size = 18, hjust = 0.5
    ),
    legend.position = "right",
    legend.title = element_text(family = "Century Gothic", size = 14), 
    legend.text = element_text(family = "Century Gothic", size = 12),
    legend.key.size = unit(1.2, "lines")
  ) +
  
  # Use smaller text that reflows within boxes
  geom_treemap_text(
    color = "black",
    place = "center",
    grow = TRUE,        # Allow text to shrink for small boxes
    min.size = 2,       # Minimum text size (pts)
    padding.x = grid::unit(1, "mm"),  # Small padding
    padding.y = grid::unit(1, "mm"),
    family = "Century Gothic"
  ) +
  
  labs(
    title = "Type B"
  ) +
  scale_fill_manual(
    values = color_vector_order,
    name = "Order",
    labels = unique(family_counts_aves_b$order_label),
    guide = guide_legend(override.aes = list(size = 3),
                         ncol = 1
    ))

treemap_aves_b

##### Create the combined plot #####

#stacked up-and-down
combined_aves <- treemap_aves_a + treemap_aves_b +
                  plot_layout(ncol = 1)

ggsave("combined_treemap_aves_vertical_it3.png", combined_aves, width = 14, height = 18, dpi = 300)

# Taxonomic data ####

### Type A ####

# Check the taxonomic distribution of the data (at label level)
table(ta$rank)

#So, 
(table(ta$rank)[["SPECIES"]]/nrow(ta))*100
#[1] 96.48129
# percent of the organisms were identified to the species level
# Check the number of kingdom, phylum, class, order, family, genus, and species
table(ta$kingdom)
# Animalia 
# 36718 
# All the organisms in the Type A dataset are animals
table(ta$phylum)
# Arthropoda   Chordata 
# 461      36254 
# 2 phyla.
# % of Chordata =
(table(ta$phylum)[["Chordata"]]/nrow(ta))*100
# % of Arthropoda =
(table(ta$phylum)[["Arthropoda"]]/nrow(ta))*100

# See the names and contributions of each class
table(ta$class)
# Actinopterygii       Amphibia           Aves        Insecta       Mammalia       Reptilia 
#             11          16244          19087            450            911              1 
# So, 6 classes. 
#% of annotations of Aves
(table(ta$class)[["Aves"]]/nrow(ta))*100
#% of annotations of Amphibia
(table(ta$class)[["Amphibia"]]/nrow(ta))*100
#% of annotations of Mammalia
(table(ta$class)[["Mammalia"]]/nrow(ta))*100
#% of annotations of Insecta
(table(ta$class)[["Insecta"]]/nrow(ta))*100
#% of annotations of Actinopterygii (ray-finned fishes)
(table(ta$class)[["Actinopterygii"]]/nrow(ta))*100
#% of annotations of Reptilia
(table(ta$class)[["Reptilia"]]/nrow(ta))*100

# List the names and contribution of the orders
table(ta$order)
length(unique(ta$order))
# [1] 36
# So, 36 orders.
#Percentage of the most dominant order (Anura) =
(table(ta$order)[["Anura"]]/nrow(ta))*100
#Percentage of the second most dominant order (Passeriformes) =
(table(ta$order)[["Passeriformes"]]/nrow(ta))*100

# List the names and contributions of the families
table(ta$family)
length(unique(ta$family))
# [1] 102
# So, 102 families.
# Sort the table in descending order
sorted_table <- sort(table(ta$family), decreasing = TRUE)
# View the top 10
head(sorted_table, 10)
#Percentage of the most dominant family (Rhacophoridae) =
(table(ta$family)[["Rhacophoridae"]]/nrow(ta))*100
#Percentage of the second most dominant family (Muscicapidae) =
(table(ta$family)[["Muscicapidae"]]/nrow(ta))*100

# list the names and contribution of the genera
length(unique(ta$genus))
# [1] 226
# So, 226 genera.
# Sort the table in descending order
sorted_table <- sort(table(ta$genus), decreasing = TRUE)
# View the top 10
head(sorted_table, 10)
#Percentage of the most dominant genus (Raorchestes) =
(table(ta$genus)[["Raorchestes"]]/nrow(ta))*100
#Percentage of the second most dominant genus (Trochalopteron) =
(table(ta$genus)[["Trochalopteron"]]/nrow(ta))*100
sorted_table <- sort(table(ta$sci_name), decreasing = TRUE)
head(sorted_table, 10)

#Percentage of the most dominant species (Raorchestes luteolus) =
(table(ta$sci_name)[["Raorchestes luteolus"]]/nrow(ta))*100
#Percentage of the second most dominant species (Raorchestes hassanensis) =
(table(ta$sci_name)[["Raorchestes hassanensis"]]/nrow(ta))*100

# To see all the sci_name in type A data
sort(unique(ta$sci_name))
# To see the number of unique sci_name in type A data
length(unique(ta$sci_name))
# 401

# Count the unique number of species using the speciesKey
# and also check if this is accurate by checking if all the genera, families,
# and orders are represented from the larger data (ta)
species_a <- ta %>%
  distinct(`speciesKey`, .keep_all = TRUE) %>%
  select(speciesKey, sci_name, genus, family, order, class) %>%
  arrange(`sci_name`)

# Total number of species
length(unique(species_a$sci_name))
#[1] 373

# Check the actual names
unique(species_a$sci_name)
#"frog/insect" is not a valid species.
# So, the total number of species in Type A is 372 (assuming we haven't missed
# any species at genus level). Notonectidae is at family level. So, at species 
# level, there are 371.

length(unique(species_a$genus))
#[1] 221
length(unique(ta$genus))
#[1] 226

# It shows 5 additional genera in the larger dataset. Check what those 5 genera 
# are
setdiff(unique(ta$genus), unique(species_a$genus))
# [1] "Dugong"   "Eumenes"  "Camera"   "Xylocopa" "Sterna"  

# So, these 5 species need to be added too.

# So, total number of species = 372+5 = 377

# Check any missing family in the unique data
length(unique(species_a$family))
#[1] 93
length(unique(ta$family))
#[1] 103

# So, there are 10 families missing, indicating potential 10 species more. Check
# them 
setdiff(unique(ta$family), unique(species_a$family))
# [1] "Dugongidae"    "Gryllidae"     "Cicadidae"     NA              "Eumenidae"     "Vespidae"      "Oecanthidae"  
# [8] "Ichneumonidae" "Apidae"        "Laridae"    

# Oecanthidae could be a synonym for Gryllidae depending on the taxonomy. So,
# only one can be considered as a unique new species.
# Eumenidae could be a synonym for Vespidae. So, its already covered.

# So, 2 more species. 377+2 = 379

# Check any missing order in the unique data
length(unique(species_a$order))
#[1] 30
length(unique(ta$order))
#[1] 36

# So, there are 6 orders missing, indicating 6 potential species more. Check
# them 
setdiff(unique(ta$order), unique(species_a$order))
# [1] "Sirenia"     "Orthoptera"  NA            "Trichoptera" "Hymenoptera" "Diptera"   

# Only Trichoptera and Diptera are not covered by species, genus, or family stages
#So, 379+2 = 381 species in Type A data

### Type B ####

# Check the taxonomic distribution of the data (at label level)
table(type_b_sf$rank)

#So, 
(table(type_b_sf$rank)[["SPECIES"]]/nrow(type_b_sf))*100
#[1] 99.42451
# percent of the organisms were identified to the species level

# Check the number of kingdom, phylum, class, order, family, genus, and species
table(type_b_sf$kingdom)
# Animalia 
# 27435 
# So, all organisms are animals in the type B dataset too
table(type_b_sf$phylum)
# Arthropoda   Chordata 
#         79      27375 
#Percentage of Chordata in type B dataset =
(table(type_b_sf$phylum)[["Chordata"]]/nrow(type_b_sf))*100
#Percentage of Arthropoda in type B dataset =
(table(type_b_sf$phylum)[["Arthropoda"]]/nrow(type_b_sf))*100

# List the names and contribution of each class
table(type_b_sf$class)
# Amphibia     Aves  Insecta Mammalia 
#       73    27225       79       77 
#% of annotations of Aves
(table(type_b_sf$class)[["Aves"]]/nrow(type_b_sf))*100
#% of annotations of Insecta
(table(type_b_sf$class)[["Insecta"]]/nrow(type_b_sf))*100
#% of annotations of Mammalia
(table(type_b_sf$class)[["Mammalia"]]/nrow(type_b_sf))*100
#% of annotations of Amphibia
(table(type_b_sf$class)[["Amphibia"]]/nrow(type_b_sf))*100

# List the names and contribution of each order
table(type_b_sf$order)
length(unique(type_b_sf$order))
# [1] 28
# So, 28 orders.
#Percentage of the most dominant order (Passeriformes) =
(table(type_b_sf$order)[["Passeriformes"]]/nrow(type_b_sf))*100
#Percentage of the second most dominant order (Psittaciformes) =
(table(type_b_sf$order)[["Psittaciformes"]]/nrow(type_b_sf))*100

# List the names and contributions of each family
table(type_b_sf$family)
# Find the number of families
length(unique(type_b_sf$family))
sorted_table <- sort(table(type_b_sf$family), decreasing = TRUE)
# See the top 10 families in terms of representation/contribution
head(sorted_table, 10)
#Percentage of the most dominant family (Psittacidae) =
(table(type_b_sf$family)[["Psittacidae"]]/nrow(type_b_sf))*100
#Percentage of the second most dominant family (Cuculidae) =
(table(type_b_sf$family)[["Cuculidae"]]/nrow(type_b_sf))*100
#Percentage of the third most dominant family (Columbidae) =
(table(type_b_sf$family)[["Columbidae"]]/nrow(type_b_sf))*100

# See the number of genera in Type B data
length(unique(type_b_sf$genus))
# Sort the table in descending order
sorted_table <- sort(table(type_b_sf$genus), decreasing = TRUE)
# View the top 10
head(sorted_table, 10)
#Percentage of the most dominant genus (Psittacula) =
(table(type_b_sf$genus)[["Psittacula"]]/nrow(type_b_sf))*100
#Percentage of the second most dominant genus (Spilopelia) =
(table(type_b_sf$genus)[["Spilopelia"]]/nrow(type_b_sf))*100

# See the top 10 species in terms of contribution
sorted_table <- sort(table(type_b_sf$sci_name), decreasing = TRUE)
head(sorted_table, 10)
#Percentage of the most dominant species (Psittacula) =
(table(type_b_sf$sci_name)[["Psittacula cyanocephala"]]/nrow(type_b_sf))*100
#Percentage of the second most dominant species (Spilopelia) =
(table(type_b_sf$sci_name)[["Oriolus xanthornus"]]/nrow(type_b_sf))*100

# To see the unique sci_name in type B data
unique(type_b_sf$sci_name)
# Count the number of unique sci_name in type B
length(unique(type_b_sf$sci_name))

# Count the unique number of species using the speciesKey
# and also check if this is accurate by checking if all the genera, families,
# and orders are represented from the larger data (ta)
species_b <- type_b_sf %>%
  st_drop_geometry() %>%
  distinct(`speciesKey`, .keep_all = TRUE) %>%
  select(speciesKey, sci_name, genus, family, order, class) %>%
  arrange(`sci_name`)

# Total number of species
length(unique(species_b$sci_name))
#[1] 348

# Check the actual names
unique(species_b$sci_name)
# So, the total number of species in Type B is 348 (assuming we haven't missed
# any species at genus level). One species at order level (Chiroptera). So, the species
# identified to the species level is 347.

length(unique(species_b$genus))
#[1] 203
length(unique(type_b_sf$genus))
#[1] 206

# It shows 3 additional genera in the larger dataset. Check what those 3 genera 
# are
setdiff(unique(type_b_sf$genus), unique(species_b$genus))
#[1] "Mecopoda"      "Semnopithecus" "Indirana"   

# These 3 species are new too.

# So, total number of species = 348+3 = 351

# Check any missing family in the unique data
length(unique(species_b$family))
#[1] 90
length(unique(type_b_sf$family))
#[1] 94

# So, there are 4 families missing, indicating potential 4 species more. Check
# them 
setdiff(unique(type_b_sf$family), unique(species_b$family))
#[1] "Cercopithecidae" "Gryllidae"       "Notonectidae"    "Ranixalidae"    

# Gryllidae and Notonectidae have not been covered by any genera without a speciesKey.

# So, 2 more species. 351+2 = 353

# Check any missing order in the unique data
length(unique(species_b$order))
#[1] 27
length(unique(type_b_sf$order))
#[1] 28

# So, there is one order missing, indicating 1 potential species more. Check
# it
setdiff(unique(type_b_sf$order), unique(species_b$order))
# [1] NA

# That's NA. So, 353 species in total for type B data

### Combined ####

# Combined number of species:
length(union(unique(species_a$sci_name), unique(species_b$sci_name)))
#507

# Check for excluded genera

#From Type A
# [1] "Dugong"   "Eumenes"  "Camera"   "Xylocopa" "Sterna"  
#From Type B
#[1] "Mecopoda"      "Semnopithecus" "Indirana"   

#Sterna aurantia is already present
# So, 7 unique species in addition.

# i.e. 507+7 = 514

# Check for excluded families

# From Type A
# [1] "Dugongidae"    "Gryllidae"     "Cicadidae"     NA              "Eumenidae"     "Vespidae"      "Oecanthidae"  
# [8] "Ichneumonidae" "Apidae"        "Laridae"       
# From Type B
#[1] "Cercopithecidae" "Gryllidae"       "Notonectidae"    "Ranixalidae" 

# Exclude NA. Oecanthidae could be a synonym for Gryllidae depending on the taxonomy.
# Only one can be considered as a unique species. So, 2 additional species.

# i.e. 514+2 = 516

# Check for excluded orders

# For Type A
# [1] "Sirenia"     "Orthoptera"  NA            "Trichoptera" "Hymenoptera" "Diptera" 
# For Type B
# [1] NA

# Only Trichoptera and Diptera are not covered by species, genus, or family stages

#So, 516+2 = 518 species in both Type A and Type B data combined
