/* Creates latex files with summary characteristics of the simulated data for the paper:
      - Table 1: Desciptives (averages  from  200  simulations) for the simulated datasets without screening and with screening assuming moderate screening 	
				 sensitivity andimperfect attendance
      - Table 2: Proportion  screen  detected, and mean and median lead-time (in  years) among screen detected cases in different simulation screening scenarios. All 
				numbers are averages (with 2.5 and 97.5 percentiles in parenthesis) based on 200 simulations
	  - Table S1: Proportion screen detected, among those with age of cancer detection between 40-74 (when cancer screening is offered), across different simulation 
				 screening scenarios. All numbers are averages (with 2.5 and 97.5 percentiles inparenthesis) based on 200 simulations

Need to run Descriptives.do first to produces descriptives0.dta and descriptives1.dta

First, set working directory to folder lead_time_bias
*/





// **************Table 1****************** //
use "dta/descriptives0.dta", clear

// fix labels for screening sensitivity
gen method2=1 if method==2
replace method2=2 if method==1
replace method2=3 if method==3
drop method
rename method2 method
label define methodlbl 0 "None" 1 "Low" 2 "Moderate" 3 "High"
label values method methodlbl

sort i method

// number diagnosed diagnosed 
// without screening
sum symptdet  
global symptdet= trim("`: di %6.0f r(mean)'")
// both symptomatic and via screening (only imperfect attendance and moderate sensitivity)
preserve
	keep if method==2 & imperfectAttendance==1
	sum totaldet
	global totaldet= trim("`: di %6.0f r(mean)'")
restore


// age at diagnosis
// without screening
sum agesym 
global agesym= trim("`: di %6.0f r(mean)'")
sum agesym_p25
global agesym_p25= trim("`: di %6.0f r(mean)'")
sum agesym_p75
global agesym_p75= trim("`: di %6.0f r(mean)'")
sum agesym_median
global agesym_median= trim("`: di %6.0f r(mean)'")
// both symptomatic and via screening (only imperfect attendance and moderate sensitivity)
preserve
	keep if method==2 & imperfectAttendance==1
	sum agescreen 
	global agescreen= trim("`: di %6.0f r(mean)'")
	sum agescreen_p25 
	global agescreen_p25= trim("`: di %6.0f r(mean)'")
	sum agescreen_p75 
	global agescreen_p75= trim("`: di %6.0f r(mean)'")
	sum agescreen_median
	global agescreen_median= trim("`: di %6.0f r(mean)'")
restore

// proportion died in the first 12 years
// without screening
replace prop_dead_sym=prop_dead_sym*100
sum prop_dead_sym 
global prop_dead_sym = trim("`: di %6.1f r(mean)'")
// both symptomatic and via screening (only imperfect attendance and moderate sensitivity)
preserve
	keep if method==2 & imperfectAttendance==1
	replace prop_dead_screen=prop_dead_screen*100
	sum prop_dead_screen 
	global prop_dead_screen = trim("`: di %6.1f r(mean)'")
restore


// proportion by tumour size
// without screening
forvalues i=1/4 {
	replace prop_sizesymp`i'=prop_sizesymp`i'*100
	sum prop_sizesymp`i' 
	global prop_sizesymp`i'= trim("`: di %6.1f r(mean)'")
}
// both symptomatic and via screening (only imperfect attendance and moderate sensitivity)
preserve
	keep if method==2 & imperfectAttendance==1
	forvalues i=1/4 {
		replace prop_sizedet`i'=prop_sizedet`i'*100
		sum prop_sizedet`i' 
		global prop_sizedet`i'= trim("`: di %6.1f r(mean)'")
	}
restore

// output: latex file descriptives_screeningVsnoscreening.tex  (Table 1 of the paper)
capture file close table
file open table using "tex/descriptives_screeningVsnoscreening.tex", write replace

file write table ///
	"\begin{table}" _newline ///
	"\centering" _newline ///
	"\caption{Desciptives (averages  from  200  simulations) for the simulated datasets without screening and with screening assuming moderate screening sensitivity and imperfect attendance}"  _newline ///
	"\label{tab:des}" _newline ///
	"\begin{threeparttable}" _newline ///
	"\scalebox{1} {" _newline ///
	"\begin{tabular}{ccc}" _newline ///
	"\toprule" _newline ///
	"& No screening & Screening    \\" _newline ///
	"\midrule" _newline

file write table ///
	"Number diagnosed &  $symptdet & $totaldet  \\" _newline ///
	"Mean age at diagnosis &  $agesym & $agescreen  \\" _newline ///
	"25th percentile of age &  $agesym_p25 & $agescreen_p25  \\" _newline ///
	"Median age &  $agesym_median & $agescreen_median  \\" _newline ///
	"75th percentile of age &  $agesym_p75 & $agescreen_p75  \\" _newline ///
	"\% dead within 12 years &  $prop_dead_sym & $prop_dead_screen  \\" _newline ///
	"\% size smaller than 17.5 &  $prop_sizesymp1 & $prop_sizedet1 \\" _newline ///
	"\% size 17.5--32.5 &  $prop_sizesymp2 & $prop_sizedet2 \\" _newline ///
	"\% size 32.5--47.5 &  $prop_sizesymp3 & $prop_sizedet3 \\" _newline ///
	"\% size larger than 47.5 &  $prop_sizesymp4 & $prop_sizedet4 \\" _newline ///

