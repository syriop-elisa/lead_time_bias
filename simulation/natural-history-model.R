## Generation of the disease in the population and when the clinical
## detection would occur in the absence of a screening program

natural_history_data <- function(pstarti, obs, tau1, tau2, d0, gam, popmort, year1, year2, bycohort, mybeta, cov, myknots, mult) {
  # no.obs.,screening ages, tau, gamma, sensitivity

  # NEED TO GENERATE AGE AT ONSET
  # ONSET CAN HAPPEN BETWEEN AGE 10 AND 99
  start <- c(10:99, NA)
  pstart <- 1 - exp(-pstarti)
  risk <- sum(pstart) * mult
  norisk <- 1 - risk
  pstart <- risk * pstart / sum(pstart)
  ppstart <- c(pstart, norisk)

  # simulate birth cohorts
  bornyear <- rep(seq(year1, year2, bycohort), obs)
  totobs <- length(bornyear)
  # output:
  # bornyear=year of birth
  # simulating 'obs' births into the population every year, from 'year1' to 'year2'

  atumon <- sample(x = start, size = totobs, replace = TRUE, prob = ppstart) ## sample of onsettimes
  # output:
  # atumon=age at start of tumour growth

  # Only keep if having onset
  index <- which(!is.na(atumon))
  nobs <- length(index)
  # Make dataset
  simdf <- tibble::tibble(
    lopnr = seq(nobs),
    bornyear = bornyear[index],
    atumon = atumon[index]
  )
  # output:
  # lopnr = id number for each subject

  # Tumour growth rates
  simdf$grr <- stats::rgamma(nobs, shape = tau1, scale = 1 / tau2) ## inverse growth rates
  # output:
  # grr=inverse growth rate

  # Tumour volumes at clinical detection
  v0 <- (1 / 6) * pi * (d0^3) # v0 in vcell in the formulae, volume of a cell of diameter d0 = 0.5 mm
  u <- stats::runif(n = nobs)
  simdf$vcd <- v0 - (log(1 - u)) / (gam * simdf$grr) # volume
  simdf$sizesymp <- (6 * simdf$vcd / pi)^(1 / 3) # turns the volumes 'vcd' into diameters
  # output:
  # sizesymp = tumour sizes at clinical detection (diameter)

  # age at clinical detection
  simdf$agesymp <- simdf$atumon + simdf$grr * log(simdf$vcd / v0) # atumon + formula 11, but written as t = ...
  # output:
  # agesymp = age at clinical detection

  # NEED TO GENERATE SURVIVAL TIME VARIABLES
  # SURVIVAL DUE TO BC FROM FPM, WITH AGE
  # AS ONLY EXPLANATORY VARIABLE
  # DEATH DUE TO OTHER CAUSES FROM POPMORT FILE

  # simulate survival time due to bc
  # Simulate the event times

  dat <- simsurv(
    betas = mybeta, # "true" parameter values
    x = data.frame(id = seq(nrow(simdf)), agesymp = simdf$agesymp), # covariate data
    knots = myknots, # knot locations for splines
    logcumhazard = logcumhaz, # definition of log
    maxt = 30,
    interval = c(0, 1e10)
  )

  # # Merge the simulated event times onto covariate data frame
  # dat <- merge(cov, dat)
  simdf$timebc <- simdf$agesymp + dat$eventtime # how old was the woman when she died of bc
  # output:
  # timebc = age at death due to bc

  # simulate survival time due to other causes
  ages <- 0:99
  prob_matrix <- matrix(data = 0, nrow = nobs, ncol = length(ages))

  long <- tidyr::crossing(
    tibble::tibble(lopnr = simdf$lopnr, bornyear = simdf$bornyear),
    agep = ages,
    sexp = 2
  )
  long$yearp <- long$bornyear + long$agep
  long$yearp[which(long$yearp > 2070)] <- 2070
  long <- dplyr::inner_join(long, popmort, by = c("agep" = "_age", "yearp" = "_year", "sexp" = "sex"))
  u <- stats::runif(n = nrow(long))
  long$timi <- log(u) / log(long$prob)
  long <- dplyr::select(long, lopnr, timi, agep)
  long <- tidyr::pivot_wider(long, names_from = agep, values_from = timi, id_cols = lopnr)
  long <- as.matrix(long)
  timeother <- vapply(X = seq(nrow(long)), FUN = function(row) {
    i <- which(long[row, ] < 1)[1]
    long[row, i] + i - 2
  }, FUN.VALUE = numeric(1))
  timeother[is.na(timeother)] <- 100
  simdf$timeother <- timeother

  # if dies prior to tumor onset, do not include
  simdf <- dplyr::filter(simdf, atumon < timeother)

  # a few extra variables
  simdf$yearsymp <- floor(simdf$agesymp + simdf$bornyear)
  simdf$yeartumon <- floor(simdf$atumon + simdf$bornyear)
  # output:
  # yeartumon=calendar year at start of tumour growth
  # yearsymp=calendar year at symptomatic detection
  # allobs=total number of simulated observations
  # obscohort=number of simulated individuals per birth cohort

  # return the data
  return(simdf)
}
