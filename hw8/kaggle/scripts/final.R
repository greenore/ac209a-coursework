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
              "gamma" = 2,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 0.8,  # minimum sum of instance weight needed in a child
              "scale_pos_weight" = 45,
              "max_delta_step" = 0
)

bst_model <- xgboost(param=param,
                     data=as.matrix(df_train %>% select(-Y)),
                     label=df_train$Y, 
                     nrounds=min.error.idx,
                     verbose=0)

# prediction
bst_pred_train <- predict(bst_model, data.matrix(df_train[, 2:length(df_train)]), type="prob")
bst_pred_test <- predict(bst_model, data.matrix(df_test[, 2:length(df_test)]), type="prob")
bst_pred_df <- predict(bst_model, data.matrix(df[, 2:length(df)]), type="prob")
bst_pred_fin <- predict(bst_model, data.matrix(df_x_final), type="prob")

bst_conf_matr <- table(df_test$Y, round(bst_pred_test))

saveRDS(bst_model, "models/bst_model.rds")

# randomforest
#-------------
df_train$Y <- as.factor(df_train$Y)
df_test$Y <- as.factor(df_test$Y)

rf_model <- ranger(Y ~ ., df_train, probability=TRUE)

# prediction
rf_pred_train <- predict(rf_model, data.matrix(df_train[, 2:length(df_train)]))$predictions[, 2]
rf_pred_test <- predict(rf_model, data.matrix(df_test[, 2:length(df_test)]))$predictions[, 2]
rf_pred_df <- predict(rf_model, data.matrix(df[, 2:length(df)]))$predictions[, 2]
rf_pred_fin <- predict(rf_model, data.matrix(df_x_final))$predictions[, 2]

rf_conf_matr <- table(df_test$Y, round(rf_pred_test))

saveRDS(rf_model, "models/rf_model.rds")

# SVM
#----
svm_model <- svm(Y ~ ., data=df_train, probability=TRUE)

# prediction
svm_pred_train <- predict(svm_model, data.matrix(df_train[, 2:length(df_train)]), probability=TRUE, decision.values=FALSE)
svm_pred_train <- data.frame(attr(svm_pred_train, "prob"))$X1
svm_pred_test <- predict(svm_model, data.matrix(df_test[, 2:length(df_test)]), probability=TRUE, decision.values=FALSE)
svm_pred_test <- data.frame(attr(svm_pred_test, "prob"))$X1
svm_pred_df <- predict(svm_model, data.matrix(df[, 2:length(df)]), probability=TRUE, decision.values=FALSE)
svm_pred_df <- data.frame(attr(svm_pred_df, "prob"))$X1
svm_pred_fin <- predict(svm_model, data.matrix(df_x_final), probability=TRUE, decision.values=FALSE)
svm_pred_fin <- data.frame(attr(svm_pred_fin, "prob"))$X1

svm_conf_matr <- table(df_test$Y, round(svm_pred_test))

saveRDS(svm_model, "models/svm_model.rds")

# Ensemble
#---------
df_train_ens <- data.frame(df_train$Y, bst_pred_train, rf_pred_train, svm_pred_train)
df_test_ens <- data.frame(df_test$Y, bst_pred_test, rf_pred_test, svm_pred_test)
df_df_ens <- data.frame(df$Y, bst_pred_df, rf_pred_df, svm_pred_df)
df_fin_ens <- data.frame(bst_pred_fin, rf_pred_fin, svm_pred_fin)

names(df_train_ens) <- c("Y", "bst_pred", "rf_pred", "svm_pred") 
names(df_test_ens) <- c("Y", "bst_pred", "rf_pred", "svm_pred") 
names(df_df_ens) <- c("Y", "bst_pred", "rf_pred", "svm_pred") 
names(df_fin_ens) <- c("bst_pred", "rf_pred", "svm_pred") 

df_train_ens$Y <- as.factor(df_train_ens$Y)
df_test_ens$Y <- as.factor(df_test_ens$Y)

# C50 ensemble
# cross-validation, 10-fold
fitControl <- trainControl(method = "repeatedcv",
                           number = 10,
                           repeats = 10, returnResamp="all")

# Choose the features and classes
grid <- expand.grid(.winnow = c(TRUE,FALSE), .trials=c(1,5,10,15,20), .model="tree")
grid <- expand.grid(.winnow = c(TRUE), .trials=c(1), .model="tree")

ens_model_cv <- train(Y ~ .,
                      data=df_train_ens,
                      tuneGrid=grid,
                      trControl=fitControl,
                      method="C5.0",
                      verbose=FALSE)
names(df_train_ens)

ens_model <- ens_model_cv$finalModel
pred <- predict(ens_model, newdata=df_test_ens)

ens_conf_matr <- table(df_test_ens$Y, pred)



df_train_ens$Y <- as.numeric(df_train_ens$Y) - 1


param <- list("objective" = "binary:logistic",    # multiclass classification 
              "max_depth" = 6    # maximum depth of tree 
)
param <- list("objective" = "binary:logistic",    # multiclass classification 
              "max_depth" = 6,    # maximum depth of tree 
              "eta" = 0.5,    # step size shrinkage 
              "gamma" = 2,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 0.8,  # minimum sum of instance weight needed in a child
              "scale_pos_weight" = 45,
              "max_delta_step" = 0
)

ifelse(df_train_ens$bst_pred <= 0.5, )
table(df_train_ens$Y == 1)

df_train_ens[df_train_ens$Y == 1 & df_train_ens$bst_pred <= 0.5, ]
ens_model <- xgboost(param=param,
                     data=as.matrix(df_train_ens[, 2:length(df_train_ens)]),
                     label=df_train_ens$Y, 
                     nrounds=200,
                     "eta" = 0.01,    # step size shrinkage 
                     verbose=0)
pred <- predict(ens_model, newdata=as.matrix(df_test_ens[, 2:length(df_test_ens)]))
ens_conf_matr <- table(df_test_ens$Y, round(pred))
ens_conf_matr


bst_conf_matr <- table(df_train_ens$Y, ifelse(df_train_ens$bst_pred >= 0.5, 1, 0))


# Evaluation
#-----------
evalFun <- function(conf_matr){
  p <- conf_matr[4] / (conf_matr[4] + conf_matr[3])
  r <- conf_matr[4] / (conf_matr[4] + conf_matr[2])
  
  F1 <- 2 * (p * r) / (p + r)
  F1
}


evalFun(bst_conf_matr)
evalFun(rf_conf_matr)
evalFun(svm_conf_matr)
evalFun(ens_conf_matr)





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

