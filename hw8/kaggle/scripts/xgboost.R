rm(list=ls())
# library(devtools)
# install.packages("drat", repos="https://cran.rstudio.com")
# drat:::addRepo("dmlc")
# install.packages("xgboost", repos="http://dmlc.ml/drat/", type = "source")
require(caret)
library(xgboost)
library(readr)

# Data
df_x <- read_csv("data/train_predictors.txt", col_names = FALSE)
df_y <- read_csv("data/train_labels.txt", col_names = FALSE)
df_x_final <- read_csv("data/test_predictors.txt", col_names = FALSE)

df_sub <- data.frame(read_csv("data/sample_submission.txt", col_names = TRUE))

df_x <- data.frame(df_x)
df_y <- data.frame(df_y)
df_x_final <- data.frame(df_x_final)

df <- cbind(df_y, df_x)

rm(df_x, df_y)

## Split dataset into test and train
set.seed(123)
sample_id <- sample(row.names(df), size = nrow(df) * 0.8, replace = FALSE)

df_train <- df[row.names(df) %in% sample_id, ]
df_test <- df[!row.names(df) %in% sample_id, ]

# Modeling
y <- df_train[, 1]
x <- data.matrix(df_train[, 2:length(df_train)])

# set up the cross-validated hyper-parameter search
xgb_grid_1 = expand.grid(
  nrounds = 1000,
  eta = c(0.01, 0.001, 0.0001),   # step size shrinkage 
  max_depth = c(2, 4, 6, 8, 10),
  gamma = 1,                      # minimum loss reduction 
  objective = "binary:logistic",  # Type of analysis
  subsample = 1,                  # part of data instances to grow tree 
  colsample_bytree = 1,           # subsample ratio of columns when constructing each tree 
  min_child_weight = 1            # minimum sum of instance weight needed in a child 
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



# set random seed, for reproducibility 
set.seed(1234)
system.time( bst.cv <- xgb.cv(param=param, data=x, label=y, 
                              nfold=5, nrounds=nround.cv, prediction=TRUE, verbose=FALSE) )


# train the model for each parameter combination in the grid,
#   using CV to evaluate
xgb_train_1 = train(
  x = x,
  y = y,
  trControl = xgb_trcontrol_1,
  tuneGrid = xgb_grid_1,
  method = "xgbTree"
)



min.error.idx <- (1:length(bst.cv$evaluation_log$test_error_mean))[bst.cv$evaluation_log$test_error_mean == min(bst.cv$evaluation_log$test_error_mean)]




# scatter plot of the AUC against max_depth and eta
ggplot(xgb_train_1$results, aes(x = as.factor(eta), y = max_depth, size = ROC, color = ROC)) +
  geom_point() +
  theme_bw() +
  scale_size_continuous(guide = "none")







# Preprozessing
#zero.var = nearZeroVar(df_train, saveMetrics=TRUE)
#zero.var

# num.class = length(unique(y))
# xgboost parameters
param <- list("objective" = "binary:logistic",    # multiclass classification 
              "nthread" = 8,   # number of threads to be used 
              "max_depth" = 16,    # maximum depth of tree 
              "eta" = 0.3,    # step size shrinkage 
              "gamma" = 0,    # minimum loss reduction 
              "subsample" = 1,    # part of data instances to grow tree 
              "colsample_bytree" = 1,  # subsample ratio of columns when constructing each tree 
              "min_child_weight" = 1  # minimum sum of instance weight needed in a child 
)


# set random seed, for reproducibility 
set.seed(1234)
# k-fold cross validation, with timing
nround.cv = 200

system.time( bst.cv <- xgb.cv(param=param, data=x, label=y, 
                              nfold=5, nrounds=nround.cv, prediction=TRUE, verbose=FALSE) )

min.error.idx <- (1:length(bst.cv$evaluation_log$test_error_mean))[bst.cv$evaluation_log$test_error_mean == min(bst.cv$evaluation_log$test_error_mean)]

# 39 at the moment

# Testing
#--------
system.time( bst <- xgboost(param=param, data=x, label=y, 
                            nrounds=min.error.idx, verbose=0) )

# Predictions
preds = predict(bst, data.matrix(df_test[, 2:length(df_test)]))
label = round(preds)
table(df_test$X1, label)


# Final
#------
system.time( bst2 <- xgboost(param=param, data=data.matrix(df[, 2:length(df)]), label=df[, 1], 
                            nrounds=min.error.idx, verbose=0) )


# Predictions
preds = predict(bst2, data.matrix(df_x_final))
label = round(preds)
df_sub <- data.frame(1:length(label), label)
names(df_sub) <- c('index', 'label')
write_csv(format(df_sub, digits=0), path = "data/submission.txt")


# Plot
# get the trained model
model = xgb.dump(bst2, with_stats=TRUE)
# get the feature real names
names = dimnames(data.matrix(df_x_final))[[2]]
# compute feature importance matrix
importance_matrix = xgb.importance(names, model=bst2)

# plot
gp = xgb.plot.importance(importance_matrix)
print(gp) 
n <- nrow(importance_matrix)
rem_features <- importance_matrix$Feature[(n-20):n]



df_train_2 <- df_train[, !(names(df_train) %in% rem_features)]
df_test_2 <- df_test[, !(names(df_test) %in% rem_features)]

x <- data.matrix(df_train_2[, 2:length(df_train_2)])

# Testing
#--------
system.time( bst <- xgboost(param=param, data=x, label=y, 
                            nrounds=min.error.idx, verbose=0) )

# Predictions
preds = predict(bst, data.matrix(df_test_2[, 2:length(df_test_2)]))
label = round(preds)
table(df_test_2$X1, label)

