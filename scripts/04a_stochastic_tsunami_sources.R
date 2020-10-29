#
# Combine unit source tsunami initial conditions to make tsunami initial
# conditions for earthquake events.
#
# Here we illustrate stochastic slip, using the S_{NCF} method from:
# Davies et al (2015) Tsunami inundation from heterogeneous earthquake
# slip distributions: Evaluation of synthetic source models. JGR,
# doi:10.1002/2015JB012272
#
# With slight modifications, this code can also generate uniforms slip events
#
#
# Note this code requires that the tutorial in ../source_contours_2_unit_sources
# has been successfully run.
#
# Modified by Ryan (27/10/2020) just to prepare stochastic scenarios then export
# it to csv files

library(rptha)

## Input parameters ##

# Folder containing one directory for each sourcename. Inside the latter
# directories are tif files for each unit source (and no other tif files)
unit_source_dirname = '../outputs/Unit_source_data'

# sourcename. This should be the name of a directory inside unit_source_dirname,
# and also the name of a discretised_source (among those contained in 
# all_discretized_source_RDS)
sourcename = 'MksThrust_Central_contours'

# RSD filename containing all discretized source information.
# The object therein should include a list entry corresponding to sourcename
all_discretized_source_RDS = '../outputs/all_discretized_sources.RDS'

# Earthquake parameters
desired_Mw = 7.7
target_location = c(118.61, -2.21) ## Approximate Lon, Lat of rupture (will stochastically vary)
number_of_sffm = 100 ## How many stochastic events to make

## end input ##

discretized_source = readRDS(all_discretized_source_RDS)[[sourcename]]
discretized_source_statistics = 
  discretized_source_approximate_summary_statistics(discretized_source)

# subfaults configuration ...
subfaultconfig = '../stochastic/subfaults_'
write.csv(discretized_source_statistics,paste0(subfaultconfig,sourcename,'.csv'))

# Read the raster corresponding to each row in the discretized_source_statistics
unit_source_raster_files = paste(unit_source_dirname, '/', sourcename, '/', 
    sourcename, '_', discretized_source_statistics$downdip_number, '_',
    discretized_source_statistics$alongstrike_number, '.tif', sep="")

if(!(all(file.exists(unit_source_raster_files)))){
    stop('Could not find some unit source raster files')
}

unit_source_rasters = lapply(as.list(unit_source_raster_files), f<-function(x) raster(x))


# Create the stochastic slip events
stochastic_slip_events = sffm_make_events_on_discretized_source(
	discretized_source_statistics = discretized_source_statistics,
	target_location = target_location,
	target_event_mw = desired_Mw,
	num_events = number_of_sffm,
	vary_peak_slip_location = TRUE,
	sourcename = sourcename,
	uniform_slip = FALSE,
	expand_length_if_width_limited = 'random',
	use_deterministic_LWkc = FALSE,
	clip_random_parameters_at_2sd = TRUE,
	relation = 'Strasser',
	peak_slip_location_near_centre = FALSE)

# Store as table
stochastic_slip_events_table = sffm_events_to_table(stochastic_slip_events)

# Save stochastic events to csv
for (i in 1:length(stochastic_slip_events)){
	slip = stochastic_slip_events[[i]][1]
	fout = paste0('../stochastic/',sourcename,'_Mw',desired_Mw)
	write.csv(slip,paste0(fout,'_Scenarios_',i,'.csv'),row.names=FALSE)
}

#dev.off()