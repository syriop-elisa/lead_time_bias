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
* [`simulate-fpm.R`](https://github.com/syriop-elisa/lead_time_bias/blob/main/simulation/simulate-fpm.R): define function logcumhaz for fitting flexible parametric survival model for death from breast cancer based on registry data in Sweden         
* [`screening.R`](https://github.com/syriop-elisa/lead_time_bias/blob/main/simulation/screening.R): impose screening scenarios with different sensitivity and attendance

The above files will return 200 simulates datasets, each called `simdata_maxt30_wide_i.dta` with i taking values 1 to 200. 
These files are omitted from the repository as they are too large but an example of those is given under [`simdata_maxt30_wide_1.dta`](https://github.com/syriop-elisa/lead_time_bias/blob/main/dta/simdata_maxt30_wide_1.dta)

After creating the simulated datasets, estimates of interest (i.e. externally age-standardised 10-year relative survival, LLE and PLL) are obtained in Stata using file [`obtain_estimates.do`](https://github.com/syriop-elisa/lead_time_bias/blob/main/analysis/obtain_estimates.do)
The output of this file called [`Estimatesmaxt30.dta`](https://github.com/syriop-elisa/lead_time_bias/blob/main/dta/Estimatesmaxt30.dta) includes the estimates of interest across screening sensitivity and screening attendance scenarios for all simulated dataset. 