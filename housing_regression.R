# ==============================================================
# Jacksonville Housing: Multiple Linear Regression in R
# STAT 4043 (Applied Regression Analysis) course project
# Oklahoma State University
#
# Response:   SalePrice (USD)
# Data:       Jaxhouse.csv (104 single-family home sales, zip 32244,
#             west Jacksonville, FL, first half of 2019)
# To run:     put Jaxhouse.csv in the same folder as this script and
#             set that folder as your working directory
#             (RStudio: Session > Set Working Directory > To Source File Location)
# ==============================================================

# ---- Libraries ----
library(car)
library(MASS)

# ---- Read data ----
jax <- read.csv("Jaxhouse.csv", header = TRUE)

# ---- Convert categorical variables to factors ----
jax$Townhouse <- factor(jax$Townhouse)
jax$Pool      <- factor(jax$Pool)

# ---- Drop YearConst (YearConst + Age2020 = 2020, so they are perfectly collinear) ----
jax$YearConst <- NULL



# ===== Response variable: SalePrice =====
# Numerical summary
summary(jax$SalePrice)
sd(jax$SalePrice)

# Figures 1 and 2: histogram and boxplot of SalePrice
par(mfrow = c(1, 2))
hist(jax$SalePrice/1000, main = "Figure 1: Histogram of Sale Price",
     xlab = "Sale Price ($1000s)", col = "grey90")
boxplot(jax$SalePrice/1000, main = "Figure 2: Boxplot of Sale Price",
        ylab = "Sale Price ($1000s)")
par(mfrow = c(1, 1))

# ===== Figure 3 — continuous predictor boxplots =====
par(mfrow = c(2, 3), oma = c(1, 1, 4, 1), mar = c(3, 3, 3, 1))
boxplot(jax$Bedrooms, main = "Bedrooms")
boxplot(jax$Baths,    main = "Baths")
boxplot(jax$GrossSF,  main = "GrossSF (sq ft)")
boxplot(jax$HtdSF,    main = "HtdSF (sq ft)")
boxplot(jax$Age2020,  main = "Age in 2020 (years)")
boxplot(jax$LotSF,    main = "LotSF (sq ft)")
mtext("Figure 3: Boxplots of Continuous Predictors",
      side = 3, outer = TRUE, line = 1, cex = 1.3, font = 2)
par(mfrow = c(1, 1))

# ===== Categorical predictors =====
table(jax$Townhouse)
table(jax$Pool)

# Explore response vs categorical
par(mfrow = c(1, 2))
boxplot(SalePrice/1000 ~ Townhouse, data = jax,
        main = "FIGURE 4 Price by Townhouse status", ylab = "Price ($1000s)")
boxplot(SalePrice/1000 ~ Pool, data = jax,
        main = "Price by Pool", ylab = "Price ($1000s)")
par(mfrow = c(1, 1))

# ===== Correlations among continuous variables =====
cont_vars <- c("Bedrooms","Baths","GrossSF","HtdSF","Age2020",
               "LotSF","SalePrice")
round(cor(jax[, cont_vars]), 3)

# Pairs plot of a subset of continuous variables
# ===== Figure 5 — Pairs plot =====
pairs(jax[, c("SalePrice","GrossSF","HtdSF","Age2020","LotSF")],
      main = "Figure 5: Pairwise Scatterplots of Continuous Variables")
# ==============================================================
# Modeling
# ==============================================================


# ==============================================================
# Step 5: Initial full model and diagnostics
# ==============================================================

# ---- Fit the full model with all 8 predictors ----
fullfit <- lm(SalePrice ~ Bedrooms + Baths + GrossSF + HtdSF + 
                Age2020 + LotSF + Townhouse + Pool, 
              data = jax)
summary(fullfit)

