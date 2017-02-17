## Clear Workspace
rm(list=ls())

## Load libraries
library(caret)
library(xgboost)
library(readr)
library(dplyr)
library(tidyr)

## Data
df_x <- read_csv("data/train_predictors.txt", col_names = FALSE)
df_y <- read_csv("data/train_labels.txt", col_names = FALSE)
df_x_final <- read_csv("data/test_predictors.txt", col_names = FALSE)

df_sub <- data.frame(read_csv("data/sample_submission.txt", col_names = TRUE))

df_x <- data.frame(df_x)
df_y <- data.frame(df_y)
df_x_final <- data.frame(df_x_final)
names(df_y) <- "Y"

# Bind together
df <- cbind(df_y, df_x)

rm(df_x, df_y)

# Feature engeneering
#--------------------
# svm_model <- readRDS("models/svm_model.rds")
# rf_model <- readRDS("models/rf_model.rds")
# 
# svm_pred_train <- predict(svm_model, data.matrix(df[, 2:length(df)]), probability=TRUE, decision.values=FALSE)
# svm_pred_train <- data.frame(attr(svm_pred_train, "prob"))$X1
# svm_pred_train <- data.frame(attr(svm_pred_train, "prob"))$X1
# svm_pred_fin <- predict(svm_model, data.matrix(df_x_final), probability=TRUE, decision.values=FALSE)
# svm_pred_fin <- data.frame(attr(svm_pred_fin, "prob"))$X1
# df$svm <- svm_pred_train
# df_x_final$svm <- svm_pred_fin

rf_pred_df <- predict(rf_model, data.matrix(df[, 2:length(df)]))$predictions[, 2]
rf_pred_fin <- predict(rf_model, data.matrix(df_x_final))$predictions[, 2]
df$rf <- rf_pred_df
df_x_final$rf <- rf_pred_fin

## Split dataset into test and train
set.seed(123)
sample_id <- sample(row.names(df), size = nrow(df) * 0.8, replace = FALSE)

df_train <- df[row.names(df) %in% sample_id, ]
df_test <- df[!row.names(df) %in% sample_id, ]

# Omit missings
df_train <- na.omit(df_train)

## Tuning

# num.class = length(unique(y))
# xgboost parameters
param <- list("objective" = "binary:logistic",    # multiclass classification 
              "max_depth" = 6,    # maximum depth of tree 
              "eta" = 0.5,    # step size shrinkage 
              "gamma" = 1.5,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 0.8,  # minimum sum of instance weight needed in a child
              "scale_pos_weight" = 50,
              "max_delta_step" = 0
)

set.seed(1234)

bst <- xgboost(param=param,
               data=as.matrix(df[, 2:length(df)]),
               label=df$Y, 
               nrounds=100,
               verbose=0)

# Evaluation
#-----------
evalFun <- function(conf_matr){
  p <- conf_matr[4] / (conf_matr[4] + conf_matr[3])
  r <- conf_matr[4] / (conf_matr[4] + conf_matr[2])
  
  F1 <- 2 * (p * r) / (p + r)
  F1
}

bst_pred_test <- predict(bst, data.matrix(df_test[, 2:length(df_test)]), type="prob")
bst_conf_matr <- table(df_test$Y, ifelse(bst_pred_test >= 0.5, 1, 0))
evalFun(bst_conf_matr)
bst_conf_matr





set.seed(1234)
bst.cv <- xgb.cv(param=param,
                 data = as.matrix(df[, 2:length(df)]),
                 label = df$Y,
                 nfold=5,
                 nrounds=60,
                 prediction=TRUE,
                 verbose=FALSE)

min.error.idx <- (1:length(bst.cv$evaluation_log$test_error_mean))[bst.cv$evaluation_log$test_error_mean == min(bst.cv$evaluation_log$test_error_mean)]


# set random seed, for reproducibility 
set.seed(12345)

min.error.idx <- 25
# Testing
#--------
bst <- xgboost(param=param,
               data=as.matrix(df[, 2:length(df)]),
               label=df$Y, 
               nrounds=min.error.idx,
               verbose=0)

importance <- xgb.importance(feature_names = names(df[, 2:length(df)]), model = bst)

# Predictions
preds = predict(bst, data.matrix(df_x_final))
label = ifelse(preds > 0.50, 1, 0)
df_sub <- data.frame(1:length(label), label)
names(df_sub) <- c('index', 'label')
write_csv(format(df_sub, digits=0), path = "data/submission.txt")








preds = predict(bst, data.matrix(df[, 2:length(df)]))
label = ifelse(preds > 0.5, 1, 0)
table(df$Y, label)
