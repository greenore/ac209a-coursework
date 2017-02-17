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

# set up the cross-validated hyper-parameter search
xgb_grid_1 = expand.grid(
  nrounds = 100,
  eta = c(0.1, 0.3),                              # Step size srinkage used to prevent overfitting [0, 1] --> default: 0.3
  max_depth = c(6),                               # Maximum depth of a tree [1, inf] --> default: 6
  gamma = c(1),                                   # Minimum loss reduction [0, inf] --> default: 0
  colsample_bytree = c(1),                        # Subsample ratio of columns when constructin each tree (0, 1] --> default 1
  min_child_weight = c(0.9)                       # Minimum sum of instance weight needed in a child [0, inf] --> default 1
)

# pack the training control parameters
xgb_trcontrol_1 = trainControl(
  method = "cv",
  number = 5,
  verboseIter = TRUE,
  returnData = FALSE,
  returnResamp = "all",                                                        # save losses across all models
  classProbs = TRUE,                                                           # set to TRUE for AUC to be computed
  summaryFunction = twoClassSummary,
  allowParallel = TRUE
)

#   using CV to evaluate
df_train$Y <- factor(df_train$Y, labels=c("none", "cancer"))    # Necessary for caret

## Train the model
xgb_train_1 = train(
  x = as.matrix(df_train %>%
                  select(-Y)),
  y = df_train$Y,
  trControl = xgb_trcontrol_1,
  tuneGrid = xgb_grid_1,
  method = "xgbTree",
  metric = "ROC"
)
"AUROC"


preds = predict(xgb_train_1$finalModel, data.matrix(df_test))

df_test$Y

xgb_train_1$finalModel

results
xgb_train_1$results[xgb_train_1$results$ROC == max(xgb_train_1$results$ROC), ]



# xgboost fitting with arbitrary parameters
xgb_params_1 = list(
  colsample_bytree = 1,
  min_child_weight = 0.9,
  gamma = 1,
  objective = "binary:logistic",                                               # binary classification
  eta = 0.1,                                                                  # learning rate
  max.depth = 6,                                                               # max tree depth
  eval_metric = "auc"                                                          # evaluation/loss metric
)


df_train$Y <- as.numeric(df_train$Y) - 1

# fit the model with the fitted parameters specified above
xgb_1 = xgboost(data = as.matrix(df_train %>%
                                   select(-Y)),
                label = df_train$Y,
                nrounds = 200,
                params = xgb_params_1,
                verbose = TRUE,                                         
                print_every_n = 1,
                early_stopping_rounds = 10                                          # stop if no improvement within 10 trees
)

preds = predict(xgb_1, data.matrix(df_test))
label = round(preds)

N
table(df_test$Y, label)





# Predictions
preds = predict(xgb_1, data.matrix(df_x_final))
label = round(preds)
df_sub <- data.frame(1:length(label), label)
names(df_sub) <- c('index', 'label')
write_csv(format(df_sub, digits=0), path = "data/submission.txt")

