### Packages
library(glue)
library(haven)
library(tidyverse)

library(simsurv)
library(flexsurv)


source("simulation/natural-history-model.R", echo = TRUE)
source("simulation/screening.R", echo = TRUE)
source("simulation/simulate-fpm.R", echo = TRUE)

# first distribute the probabilities of onset at different ages
# from incidence 1973
pstarti <- c(
  1.37, 1.37, 1.37, 1.37, 1.37,
  6.07, 6.07, 6.07, 6.07, 6.07,
  15.80, 15.80, 15.80, 15.80, 15.80,
  44.31, 44.31, 44.31, 44.31, 44.31,
  87.59, 87.59, 87.59, 87.59, 87.59,
  139.5, 139.5, 139.5, 139.5, 139.5,
  143.24, 143.24, 143.24, 143.24, 143.24,
  150.35, 150.35, 150.35, 150.35, 150.35,
  180.11, 180.11, 180.11, 180.11, 180.11,
  202.79, 202.79, 202.79, 202.79, 202.79,
  213.08, 213.08, 213.08, 213.08, 213.08,
  256, 256, 256, 256, 256,
  340.35, 340.35, 340.35, 340.35, 340.35,
  346.48, 346.48, 346.48, 346.48, 346.48,
  335, 335, 335, 335, 335,
  325, 325, 325, 325, 325,
  315, 315, 315, 315, 315,
  300, 300, 300, 300, 300
)
pstarti <- pstarti / 100000
fact <- 1

# parameter values for the tumor growth
tau1 <- 1.385
tau2 <- tau1
gammavar <- 8.268 # eta in the formulae
gam <- exp(-gammavar)
d0 <- 0.5 # diameter

# popmort for other cause mortality
popmort <- haven::read_dta("dta/popmort_projection.dta")
popmort <- haven::zap_label(popmort)
popmort <- haven::zap_labels(popmort)
popmort <- haven::zap_formats(popmort)

# observations and birth cohorts
nnobs <- 10000
year1 <- 1870
year2 <- 1965
bycohort <- 1

# screening interval
a1 <- 40
au <- 75
byyear <- 2


# parameters values of flexible parametric model based on Swedish registry breast cancer data
# define model parameters and knots
mybeta <- c(
  agesymp = .01553308,
  rcs1 = 1.0984277,
  rcs2 = -.02851371,
  rcs3 = .08316873,
  cons = -3.1615401
)

myknots <- log(c(.0416666666666666, 2.926598173515981, 9.490981735159819, 29.99783105022833))

cov <- data.frame(id = seq(nnobs), agediag = rnorm(nnobs, mean = 62.71848, sd = 13.601991))


# screening parameters for moderate screening
beta1_1 <- -5.04
beta2_1 <- 0.56

# screening parameters for low screening
beta1_2 <- -5.45
beta2_2 <- 0.48

# screening parameters for high screening
beta1_3 <- -4.67
beta2_3 <- 0.65

# set seed for reproducibility
set.seed(165)
# do B replicates
B <- 200

# Setup progress bar
pb <- utils::txtProgressBar(min = 0, max = B, style = 3)
for (i in seq(B)) {

  # Base data
  qq <- natural_history_data(pstarti = pstarti, obs = nnobs, tau1 = tau1, tau2 = tau2, d0 = d0, gam = gam, popmort = popmort, year1 = year1, year2 = year2, bycohort = bycohort, mybeta = mybeta, cov = cov, myknots = myknots, mult = fact)

  # Screening scenario 1
  rr_1_perfect <- impose_screening(aa = qq, a1 = a1, au = au, beta1 = beta1_1, beta2 = beta2_1, byyr = byyear, v0 = d0, perfect_screening = TRUE)
  rr_1_imperfect <- impose_screening(aa = qq, a1 = a1, au = au, beta1 = beta1_1, beta2 = beta2_1, byyr = byyear, v0 = d0, perfect_screening = FALSE)

  # Screening scenario 2
  rr_2_perfect <- impose_screening(aa = qq, a1 = a1, au = au, beta1 = beta1_2, beta2 = beta2_2, byyr = byyear, v0 = d0, perfect_screening = TRUE)
  rr_2_imperfect <- impose_screening(aa = qq, a1 = a1, au = au, beta1 = beta1_2, beta2 = beta2_2, byyr = byyear, v0 = d0, perfect_screening = FALSE)

  # Screening scenario 3
  rr_3_perfect <- impose_screening(aa = qq, a1 = a1, au = au, beta1 = beta1_3, beta2 = beta2_3, byyr = byyear, v0 = d0, perfect_screening = TRUE)
  rr_3_imperfect <- impose_screening(aa = qq, a1 = a1, au = au, beta1 = beta1_3, beta2 = beta2_3, byyr = byyear, v0 = d0, perfect_screening = FALSE)


  # Combine into a single dataset with the three scenarios, in wide format
  # First, prepare files to be joined
  rr_1_perfect <- dplyr::rename(rr_1_perfect, sizedet_1_perfect = sizedet, diamam_1_perfect = diamam, agedet_1_perfect = agedet, yeardet_1_perfect = yeardet)
  rr_1_imperfect <- dplyr::select(rr_1_imperfect, lopnr, sizedet, diamam, agedet, yeardet) %>%
    dplyr::rename(sizedet_1_imperfect = sizedet, diamam_1_imperfect = diamam, agedet_1_imperfect = agedet, yeardet_1_imperfect = yeardet)

  rr_2_perfect <- dplyr::select(rr_2_perfect, lopnr, sizedet, diamam, agedet, yeardet) %>%
    dplyr::rename(sizedet_2_perfect = sizedet, diamam_2_perfect = diamam, agedet_2_perfect = agedet, yeardet_2_perfect = yeardet)
  rr_2_imperfect <- dplyr::select(rr_2_imperfect, lopnr, sizedet, diamam, agedet, yeardet) %>%
    dplyr::rename(sizedet_2_imperfect = sizedet, diamam_2_imperfect = diamam, agedet_2_imperfect = agedet, yeardet_2_imperfect = yeardet)

  rr_3_perfect <- dplyr::select(rr_3_perfect, lopnr, sizedet, diamam, agedet, yeardet) %>%
    dplyr::rename(sizedet_3_perfect = sizedet, diamam_3_perfect = diamam, agedet_3_perfect = agedet, yeardet_3_perfect = yeardet)
  rr_3_imperfect <- dplyr::select(rr_3_imperfect, lopnr, sizedet, diamam, agedet, yeardet) %>%
    dplyr::rename(sizedet_3_imperfect = sizedet, diamam_3_imperfect = diamam, agedet_3_imperfect = agedet, yeardet_3_imperfect = yeardet)
  # Then, join them
  rr <- dplyr::left_join(rr_1_perfect, rr_1_imperfect, by = "lopnr") %>%
    dplyr::left_join(rr_2_perfect, by = "lopnr") %>%
    dplyr::left_join(rr_2_imperfect, by = "lopnr") %>%
    dplyr::left_join(rr_3_perfect, by = "lopnr") %>%
    dplyr::left_join(rr_3_imperfect, by = "lopnr")

  # Now, export in Stata format
  haven::write_dta(data = rr, path = glue::glue("dta/simdata_wide_{i}.dta"))

  # Advance progress bar
  utils::setTxtProgressBar(pb = pb, value = i)
}
close(pb)
