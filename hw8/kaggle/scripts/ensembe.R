## Split dataset into test and train
set.seed(123)
sample_id <- sample(row.names(df_test), size = nrow(df_test) * 0.5, replace = FALSE)

df_train_new <- df_test[row.names(df_test) %in% sample_id, ]
df_test_new <- df_test[!row.names(df_test) %in% sample_id, ]


## Ensemble

# RF
df_train_new$rf_pred <- as.numeric(predict(rf, data.matrix(df_train_new[, 2:length(df_train_new)]))$predictions) - 1
df_test_new$rf_pred <- as.numeric(predict(rf, data.matrix(df_test_new[, 2:length(df_test_new)]))$predictions) - 1
df_x_final$rf_pred <- as.numeric(predict(rf, data.matrix(df_x_final))$predictions) - 1

#XGBOOST
df_train_new$bst_pred <- predict(bst, data.matrix(df_train_new %>% select(-Y, -rf_pred)))
df_test_new$bst_pred <- predict(bst, data.matrix(df_test_new %>% select(-Y, -rf_pred)))
df_x_final$bst_pred <- predict(bst, data.matrix(df_x_final))

###########################
param <- list("objective" = "binary:logistic",    # multiclass classification 
              "max_depth" = 6,    # maximum depth of tree 
              "eta" = 0.5,    # step size shrinkage 
              "gamma" = 0,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 0.01  # minimum sum of instance weight needed in a child 
)


# set random seed, for reproducibility 
set.seed(1234)
bst.cv2 <- xgb.cv(param=param,
                  data = as.matrix(df_train_new %>%
                                     select(-Y)),
                  label = df_train_new$Y,
                  nfold=5,
                  nrounds=50,
                  prediction=TRUE,
                  verbose=FALSE)

min.error.idx <- (1:length(bst.cv2$evaluation_log$test_error_mean))[bst.cv2$evaluation_log$test_error_mean == min(bst.cv2$evaluation_log$test_error_mean)]

# Testing
#--------
bst2 <- xgboost(param=param,
                data=as.matrix(df_train_new %>% select(-Y)),
                label=df_train_new$Y, 
                nrounds=min.error.idx,
                verbose=0)

# Predictions
preds = predict(bst2, data.matrix(df_test_new[, 2:length(df_test_new)]))
label = round(preds)
table(df_test_new$Y, label)



library(ranger)

# Modelling
set.seed(1234)
df_train_new$Y <- as.factor(df_train_new$Y)

rf <- ranger(Y ~ ., df_train_new)

# Predictions
preds = predict(rf, data.matrix(df_test_new[, 2:length(df_test_new)]))
label = preds$predictions
table(df_test_new$Y, label)


?ranger
