// Prepare data for a summary of the characteristics of the simulated dataset by screening sensitivity scenario (v=1/3) and both for perfect (a=0) and imperfect visit attendance (a=1)
// Creates file descriptives0.dta for the whole age population 
// Creates file descriptives1.dta that restricts descriptives to screening ages 40-74. To produce this, there is ***local subset 1*** in two locations!
// Use Summarise_descriptives.do to produce a latex table  (Table 1, Table 2, Table S1)

// First, set working directory to folder lead_time_bias

local nsim 200
// store local subset=1 if interested in the subset of screening ages 40-74 
// store local subset=0 for the whole age population
local subset 0 

capture program drop CIsim
program define CIsim, rclass
	syntax, [ i(integer 1) ///	
			  p(integer 0) ///	
			  v(integer 1) ///	  
		]

	use "dta/simdata_wide_`i'.dta", clear
	
	// fix local a for attendance scenarios to match variable names
	if `p'==0 {
	     
	     local a perfect 
	 }
		 
	 if `p'==1 {
	     
	     local a imperfect 
	 }

	// store local subset=1 if interested in the subset of screening ages 40-74 
	// store local subset=0 for the whole age population
	local subset 0   

 
	// ****First for symptomatic detections**** //
	preserve
	keep if yearsymp>=1970 & yearsymp<=1974
	// age at death as the minimum of age at death from other causes and age at death due to breast cancer
	gen agedeath=min(timeother, timebc)
	// generate survival time as the difference between age at death and age at detection
	gen survtime= agedeath-agesymp
	// censored if still alive after 12 years since diagnosis
	replace survtime=12 if survtime>12
	//status
	gen status=1 if timeother>=timebc //dead due to breast cancer
	replace status = 2 if timeother<timebc //dead due to other causes
	replace status=0 if survtime==12 //alive if survived more than 12 years
	// declare surviva data
	stset survtime, failure(status=1,2) 
	keep if _st==1
	
	// store number diagnoses without screening
	count 
	global symptdet= `r(N)'
	
	// store age at diagnosis (mean, 25th percentile, 75th percentile, median)
	sum agesym, d
	global agesym= `r(mean)' 
	global agesym_p25=`r(p25)'
	global agesym_p75=`r(p75)'
	global agesym_median=`r(p50)'
	
	// store proportion dead within the first 12 years
	count if status==1 | status==2
	global dead_sym= `r(N)'
	global prop_dead_sym=$dead_sym/$symptdet
	
	// proportion by tumour size
	recode sizesymp (min/17.49999999=1) (17.5/32.49999999=2) (32.5/47.49999999=3) (47.5/max=4), gen(sizesymp_grp)
	count if sizesymp_grp==1
	global sizesymp1=`r(N)'
	global prop_sizesymp1=$sizesymp1/$symptdet
	count if sizesymp_grp==2
	global sizesymp2=`r(N)'
	global prop_sizesymp2=$sizesymp2/$symptdet
	count if sizesymp_grp==3
	global sizesymp3=`r(N)'
	global prop_sizesymp3=$sizesymp3/$symptdet
	count if sizesymp_grp==4
	global sizesymp4=`r(N)'
	global prop_sizesymp4=$sizesymp4/$symptdet
	
	
	restore
	

	//****Now for screening detections****//
	
		preserve
		keep if yeardet_`v'_`a'>=1970 & yeardet_`v'_`a'<=1974
		// age at death
		gen agedeath=min(timeother, timebc)
		// generate survival time as the difference between age at death and age at detection
		gen survtime= agedeath-agedet_`v'_`a'
		// censored if still alive after 12 years since diagnosis
		replace survtime=12 if survtime>12
		// status
		gen status=1 if timeother>=timebc //dead due to breast cancer
		replace status = 2 if timeother<timebc //dead due to other causes
		replace status=0 if survtime==12 //alive if survived more than 12 years
		// declare surviva data
		stset survtime, failure(status=1,2) 
		keep if _st==1


		// store number of diagnoses (both symptomatic & via screening)
		if `subset'==1 {
		    
		 keep if agedet_`v'_`a'>=40 & agedet_`v'_`a'<=74
		 
		 }
		 
		count 
		global totaldet= `r(N)'

		// store average age at diagnosis in the presence of screening
		sum agedet_`v'_`a',d
		global agescreen= `r(mean)' 
		global agescreen_p25=`r(p25)'
		global agescreen_p75=`r(p75)'
		global agescreen_median=`r(p50)'

		// store proportion dead within the first 12 months
		count if status==1 | status==2
		global dead_screen= `r(N)'
		global prop_dead_screen=$dead_screen/$totaldet

		// store proportion by tumour size
		recode sizedet_`v'_perfect (min/17.49999999=1) (17.5/32.49999999=2) (32.5/47.49999999=3) (47.5/max=4), gen(sizedet_grp)
		count if sizedet_grp==1
		global sizedet1=`r(N)'
		global prop_sizedet1=$sizedet1/$totaldet
		count if sizedet_grp==2
		global sizedet2=`r(N)'
		global prop_sizedet2=$sizedet2/$totaldet
		count if sizedet_grp==3
		global sizedet3=`r(N)'
		global prop_sizedet3=$sizedet3/$totaldet
		count if sizedet_grp==4
		global sizedet4=`r(N)'
		global prop_sizedet4=$sizedet4/$totaldet

		
		// additional information required for Table 2 and Table S1
		// store proportion screen detected
		count if diamam_`v'_`a'==3
		global screendet= `r(N)'
		global prop_screendet=$screendet/$totaldet

		// store mean lead time bias
		gen ltb=agesym-agedet_`v'_`a'
		sum ltb if diamam_`v'_`a'==3,d
		global ltb_mean= `r(mean)' 
		global ltb_median= `r(p50)' 
		restore
	
	

	ereturn clear
end



// store estimates
tempname estimates 
postfile `estimates' i imperfectAttendance method symptdet totaldet ///
					agesym agescreen  agesym_p25 agescreen_p25  agesym_p75 agescreen_p75  agesym_median agescreen_median ///
					prop_dead_sym prop_dead_screen ///
					prop_sizesymp1 prop_sizesymp2 prop_sizesymp3 prop_sizesymp4 ///
					prop_sizedet1 prop_sizedet2 prop_sizedet3 prop_sizedet4 ///
					prop_screendet ///
					ltb_mean ltb_median using "dta/descriptives`subset'.dta", replace



quietly{
	noi _dots 0, title("Store data...")
	profiler on
	forval i = 1/`nsim' {
	  forval p = 0/1 {
			forval v = 1/3 {
				
				CIsim, i(`i') p(`p') v(`v')

				post `estimates' (`i') (`p') (`v') ($symptdet)  ($totaldet)  ///
								($agesym) ($agescreen) ($agesym_p25) ($agescreen_p25)  ($agesym_p75) ($agescreen_p75)  ($agesym_median) ($agescreen_median) ///
								($prop_dead_sym) ($prop_dead_screen) ///
								($prop_sizesymp1) ($prop_sizesymp2) ($prop_sizesymp3) ($prop_sizesymp4) ///
								($prop_sizedet1) ($prop_sizedet2) ($prop_sizedet3) ($prop_sizedet4) ///
								($prop_screendet) ///
								($ltb_mean) ($ltb_median)
			}

		}
		noi _dots `i' 0
		profiler off

	}

	postclose `estimates'

}




