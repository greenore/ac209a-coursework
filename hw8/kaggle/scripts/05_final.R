## Load libraries
library(caret)
library(xgboost)
library(readr)
library(dplyr)
library(tidyr)
library(ranger)
library(e1071)
library(C50)

# xgboost
#--------
min.error.idx <- 40

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

bst_model <- xgboost(param=param,
                     data=as.matrix(df_train[, 2:length(df_train)]),
                     label=df_train$Y, 
                     nrounds=min.error.idx,
                     verbose=0)

# prediction
bst_pred_train <- predict(bst_model, data.matrix(df_train[, 2:length(df_train)]), type="prob")
bst_pred_test <- predict(bst_model, data.matrix(df_test[, 2:length(df_test)]), type="prob")
bst_pred_df <- predict(bst_model, data.matrix(df[, 2:length(df)]), type="prob")
bst_pred_fin <- predict(bst_model, data.matrix(df_x_final), type="prob")

bst_conf_matr <- table(df_test$Y, ifelse(bst_pred_test >= 0.45, 1, 0))
evalFun(bst_conf_matr)

# Evaluation
#-----------
evalFun <- function(conf_matr){
  p <- conf_matr[4] / (conf_matr[4] + conf_matr[3])
  r <- conf_matr[4] / (conf_matr[4] + conf_matr[2])
  
  F1 <- 2 * (p * r) / (p + r)
  F1
}







# Predictions
label <- predict(ens_model, newdata=df_fin_ens)
df_sub <- data.frame(1:length(label), label)
names(df_sub) <- c('index', 'label')
write_csv(format(df_sub, digits=0), path = "data/submission.txt")



































#ens_model <- glm(Y ~ bst_pred + rf_pred + svm_pred, data=df_test_ens, family=binomial)

tc <- trainControl("cv", 10, savePredictions=TRUE) # cross-validation, 10-fold
ens_model_cv <- train(Y ~ .,
                      data=df_test_ens,
                      method="glm",
                      family=binomial,
                      trControl=tc)

ens_model <- ens_model_cv$finalModel

pred <- predict(ens_model, newdata=df_test_ens)

pred <- as.numeric(ifelse(pred < 0.5, 0, 1))
ens_conf_matr <- table(df_test$Y, pred)

