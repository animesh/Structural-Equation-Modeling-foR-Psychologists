
income_psych <- read.csv("income_psych.csv")

head(income_psych)

# Testing mediation:
# Does negative mood mediate the relationship between anxiety and income?
# Graphically, it looks like "plot1.png"

# Manual path analysis ----------------------------------------------------

m1 <- lm(income ~ anxiety + mood_neg, income_psych)
m2 <- lm(mood_neg ~ anxiety, income_psych)

(coef1 <- coef(m1))
(coef2 <- coef(m2))

direct <- unname(coef1[2])
indirect <- unname(coef1[3] * coef2[2])

mediation_by_hand <- c(direct = direct,
                       indirect = indirect,
                       total = direct + indirect)

summary(lm(income ~ anxiety, income_psych))
mediation_by_hand


# With lavaan -------------------------------------------------------------

# lets do this with `lavaan`!

library(lavaan)

# modelss are written as a multi-line charachter object:
mediation_model <- '
    income ~ anxiety + mood_neg
  mood_neg ~ anxiety
'

# fit the model to the data:
fit <- sem(mediation_model, data = income_psych)

summary(fit) # (why is the Test Statistic 0?)

summary(fit, standardize = TRUE) # look at Std.all for beta
summary(fit, rsquare = TRUE) # See regression R2
# Note that by DEFAULT, lavaan estimates all residual errors.


# Modifiers! --------------------------------------------------------------

# how to compute the paths? With *modifiers*!
# - We can mark parameters with a "stand-ins" followed by "*"
# - We can have lavaan compute effects with ":="
mediation_model <- '
  # regressions
  mood_neg ~ a * anxiety
    income ~ b * mood_neg + c * anxiety
  

  # effects
    direct := c
  indirect := a * b
     total := direct + indirect
'
fit <- sem(mediation_model, data = income_psych)

summary(fit, standardize = TRUE) # look at "Defined Parameters" 
mediation_by_hand
cor(income_psych$anxiety, income_psych$income)

## Confidence intervals:
summary(fit, standardize = TRUE, ci = TRUE) # ci for the raw estimates
standardizedSolution(fit, ci = TRUE, output = "text") # ci for the std estimates

## Bootstrap
fit_with_boot <- sem(mediation_model, data = income_psych,
                     se = "bootstrap", bootstrap = 200)
summary(fit_with_boot, standardize = TRUE)


# Compare paths -----------------------------------------------------------

# We can also compare paths directly:
mediation_model <- '
  # regressions
  mood_neg ~ a * anxiety
    income ~ b * mood_neg + c * anxiety
  

  # effects
     direct := c
   indirect := a * b
      total := direct + indirect
      
  path_diff := direct - indirect
'
fit <- sem(mediation_model, data = income_psych)

# look at "Defined Parameters" 
parameterEstimates(fit, output = "text") # summary gives these test values
standardizedSolution(fit, output = "text")
# Note that the tests from these 2 functions CAN BE DIFFERENT. Why?


fit <- sem(mediation_model, data = income_psych,
           likelihood = "wishart")
# likelihood = "wishart" used an unbiased cov-matrix, and gives
# similar results to AMOS (SPSS).
# In large samples this heardly has any effects...
# Read more about the varouls likelihoods and estimators:
# http://lavaan.ugent.be/tutorial/est.html

# Plotting ----------------------------------------------------------------

library(tidySEM)

graph_sem(fit)

graph_sem(fit, label = "est_std")


# See also advanced plotting.R


# Exercise ----------------------------------------------------------------

# 1. Look at the plot in "plot2.png". Fit this model with `lavaan`.
# 2. Compute all the paths in this model from *anxiety* to *income*, and 
#    the total of these paths.
#    - Why is the std total not equal exactly to the real correlation?
#    - is it very different?