file write table ///
	"\bottomrule" _newline ///
	"\end{tabular}}" _newline ///
	"\end{threeparttable}" _newline ///
	"\end{table}" 

file close table    


// **************Table 2 and Table S1****************** //
// for Table 2
use "dta/descriptives0.dta", clear 
// for Table S1 among ages 40-74 the are invited for screening use the following dataset instead
// use "dta/descriptives1.dta", clear

// fix labels for screening sensitivity
gen method2=1 if method==2
replace method2=2 if method==1
replace method2=3 if method==3
drop method
rename method2 method
label define methodlbl 0 "None" 1 "Low" 2 "Moderate" 3 "High"
label values method methodlbl


sort i method
replace prop_screendet=prop_screendet*100

// for screening attendance scenarios
forvalues p=0/1 {
	// for screening sensitivity attendance
	forvalues m=1/3 {
		// number detected
		sum totaldet if imperfectAttendance==`p' & method==`m' 
		ereturn li
		local totaldet_m`m'_p`p'= trim("`: di %6.0f r(mean)'")
		centile totaldet if imperfectAttendance==`p' & method==`m', centile(2.5 97.5)
		local totaldet_m`m'_p`p'_p25= trim("`: di %6.0f r(c_1)'")
		local totaldet_m`m'_p`p'_p75= trim("`: di %6.0f r(c_2)'")
		// proportion screen detected
		sum prop_screendet if imperfectAttendance==`p' & method==`m'
		local prop_screendet_m`m'_p`p'= trim("`: di %6.1f r(mean)'")
		centile prop_screendet if imperfectAttendance==`p' & method==`m', centile(2.5 97.5)
		local prop_screendet_m`m'_p`p'_p25= trim("`: di %6.1f r(c_1)'")	
		local prop_screendet_m`m'_p`p'_p75= trim("`: di %6.1f r(c_2)'")
		// mean lead time bias
		sum ltb_mean if imperfectAttendance==`p' &  method==`m'
		local ltb_mean_m`m'_p`p'= trim("`: di %6.2f r(mean)'")	
		centile ltb_mean if imperfectAttendance==`p' & method==`m', centile(2.5 97.5)
		local ltb_mean_m`m'_p`p'_p25= trim("`: di %6.2f r(c_1)'")	
		local ltb_mean_m`m'_p`p'_p75= trim("`: di %6.2f r(c_2)'")	
		// median lead time bias
		sum ltb_median if imperfectAttendance==`p' &  method==`m'
		local ltb_median_m`m'_p`p'= trim("`: di %6.2f r(mean)'")	
		centile ltb_median if imperfectAttendance==`p' & method==`m', centile(2.5 97.5)
		local ltb_median_m`m'_p`p'_p25= trim("`: di %6.2f r(c_1)'")
		local ltb_median_m`m'_p`p'_p75= trim("`: di %6.2f r(c_2)'")			
	}
} 




// output: latex file descriptives_screening.tex  (Table 2 of the paper)
capture file close table
file open table using "tex/descriptives_screening.tex", write replace

file write table ///
	"\begin{table}[h]" _newline ///
	"\centering" _newline ///
	"\caption{Proportion screen detected, and mean and median lead-time (in years) among screen detected cases in different simulation screening scenarios. All numbers are averages (with 2.5 and 97.5 percentiles in parenthesis) based on 200 simulations.}" _newline ///
	"\label{tab:screenn}" _newline ///
	"\begin{threeparttable}" _newline ///
	"\scalebox{0.9} {" _newline ///
	"\begin{tabular}{cccccc}" _newline ///
	"\toprule" _newline ///
	"Attendance & Screening & Number diagnosed & \% screen detected & Lead time (mean) & Lead time (median)  \\" _newline ///
	"\midrule" _newline
forvalues p=0/1  {
 forvalues m=1/3  {
	if (`p' == 0) {
		local p2 = "Perfect"
	}
	else {
		local p2 = "Imperfect"
	}
	if (`m' == 1) {
		local m2 = "Low"
	}
	if (`m' == 2) {
		local m2 = "Moderate"
	}
	if (`m' == 3) {
		local m2 = "High"
	}
	file write table ///
		"`p2' & `m2' & `totaldet_m`m'_p`p'' (`totaldet_m`m'_p`p'_p25' -- `totaldet_m`m'_p`p'_p75') & `prop_screendet_m`m'_p`p'' (`prop_screendet_m`m'_p`p'_p25' -- `prop_screendet_m`m'_p`p'_p75') & `ltb_mean_m`m'_p`p'' (`ltb_mean_m`m'_p`p'_p25' -- `ltb_mean_m`m'_p`p'_p75') & `ltb_median_m`m'_p`p'' (`ltb_median_m`m'_p`p'_p25' -- `ltb_median_m`m'_p`p'_p75') \\" _newline ///

 }
}
file write table ///
	"\bottomrule" _newline ///
	"\end{tabular}}" _newline ///
	"\end{threeparttable}" _newline ///
	"\end{table}" 

file close table  





