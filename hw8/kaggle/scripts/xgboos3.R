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


# set random seed, for reproducibility 
set.seed(1234)
bst.cv <- xgb.cv(param=param,
                 data = as.matrix(df_train %>%
                                    select(-Y)),
                 label = df_train$Y,
                 nfold=5,
                 nrounds=50,
                 prediction=TRUE,
                 verbose=FALSE)

min.error.idx <- (1:length(bst.cv$evaluation_log$test_error_mean))[bst.cv$evaluation_log$test_error_mean == min(bst.cv$evaluation_log$test_error_mean)]

# min.error.idx == 40
# Testing
#--------
bst <- xgboost(param=param,
               data=as.matrix(df_train %>% select(-Y)),
               label=df_train$Y, 
               nrounds=min.error.idx,
               verbose=0)

# Predictions
preds = predict(bst, data.matrix(df_test[, 2:length(df_test)]))
label = round(preds)
table(df_test$Y, label)


# Predictions
preds = predict(bst, data.matrix(df_x_final))
label = round(preds)
df_sub <- data.frame(1:length(label), label)
names(df_sub) <- c('index', 'label')
write_csv(format(df_sub, digits=0), path = "data/submission.txt")


