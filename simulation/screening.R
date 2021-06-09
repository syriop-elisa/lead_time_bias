############################################
# Now find screening detected tumors
############################################

# sts computes screening sensitivity
sts <- function(.size, .beta1, .beta2) { # size here is diameter of the tumour
  STS <- exp(.beta1 + .beta2 * .size) / (1 + exp(.beta1 + .beta2 * .size))
  return(STS)
}

impose_screening <- function(aa, a1, au, beta1, beta2, byyr, v0, perfect_screening) {
  nobs <- nrow(aa)

  sizedet <- rep(NA, nobs)
  diamam <- rep(0, nobs)
  agedet <- rep(NA, nobs)
  yeardet <- rep(NA, nobs)

  # first diagnose those who will not have cancer during screening
  # these are people that already had symptoms (were diagnosed/detected) before age of 40, when screening started
  i0 <- which((diamam == 0) & (aa$agesymp <= a1))
  sizedet[i0] <- aa$sizesymp[i0]
  diamam[i0] <- 1
  agedet[i0] <- aa$agesymp[i0]
  yeardet[i0] <- aa$yearsymp[i0]

  # first diagnose those who will not have cancer during screening
  # these are people that didn't have cancer yet
  i0 <- which((diamam == 0) & (aa$atumon > au))
  sizedet[i0] <- aa$sizesymp[i0]
  diamam[i0] <- 5
  agedet[i0] <- aa$agesymp[i0]
  yeardet[i0] <- aa$yearsymp[i0]

  # screening
  if (perfect_screening) {
    attender <- rep(1, nobs)
    p_attending_a_visit <- rep(1, nobs)
  } else {
    # there is a 80 percent probability of attending screening
    attender <- rbinom(n = nobs, size = 1, prob = 0.8)
    # Among those who have a high probability to attend screening (attender=1), there is 90 percent probability of attending a specific visit tt
    # Among those who have a low probability to attend screening (attender=0), there is 15 percent probability of attending a specific visit tt
    p_attending_a_visit <- ifelse(attender == 0, 0.15, 0.9)
  }

  # loop through those who might be detected during screening
  for (tt in seq(a1, au, by = byyr)) {


    # those that have not yet been diagnosed, but have symp detection before time tt
    i1 <- which((diamam == 0) & (aa$atumon <= tt) & (tt >= aa$agesymp))
    sizedet[i1] <- aa$sizesymp[i1]
    diamam[i1] <- 2
    agedet[i1] <- aa$agesymp[i1]
    yeardet[i1] <- aa$yearsymp[i1]

    # those that have not yet been diagnosed, and have an undiagnosed tumor
    i2 <- which((diamam == 0) & (aa$atumon <= tt) & (tt < aa$agesymp))
    if (length(i2) > 0) {
      for (a in 1:length(i2)) {
        vnow <- (pi * (v0^3) / 6) * exp((tt - aa$atumon[i2[a]]) / aa$grr[i2[a]]) # calculate volume of tumour at current screen
        sizenow <- (6 * vnow / pi)^(1 / 3) # turn volume into diameter
        tmp <- sts(.size = sizenow, .beta1 = beta1, .beta2 = beta2) # calculate screening sensitivity: P(being detected by screening with a tumour of diameter 'sizenow' when screened at age 'tt')
        attended_this_visit <- rbinom(n = 1, size = 1, prob = p_attending_a_visit[i2[a]])
        tmp <- tmp * attended_this_visit
        u <- stats::runif(n = 1)
        # kind of equivalent to detected = rbinom(n = 1, size = 1, prob = tmp), Bernoulli(tmp)
        if (u < tmp) { # if u smaller than tmp -> screen detection!
          sizedet[i2[a]] <- sizenow
          diamam[i2[a]] <- 3
          agedet[i2[a]] <- tt
          yeardet[i2[a]] <- floor(aa$bornyear[i2[a]] + tt)
        }
      }
    }
    # now loop for the next screen age
  }

  # now those that have been in screening but not yet diagnosed
  # these are people with a tumour, not detected yet by screening, not detected yet by symptoms
  i3 <- which((diamam == 0) & (!is.na(aa$atumon)))
  sizedet[i3] <- aa$sizesymp[i3]
  diamam[i3] <- 4
  agedet[i3] <- aa$agesymp[i3]
  yeardet[i3] <- aa$yearsymp[i3]

  # save characteristics of the screening process and return
  nn <- tibble::tibble(aa, sizedet, diamam, agedet, yeardet)
  return(nn)
}