# ---- Part B1: Residuals vs fitted (linearity + constant variance) ----
par(mfrow = c(1,1))
plot(fullfit$fitted.values, studres(fullfit),
     xlab = "Fitted Values", ylab = "Studentized Residuals",
     main = "Figure 6: Residuals vs Fitted — Full Model")
abline(h = c(-3, 0, 3), lty = c(2, 1, 2))

# ---- Part B2: Normality — QQ plot ----
qqnorm(fullfit$residuals, main = "Figure 7: Normal Q-Q Plot — Full Model")
qqline(fullfit$residuals)

# Quantify normality
norm_check <- qqnorm(fullfit$residuals, plot.it = FALSE)
cat("QQ correlation:", cor(norm_check$x, norm_check$y), "\n")

# ---- Part B3: Histogram of residuals (visual normality check) ----
hist(fullfit$residuals, breaks = 15,
     main = "Figure 8: Histogram of Residuals — Full Model",
     xlab = "Residuals")

# ---- Part B4: Multicollinearity — VIFs ----
vif(fullfit)

# ---- Part C: Outliers and influential observations ----
# Cook's distance
plot(cooks.distance(fullfit), type = "h",
     main = "Figure 9: Cook's Distance — Full Model",
     ylab = "Cook's Distance", xlab = "Observation Index")
abline(h = 4/nrow(jax), lty = 2, col = "red")

# Which observations have highest Cook's distance?
cd <- cooks.distance(fullfit)
head(sort(cd, decreasing = TRUE), 10)

# Leverage (hat values)
hv <- hatvalues(fullfit)
p <- length(coef(fullfit))
n <- nrow(jax)
cat("Average hat value (p/n):", p/n, "\n")
cat("High leverage threshold (2p/n):", 2*p/n, "\n")
head(sort(hv, decreasing = TRUE), 10)

# Studentized residuals — observations with |studres| > 3
sr <- studres(fullfit)
which(abs(sr) > 3)
jax[c(72, 88, 103, 104), ]



# ==============================================================
# Part D: Remedial measure — drop influential observations 103, 104
# ==============================================================

# Create cleaned dataset
jax_clean <- jax[-c(103, 104), ]
nrow(jax_clean)   # should be 102

# Refit full model on cleaned data
fullfit2 <- lm(SalePrice ~ Bedrooms + Baths + GrossSF + HtdSF +
                 Age2020 + LotSF + Townhouse + Pool,
               data = jax_clean)
summary(fullfit2)

# ---- Re-check all assumptions ----

# Residuals vs fitted
plot(fullfit2$fitted.values, studres(fullfit2),
     xlab = "Fitted Values", ylab = "Studentized Residuals",
     main = "Figure 10: Residuals vs Fitted — After Removing 103, 104")
abline(h = c(-3, 0, 3), lty = c(2, 1, 2))

# QQ plot
qqnorm(fullfit2$residuals,
       main = "Figure 11: Normal Q-Q Plot — After Removing 103, 104")
qqline(fullfit2$residuals)

# Quantify normality
norm_check2 <- qqnorm(fullfit2$residuals, plot.it = FALSE)
cat("QQ correlation after removal:", cor(norm_check2$x, norm_check2$y), "\n")

# Histogram of residuals
hist(fullfit2$residuals, breaks = 15,
     main = "Figure 12: Histogram of Residuals — Cleaned",
     xlab = "Residuals")

# VIFs
vif(fullfit2)

# Cook's Distance — relabeled
cd2 <- cooks.distance(fullfit2)
threshold2 <- 4 / nrow(jax_clean)
plot(cd2, type = "h",
     main = "Figure 13: Cook's Distance — After Removing 103, 104",
     ylab = "Cook's Distance", xlab = "Observation Index",
     ylim = c(0, max(cd2) * 1.2))
abline(h = threshold2, lty = 2, col = "red")
high_idx2 <- which(cd2 > threshold2)
text(x = high_idx2, y = cd2[high_idx2], labels = high_idx2,
     pos = 3, cex = 0.8, col = "blue")

