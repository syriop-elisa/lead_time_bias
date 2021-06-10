# Create Figures 1 and 2 for absolute and relative bias respectively:
# Figure 1 - Bias  for  externally  age-standardised  10-year  relative  survival  (RS),  loss  in  life  expectancy  (LLE)  andproportion  of  life  lost  (PLL)  across  different  screening  sensitivities  and  attendance  scenarios,  with  95%  confidenceintervals based on the Monte Carlo error for bias (across 200 simulations).  Bias was obtained as the difference to thesetting in which no screening is imposed and all cases are symptomatic.
# Figure 2 - Average relative bias for externally age-standardised 10-year relative survival (RS), loss in life expectancy(LLE) and proportion of life lost (PLL) across different screening sensitivities and attendance scenarios, with 2.5 and97.5 percentiles based on 200 simulations.  The reference scenario is the setting in which no screening is imposed andall cases are symptomatic. 

library(rsimsum)
library(tidyverse)
library(haven)
.base_plot_unit <- 4
.sf <- sqrt(4)

# Dataset with results
res <- read_dta(file = "dta/estimates.dta") %>%
  zap_formats() %>%
  mutate(attendance = factor(attendance, levels = 0:1, labels = c("Perfect", "Imperfect"))) %>%
  mutate(method = factor(method, levels = c(0, 2, 1, 3), labels = c("None", "Low", "Moderate", "High"))) %>%
  rename(Attendance = attendance, Screening = method) %>%
  pivot_longer(cols = 4:6) %>%
  mutate(value = ifelse(name != "lle", value * 100, value)) %>%
  mutate(name = factor(name, levels = c("relsurv10", "lle", "pll"), labels = c("10-Year Relative Survival", "Loss in Life Expectancy", "Proportion of Life Lost")))

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
sssumdf <- get_data(sssum) %>%
  filter(stat == "bias") %>%
  filter(Screening != "None")

# Figure 1: absolute bias
p_absolute_bias <- ggplot(sssumdf, aes(x = Screening, y = est, shape = Attendance)) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "gray50") +
  geom_errorbar(aes(ymin = est - qnorm(1 - 0.05 / 2) * mcse, ymax = est + qnorm(1 - 0.05 / 2) * mcse), position = position_dodge(width = 0.5), width = 0.1) +
  geom_point(position = position_dodge(width = 0.5)) +
  scale_y_continuous(labels = function(x) scales::comma(x, accuracy = 0.1)) +
  facet_wrap(~name, scales = "free_y", ncol = 1) +
  labs(y = "Bias (with 95% C.I.)", x = "Screening Sensitivity") +
  theme_bw(base_size = 12, base_family = "Roboto Condensed") +
  theme(legend.position = "bottom", strip.background = element_rect(fill = "grey90"), panel.grid.minor = element_blank())
ggsave(filename = "pdf/p_absolute_bias.pdf", plot = p_absolute_bias, device = cairo_pdf, height = .base_plot_unit * .sf, width = .base_plot_unit)

# Figure 2: relative bias
rbdf <- res %>%
  mutate(y = (value - target) / target) %>%
  filter(Screening != "None") %>%
  group_by(Attendance, Screening, name) %>%
  summarise(
    mean = mean(y),
    lower = quantile(y, 0.025),
    upper = quantile(y, 0.975)
  ) %>%
  ungroup()

p_relative_bias <- ggplot(rbdf, aes(x = Screening, shape = Attendance)) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "gray50") +
  geom_errorbar(aes(ymin = lower, ymax = upper), position = position_dodge(width = 0.5), width = 0.1) +
  geom_point(aes(y = mean), position = position_dodge(width = 0.5)) +
  facet_wrap(~name, scales = "free_y", ncol = 1) +
  scale_y_continuous(labels = function(x) scales::percent(x, accuracy = 0.1), breaks = seq(-1, 1, by = 0.025)) +
  labs(y = "Average Relative Bias (with 2.5 and 97.5 Percentiles)", x = "Screening Sensitivity") +
  theme_bw(base_size = 12, base_family = "Roboto Condensed") +
  theme(legend.position = "bottom", strip.background = element_rect(fill = "grey90"), panel.grid.minor = element_blank())
ggsave(filename = "pdf/p_relative_bias.pdf", plot = p_relative_bias, device = cairo_pdf, height = .base_plot_unit * .sf, width = .base_plot_unit)
