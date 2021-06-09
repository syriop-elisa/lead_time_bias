# Define a function returning the log cum hazard at time t
logcumhaz <- function(t, x, betas, knots) {

  # Obtain the basis terms for the spline-based log
  # cumulative hazard (evaluated at time t)
  basis <- flexsurv::basis(knots = knots, x = log(t))

  # Evaluate the log cumulative hazard under the
  # Royston and Parmar specification
  res <-
    betas[["cons"]] * basis[[1]] +
    betas[["rcs1"]] * basis[[2]] +
    betas[["rcs2"]] * basis[[3]] +
    betas[["rcs3"]] * basis[[4]] +
    betas[["agesymp"]] * x[["agesymp"]]

  # Return the log cumulative hazard at time t
  res
}