# Studentized residuals over 3
which(abs(studres(fullfit2)) > 3)



# Sensitivity check: also remove row 88 (high leverage, low Cook's distance).
# Rows 103 and 104 come after row 88, so its row name is unchanged in jax_clean.

jax_final <- jax_clean[-which(rownames(jax_clean) == "88"), ]
nrow(jax_final)   # should be 101

# Refit
fullfit3 <- lm(SalePrice ~ Bedrooms + Baths + GrossSF + HtdSF +
                 Age2020 + LotSF + Townhouse + Pool,
               data = jax_final)
summary(fullfit3)

# Re-check assumptions
plot(fullfit3$fitted.values, studres(fullfit3),
     xlab = "Fitted Values", ylab = "Studentized Residuals",
     main = "Sensitivity: Residuals vs Fitted — After Removing 88, 103, 104")
abline(h = c(-3, 0, 3), lty = c(2, 1, 2))

qqnorm(fullfit3$residuals,
       main = "Sensitivity: Normal Q-Q Plot — After Removing 88, 103, 104")
qqline(fullfit3$residuals)
norm_check3 <- qqnorm(fullfit3$residuals, plot.it = FALSE)
cat("QQ correlation now:", cor(norm_check3$x, norm_check3$y), "\n")

hist(fullfit3$residuals, breaks = 15,
     main = "Sensitivity: Histogram of Residuals — After Removing 88, 103, 104",
     xlab = "Residuals")

vif(fullfit3)

cd3 <- cooks.distance(fullfit3)
threshold3 <- 4 / nrow(jax_final)
plot(cd3, type = "h",
     main = "Sensitivity: Cook's Distance — After Removing 88, 103, 104",
     ylab = "Cook's Distance", xlab = "Observation Index",
     ylim = c(0, max(cd3) * 1.2))
abline(h = threshold3, lty = 2, col = "red")
high_idx3 <- which(cd3 > threshold3)
text(x = high_idx3, y = cd3[high_idx3], labels = high_idx3,
     pos = 3, cex = 0.8, col = "blue")

which(abs(studres(fullfit3)) > 3)
head(sort(cd3, decreasing = TRUE), 5)

# Row 88 is retained: the sensitivity fit above is for comparison only.
# jax_clean (102 rows) and fullfit2 remain the reference dataset and model.
nrow(jax_clean)   # 102
summary(fullfit2)

# ==============================================================
# Step 6: Model Selection: AIC stepwise
# ==============================================================

# ---- Main effects: forward-backward stepwise from null model ----
fit0 <- lm(SalePrice ~ 1, data = jax_clean)

step_main <- step(fit0, 
                  SalePrice ~ Bedrooms + Baths + GrossSF + HtdSF + 
                    Age2020 + LotSF + Townhouse + Pool, 
                  direction = "both", trace = 1)

# Show selected main-effects model
summary(step_main)

# ---- Refit chosen main-effects model with a clean name ----
fitmain <- lm(SalePrice ~ GrossSF + Age2020 + Townhouse + Pool, 
              data = jax_clean)
summary(fitmain)

# ---- Interaction search: stepwise from main-effects model ----
step_int <- step(fitmain, 
                 scope = . ~ .^2, 
                 direction = "both", 
                 trace = 1)

summary(step_int)

# ---- Final model: assign clean name for diagnostics ----
final_fit <- step_int   # stepwise added no interactions, so this equals fitmain


# ==============================================================
# Step 7: Final Model Diagnostics
# Final model = fitmain (main effects only; no interactions were added)
# ==============================================================


# ---- Residuals vs Fitted ----
plot(final_fit$fitted.values, studres(final_fit),
     xlab = "Fitted Values", ylab = "Studentized Residuals",
     main = "Figure 14: Residuals vs Fitted — Final Model")
abline(h = c(-3, 0, 3), lty = c(2, 1, 2))

