# Assessing Lead Time Bias Due to Mammography Screening on Estimates of Loss in Life Expectancy

This repository contains the code required for the simulation-based approach of the manuscript titled Assessing lead time bias due to mammography screening on estimates of loss in life expectancy by Syriopoulou et al. (2021).

In this paper we assessed the impact of lead time bias, which, for breast cancer, is introduced in the presence of mammography screening, on the estimation of loss in life expectancy metrics using a simulation-based approach.
Our simulation-based approach was informed by Swedish cancer registry data and uses a natural history model developed in a Swedish setting.
Different scenarios were assumed for screening sensitivity (low, moderate, high) as well as screening attendance to allow for settings where individuals may attend some visits but miss others.
Estimates of 10-year relative survival, loss in life expectanct (LLE) and proportion of life lost (PLL) in the absence of screening were compared with estimates when screening was imposed to obtain the lead time bias. 

A file has be created for the project under [`lead_time_bias.Rproj`](https://github.com/syriop-elisa/lead_time_bias/blob/main/-ead_time_bias.Rproj).
The code for simulating the data is available in the folder [`simulation`](https://github.com/syriop-elisa/lead_time_bias/tree/main/simulation) that includes the following files:

* [`simulation-script.R`](https://github.com/syriop-elisa/lead_time_bias/blob/main/simulation/simulation-script.R): main file with parameters values
* [`natural-history-model.R`](https://github.com/syriop-elisa/lead_time_bias/blob/main/simulation/natural-history-model.R): simulate tumour growth and age at symptomatic detection in the absence of screening
* [`simulate-fpm.R`](https://github.com/syriop-elisa/lead_time_bias/blob/main/simulation/simulate-fpm.R): define function `logcumhaz` for fitting flexible parametric survival model for death from breast cancer based on registry data in Sweden         
* [`screening.R`](https://github.com/syriop-elisa/lead_time_bias/blob/main/simulation/screening.R): impose screening scenarios with different sensitivity and attendance

The above files will return 200 simulates datasets, each called `simdata_maxt30_wide_i.dta` with i taking values 1 to 200. 
These files are omitted from the repository as they are too large but an example of the first simulated dataset is given under [`simdata_wide_1.dta`](https://github.com/syriop-elisa/lead_time_bias/blob/main/dta/simdata_wide_1.dta)

Files of Stata code for the analyses of the simulated data are available in folder [`analysis`](https://github.com/syriop-elisa/lead_time_bias/blob/main/analysis):
* [`compress_simulated_data.do`](https://github.com/syriop-elisa/lead_time_bias/blob/main/analysis/compress_simulated_data.do): reduces size of each dataset by ~30% after having simulated all datasets
* [`obtain_estimates.do`](https://github.com/syriop-elisa/lead_time_bias/blob/main/analysis/obtain_estimates.do): obtain estimates of interest (i.e. externally age-standardised 10-year relative survival, LLE and PLL).
The output of this file is called [`estimates.dta`](https://github.com/syriop-elisa/lead_time_bias/blob/main/dta/estimates.dta) and includes the estimates of interest across screening sensitivity and screening attendance scenarios for all simulated dataset. 

For the analysis, we use some user-written Stata commands.
These can be installed within Stata from the Boston College Statistical Software Components (SSC) archive as described below. 

To install the function required for fitting flexible parametric survival models (FPMs) type:  
* `ssc install stpm2`

To install the function required for generating the restricted cubic spline functions that are required for the FPMs type:
* `ssc install rcsgen`

The `standsurv` command is used to obtain marginal estimates using regression standardisation and it can be installed by running:

`net from https://www.pclambert.net/downloads/standsurv`

Finally, the population lifetable required for obtaining the estimates of interest is available in the file [`popmort_projection.dta`](https://github.com/syriop-elisa/lead_time_bias/blob/main/dta/popmort_projection.dta)


Files to summarise the results can be found in the folder [`summary`](https://github.com/syriop-elisa/lead_time_bias/blob/main/summary):
* [`data_preparation.do`](https://github.com/syriop-elisa/lead_time_bias/blob/main/summary/data_preparation.do): this file prepared data before creating Tables 1, 2, S1 of the paper. Output files: [`descriptives0.dta`](https://github.com/syriop-elisa/lead_time_bias/blob/main/dta/descriptives0.dta) and [`descriptives1.dta`](https://github.com/syriop-elisa/lead_time_bias/blob/main/dta/descriptives1.dta)
* [`table1_table2_tableS1.do`](https://github.com/syriop-elisa/lead_time_bias/blob/main/summary/table1_table2_tableS1.do): produces tables with summary characteristics of the simulated data (Table 1, Table 2 and Table S1 of the paper)
* [`table3_tableS3.do`](https://github.com/syriop-elisa/lead_time_bias/blob/main/summary/table3_tableS3.do): produces tables for the average estimates over 200 simulations and the relative bias (Table 3 and Table S3 of the paper)
* [`table_S2.R`](https://github.com/syriop-elisa/lead_time_bias/blob/main/summary/table_S2.R): creates a table for the bias with 95\% confidence intervals based on Monte Carlo errors (Table S2 of the paper)
* [`plots.R`](https://github.com/syriop-elisa/lead_time_bias/blob/main/summary/plots.R): produces figures for the bias and relative bias (Figure 1 and 2 of the paper, respectively)