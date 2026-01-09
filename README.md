This repository consists of a list of scripts to calculate the _Environment90m_ dataset.

Environment90m dataset aggregates a large number of environmental layers into each 
of the 726 million sub-catchments of the _Hydrography90m_ dataset (Amatulli, et al 2022).
It includes 45 variables related to topography and hydrography, 
19 climate variables for the observation period of 1981-2010, 
as well as projections for 2041-2070 and 2071-2100 under the 
Shared Socioeconomic Pathways (SSPs) 1.26, 3.70 and 5.85, 
and three global circulation models (UKESM, MPI and IPSL). 
Moreover, _Environment90m_ includes 22 land cover categories for the annual time-series data from 1992-2020.
In addition, we provide 15 soil variables and information on aridity and modelled streamflow. 
Summary statistics  (i.e., mean, min, max, range, sd) are provided for all continuous variables 
while for categorical data, the proportion of each category is calculated within each of the sub-catchments. 
The data is available at https://hydrography.org/environment90m 

The calculations consisted of two main steps:

1. Run the agregation statistics for all target variables to each of the regional units defined in Amatulli, et al 2022.
   As a result of the aggregation tables were obtained for each variable and for each regional unit with the list of sub-catchment IDs
   and the corresponding statistics.

   The first group of scripts (sc2*) relate to this procedure
   
3. Transpose the original tables to follow the same tiling scheme as in the _Hydrography90m_ dataset, and make both datasets compatible

   The second group of scripts (sc3*) are related to this procedure

All calculations were processed in parallel using the High Performance Computing (HPC) facility at Yale University.
    
Amatulli, G., Garcia Marquez, J., Sethi, T., Kiesel, J., Grigoropoulou, A., Üblacker, M. M., Shen, L. Q., and Domisch, S.: Hydrography90m:
A new high-resolution global hydrographic dataset, Earth System Science Data, 14, 4525–4550, 2022.