# ---- Residuals vs each main-effect predictor ----
par(mfrow = c(2, 2))
plot(jax_clean$GrossSF, studres(final_fit),
     xlab = "GrossSF", ylab = "Studentized Residuals",
     main = "Residuals vs GrossSF")
abline(h = 0, lty = 2)
plot(jax_clean$Age2020, studres(final_fit),
     xlab = "Age2020", ylab = "Studentized Residuals",
     main = "Residuals vs Age2020")
abline(h = 0, lty = 2)
boxplot(studres(final_fit) ~ jax_clean$Townhouse,
        xlab = "Townhouse", ylab = "Studentized Residuals",
        main = "Residuals by Townhouse")
abline(h = 0, lty = 2)
boxplot(studres(final_fit) ~ jax_clean$Pool,
        xlab = "Pool", ylab = "Studentized Residuals",
        main = "Residuals by Pool")
abline(h = 0, lty = 2)
mtext("Figure 15: Residuals vs Each Predictor — Final Model",
      side = 3, outer = TRUE, line = -1.5, cex = 1.2, font = 2)
par(mfrow = c(1, 1))

# ---- QQ plot ----
qqnorm(final_fit$residuals,
       main = "Figure 16: Normal Q-Q Plot — Final Model")
qqline(final_fit$residuals)
norm_check_final <- qqnorm(final_fit$residuals, plot.it = FALSE)
cat("QQ correlation, final model:",
    cor(norm_check_final$x, norm_check_final$y), "\n")

# ---- Cook's Distance ----
cd_final <- cooks.distance(final_fit)
threshold_final <- 4 / nrow(jax_clean)
plot(cd_final, type = "h",
     main = "Figure 17: Cook's Distance — Final Model",
     ylab = "Cook's Distance", xlab = "Observation Index",
     ylim = c(0, max(cd_final) * 1.2))
abline(h = threshold_final, lty = 2, col = "red")
high_idx_final <- which(cd_final > threshold_final)
text(x = high_idx_final, y = cd_final[high_idx_final], labels = high_idx_final,
     pos = 3, cex = 0.8, col = "blue")

# ---- VIFs ----
vif(final_fit)

# ---- Studentized residuals over 3 ----
which(abs(studres(final_fit)) > 3)

# ---- Top 5 Cook's distance values ----
head(sort(cd_final, decreasing = TRUE), 5)

# ==============================================================
# Step 8: Results — Confidence Intervals and Prediction Example
# ==============================================================

# ---- Confidence intervals for each coefficient ----
confint(final_fit, level = 0.95)

# ---- Mean values of continuous predictors (used for the worked prediction) ----
mean(jax_clean$GrossSF)
mean(jax_clean$Age2020)

# ---- Worked-example prediction: an "average" non-townhouse, no-pool home ----
# Predict SalePrice for a home with mean GrossSF, mean Age2020, 
# no townhouse, no pool — this will be our "baseline" home.

baseline <- data.frame(
  GrossSF   = mean(jax_clean$GrossSF),
  Age2020   = mean(jax_clean$Age2020),
  Townhouse = factor("N", levels = c("N","Y")),
  Pool      = factor("N", levels = c("N","Y"))
)

predict(final_fit, newdata = baseline, interval = "confidence", level = 0.95)
predict(final_fit, newdata = baseline, interval = "prediction", level = 0.95)

# ---- Same baseline home but WITH a pool ----
baseline_pool <- baseline
baseline_pool$Pool <- factor("Y", levels = c("N","Y"))
predict(final_fit, newdata = baseline_pool, interval = "confidence", level = 0.95)

# ---- A townhouse with otherwise average characteristics ----
baseline_th <- baseline
baseline_th$Townhouse <- factor("Y", levels = c("N","Y"))
predict(final_fit, newdata = baseline_th, interval = "confidence", level = 0.95)

# ---- Summary of the final model (for reporting coefficient table) ----
summary(final_fit)
