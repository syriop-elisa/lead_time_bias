/* 
Code to create latex tables for the paper: 1. Table 3 - Estimates of externally age-standardised 10-year relative survival (RS) in percentages, loss in  			
											life expectancy(LLE) in years and proportion of life lost (PLL) in percentages in the absence of screening as well as in 
											the presence of screening across different screening sensitivities and attendance scenarios.  All numbers are averages ]
											(with 2.5 and 97.5 percentiles in parenthesis) based on 200 simulations.
										   2. Table S3 - Average relative bias for externally age-standardised 10-year relative survival (RS), loss in life 
											expectancy(LLE) and proportion of life lost (PLL) across different screening sensitivities and attendance scenarios, 
											with 2.5 and 97.5 percentiles based on 200 simulations. The reference scenario is the setting in which no screening is 
											imposed andall cases are symptomatic.

First, set working directory to folder lead_time_bias
*/


use "dta/estimates.dta" , clear


reshape wide relsurv10 lle pll , i(i attendance) j(method)

forvalues w = 0/3 {
	gen relsurv10p`w' = (relsurv10`w' - relsurv100) / relsurv100
	gen llep`w' = (lle`w' - lle0) / lle0
	gen pllp`w' = (pll`w' - pll0) / pll0
}

reshape long relsurv10p llep pllp relsurv10 lle pll, i(i attendance) j(method)

//fix tables for screening scenario (0 for no screening, 1 low screening sensitivity, 2 moderate screening sensitivity, 3 high screening sensitivity)
gen method2=0 if method==0
replace method2=1 if method==2
replace method2=2 if method==1
replace method2=3 if method==3
drop method
rename method2 method

label define methodlbl 0 "None" 1 "Low" 2 "Moderate" 3 "High"
label values method methodlbl


// format
replace relsurv10 = relsurv10*100
replace relsurv10p = relsurv10p*100
replace llep = llep*100
replace pll = pll*100
replace pllp = pllp*100


// store mean and percentiles
// for each attendance scenario (p)
forval p=0/1 {
	// for each screening scenario (method)
	forvalues method=0/3 {
		// point estimates
		sum relsurv10 if method==`method' & attendance==`p'
		local relsurv10_`method'_p`p' = trim("`: di %6.2f r(mean)'")
		centile relsurv10 if method==`method' & attendance==`p', centile(2.5 97.5)
		local rs_per25_`method'_p`p' = trim("`: di %6.2f r(c_1)'")
		local rs_per75_`method'_p`p' = trim("`: di %6.2f r(c_2)'")

		sum lle if method==`method' & attendance==`p'
		local lle_`method'_p`p' = trim("`: di %6.2f r(mean)'")
		centile lle if method==`method' & attendance==`p', centile(2.5 97.5)
		local lle_per25_`method'_p`p' = trim("`: di %6.2f  r(c_1)'")
		local lle_per75_`method'_p`p' = trim("`: di %6.2f  r(c_2)'")

		sum pll if method==`method' & attendance==`p'
		local pll_`method'_p`p' = trim("`: di %6.2f r(mean)'")
		centile pll if method==`method' & attendance==`p', centile(2.5 97.5)
		local pll_per25_`method'_p`p' = trim("`: di %6.2f  r(c_1)'")
		local pll_per75_`method'_p`p' = trim("`: di %6.2f  r(c_2)'")

		// relative bias
		sum relsurv10p if method==`method' & attendance==`p'
		local relsurv10_rbias_`method'_p`p' = trim("`: di %6.2f r(mean)'")
		centile relsurv10p if method==`method' & attendance==`p', centile(2.5 97.5)
		local rs_rbias_per25_`method'_p`p' = trim("`: di %6.2f  r(c_1)'")
		local rs_rbias_per75_`method'_p`p' = trim("`: di %6.2f  r(c_2)'")

		sum llep if method==`method' & attendance==`p'
		local lle_rbias_`method'_p`p' = trim("`: di %6.2f r(mean)'")
		centile llep if method==`method' & attendance==`p', centile(2.5 97.5)
		local lle_rbias_per25_`method'_p`p' = trim("`: di %6.2f  r(c_1)'")
		local lle_rbias_per75_`method'_p`p' = trim("`: di %6.2f  r(c_2)'")

		sum pllp if method==`method' & attendance==`p'
		local pll_rbias_`method'_p`p' = trim("`: di %6.2f r(mean)'")
		centile pllp if method==`method' & attendance==`p', centile(2.5 97.5)
		local pll_rbias_per25_`method'_p`p' = trim("`: di %6.2f  r(c_1)'")
		local pll_rbias_per75_`method'_p`p' = trim("`: di %6.2f  r(c_2)'")
		
	}
}



