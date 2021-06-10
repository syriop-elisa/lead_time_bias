# Code to create latex table for the paper: 
# Table S2 - Bias (absolute scale) for externally age-standardised 10-year relative survival (RS), loss in life expectancy(LLE) and proportion of life lost (PLL) across different screening sensitivities and attendance scenarios, with 95% confidence  intervals based on the Monte Carlo  error for bias (across 200 simulations). Bias was obtained as the difference to the setting in which no screening is imposed and all cases are symptomatic


library(rsimsum)
library(tidyverse)
library(haven)
library(knitr)
library(kableExtra)
library(formattable)
library(glue)

# Dataset with results
res <- read_dta(file = "dta/estimates.dta") %>%
  zap_formats() %>%
  mutate(attendance = factor(attendance, levels = 0:1, labels = c("Perfect", "Imperfect"))) %>%
  mutate(method = factor(method, levels = c(0, 2, 1, 3), labels = c("None", "Low", "Moderate", "High"))) %>%
  rename(Attendance = attendance, Screening = method) %>%
  pivot_longer(cols = 4:6) %>%
  mutate(value = ifelse(name != "lle", value * 100, value)) %>%
  mutate(name = factor(name, levels = c("relsurv10", "lle", "pll"), labels = c("10-Year RS", "LLE", "PLL")))

# Define reference (target) values
ref <- filter(res, Attendance == "Perfect" & Screening == "None") %>%
  rename(target = value) %>%
  select(i, name, target)

# Merge
res <- left_join(
  res,
  ref,
  by = c("i", "name")
)

###
sssum <- multisimsum(
  data = res,
  par = "name",
  estvarname = "value",
  true = "target",
  by = c("Attendance", "Screening")
)


# Table: absolute bias
sink(file = "tex/tab_absolute_bias.tex")
get_data(sssum) %>%
  filter(stat == "bias") %>%
  filter(!(Attendance == "Imperfect" & Screening == "None")) %>% 
  mutate(lower = est - qnorm(1 - 0.05 / 2) * mcse,
         upper = est + qnorm(1 - 0.05/2) * mcse,
         y = glue("{comma(est, 2)} ({comma(lower, 2)} -- {comma(upper, 2)})")) %>% 
  select(-stat, -mcse, -est, -lower, -upper) %>% 
  pivot_wider(names_from = name, values_from = y) %>% 
  arrange(Attendance, Screening) %>%
  mutate(Attendance = as.character(Attendance),
         Screening = as.character(Screening)) %>% 
  mutate(Attendance = ifelse(row_number() == 1, "---", Attendance),
         Screening = ifelse(row_number() == 1, "None (reference)", Screening),
         `10-Year RS` = ifelse(row_number() == 1, "---", `10-Year RS`),
         LLE = ifelse(row_number() == 1, "---", LLE),
         PLL = ifelse(row_number() == 1, "---", PLL)) %>% 
  kable(format = "latex", booktabs = TRUE, align = rep("c", 5), linesep = "")
sink()
