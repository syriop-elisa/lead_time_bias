//Obtain estimates of externally age-standardised 10-year relative survival, loss in life expectancy (LLE) and proportion of life lost (PLL)
// First, set working directory to folder lead_time_bias

local nsim 200

capture program drop CIsim
program define CIsim, rclass
	syntax, [  i(integer 2) ///	
	           p(integer 0) ///
		       v(integer 1) ///	  
		]

	use "dta/simdata_wide_`i'.dta", clear
	
	// for NO screening 
	if `v'==0 {
		//age of detection without screening
		gen agedet=agesymp
		//year of detection without screening
		gen yeardet= yearsymp
	}
	
	// for screening with different sensitivity scenarios
	if `v'==1 | `v'==2 |`v'==3 {
	
		if `p'==0 {
			//For perfect attendance
			gen agedet=agedet_`v'_perfect
			gen yeardet= yeardet_`v'_perfect
		}
		
		if `p'==1 {
			//For imperfect attendance
			gen agedet=agedet_`v'_imperfect
			gen yeardet= yeardet_`v'_imperfect
		}
		
	}
	
	// age at death as the minumum of age to death due to other causes and breast cancer
	gen agedeath=min(timeother, timebc)

	// generate survival time as the difference between age at death and age at detection
	gen survtime= agedeath-agedet
	// censored if still alive after 12 years since diagnosis
	replace survtime=12 if survtime>12

	// status
	gen status=1 if timeother>=timebc //dead due to breast cancer
	replace status = 2 if timeother<timebc //dead due to other causes
	replace status=0 if survtime==12 //alive if survived more than 12 years

	// declare surviva data
	stset survtime, failure(status=1,2) 
	keep if _st==1

	// keep years 1970-1974 as with the Swedish registry data
	keep if yeardet>=1970 & yeardet<=1974
	
	// merge expected mortality rates
	gen sex=2 //females
	gen _age = min(int(agedet + _t),99)
	gen _year = int(yeardet + _t)
	merge m:1 sex _year _age using "dta/popmort_projection.dta", keep(matched master)

	// generate age groups for external weights
	recode agedet (min/44.99999999=1) (45/54.999999999=2) (55/64.99999999=3) (65/74.99999999=4) (75/max=5), gen(ageICSS)	
	recode ageICSS (1=0.07) (2=0.12) (3=0.23) (4=0.29) (5=0.29), gen(ICSSwt)
	local total = _N
	bysort ageICSS:gen a_age = _N/`total'
	gen w = ICSSwt/a_age

	// fit relative survival model
	stpm2 agedet, df(3) tvc(agedet) dftvc(3) bhaz(rate) scale(h) 
	estimates store surv

	// estimates for 10-year relative survival
	gen t10=10
	standsurv, at1(.) timevar(t10) atvar(relsurv) indweights(w)
	sum relsurv if t10==10
	global relsurv=r(mean)
	
	//estimates for loss in life expectancy using option rmst
	gen t90 = 90 in 1
	replace agedet=int(agedet)
	standsurv, at1(.) atvar(S_rmst) timevar(t90) ci  rmst indweights(w) ///
		expsurv(using("dta/popmort_projection.dta")  ///
		datediag(yeardet)               ///
		agediag(agedet)               ///
		pmrate(rate)			   ///
		pmage(_age)				   ///
		pmyear(_year)              ///
		pmother(sex)			   ///
		pmmaxyear(2070)			   ///
		expsurvvar(es))	

	// the expsurvvar() option has saved the marginal expected survival
	// we can calculate the LLE as the difference between expected and observed life expectancy
	gen lle = es - S_rmst in 1 
	sum lle
	global lle=`r(mean)'	

	//estimates for proportion of life lost 
	gen pll=lle/es in 1
	list es lle pll in 1
	sum pll
	global pll=`r(mean)'
	di "$pll"


	ereturn clear
end


//store estimates
tempname estimates 
postfile `estimates' i attendance method relsurv10 lle pll using "dta/estimates.dta", replace


quietly{
	noi _dots 0, title("Simulation running...")
	profiler on
	forval i = 1/`nsim' {
	  forval p = 0/1 {
			forval v = 0/3 {

				CIsim, i(`i') p(`p') v(`v')

				post `estimates' (`i') (`p') (`v') ($relsurv)  ($lle) ($pll)


			}

		}
		
		noi _dots `i' 0
		profiler off
	}

postclose `estimates'

	

}