label variable method "Screening"
label variable relsurv10 "10-year RS"
label variable lle "LLE"
label variable pll "Proportion lost"
label variable relsurv10p "10-year RS"
label variable llep "LLE"
label variable pllp "Proportion lost"




//***********Table 3 with point estimates and 2.5 and 97.5 percentiles**************// 
//// Table is stored in folder tex with the name tab_averages.tex

capture file close table
file open table using "tex/tab_averages.tex", write replace

file write table ///
	"\begin{tabular}{ccccc}" _newline ///
	"\toprule{}" _newline ///
	"Attendance & Screening & 10-Year RS & LLE & PLL   \\" _newline ///
	"\midrule{}" _newline
		file write table ///
" --- & None &  `relsurv10_0_p0' (`rs_per25_0_p0' -- `rs_per75_0_p0') & `lle_0_p0' (`lle_per25_0_p0' -- `lle_per75_0_p0') & `pll_0_p0' (`pll_per25_0_p0' -- `pll_per75_0_p0')  \\" _newline ///

forval p=0/1{
	forvalues method=1/3  {
		if (`p' == 0) {
			local p2 = "Perfect"
		}
		else {
			local p2 = "Imperfect"
		}
		if (`method' == 0) {
			local m2 = "None"
		}
		if (`method' == 1) {
			local m2 = "Low"
		}
		if (`method' == 2) {
			local m2 = "Moderate"
		}
		if (`method' == 3) {
			local m2 = "High"
		}
		file write table ///
		"`p2' & `m2' &  `relsurv10_`method'_p`p'' (`rs_per25_`method'_p`p'' -- `rs_per75_`method'_p`p'') & `lle_`method'_p`p'' (`lle_per25_`method'_p`p'' -- `lle_per75_`method'_p`p'') & `pll_`method'_p`p'' (`pll_per25_`method'_p`p'' -- `pll_per75_`method'_p`p'')  \\" _newline ///

	}
}

file write table ///
	"\bottomrule{}" _newline ///
	"\end{tabular}"
	
file close table



//***********Table S3 with relative bias and 2.5 and 97.5 percentiles**************// 
// Table is stored in folder tex with the name tab_relative_bias.tex 

capture file close table
file open table using "tex/tab_relative_bias.tex", write replace

file write table ///
	"\begin{tabular}{ccccc}" _newline ///
	"\toprule{}" _newline ///
	"Attendance & Screening &  10-Year RS & LLE & PLL \\" _newline ///
	"\midrule{}" _newline
	file write table ///
	" --- & None (reference) & --- & --- & --- \\" _newline ///

forval p=0/1{
	forvalues method=1/3  {
		if (`p' == 0) {
			local p2 = "Perfect"
		}
		else {
			local p2 = "Imperfect"
		}
		if (`method' == 0) {
			local m2 = "None"
		}
		if (`method' == 1) {
			local m2 = "Low"
		}
		if (`method' == 2) {
			local m2 = "Moderate"
		}
		if (`method' == 3) {
			local m2 = "High"
		}
		file write table ///
		"`p2' & `m2' &  `relsurv10_rbias_`method'_p`p'' (`rs_rbias_per25_`method'_p`p'' -- `rs_rbias_per75_`method'_p`p'') & `lle_rbias_`method'_p`p'' (`lle_rbias_per25_`method'_p`p'' -- `lle_rbias_per75_`method'_p`p'') & `pll_rbias_`method'_p`p'' (`pll_rbias_per25_`method'_p`p'' -- `pll_rbias_per75_`method'_p`p'')  \\" _newline ///

	}
}

file write table ///
	"\bottomrule{}" _newline ///
	"\end{tabular}"
	
file close table

