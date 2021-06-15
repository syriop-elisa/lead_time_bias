// Run this file once after having simulated all datasets, reduces size of each dataset by ~30%
// First, set working directory to folder lead_time_bias

local nsim 200
forvalues i = 1/`nsim' {
	capture use "dta/simdata_wide_`i'.dta"
	if (_rc == 0) {
		compress
		save, replace
	}
}
