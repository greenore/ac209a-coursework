library(readr)
library(ranger)

# Data
df_x <- read_csv("data/train_predictors.txt", col_names = FALSE)
df_y <- read_csv("data/train_labels.txt", col_names = FALSE)
df_x_final <- read_csv("data/test_predictors.txt", col_names = FALSE)

df_x <- data.frame(df_x)
df_y <- data.frame(df_y)
df_x_final <- data.frame(df_x_final)

df <- cbind(df_y, df_x)

rm(df_x, df_y)
## Split dataset into test and train
set.seed(123)
sample_id <- sample(row.names(df), size = nrow(df) * 0.7, replace = FALSE)

df_train <- df[row.names(df) %in% sample_id, ]
df_test <- df[!row.names(df) %in% sample_id, ]

# Modelling
set.seed(1)
df_train$X1 <- as.factor(df_train$X1)
rf <- ranger(X1 ~ ., df_train)

# Full dataset
df$X1 <- as.factor(df$X1)
rf <- ranger(X1 ~ ., df)

# Prediction
preds <- predict(rf, df)
table(preds$predictions, df$X1)

preds <- predict(rf, df_x_final)
table(preds$predictions, df_test$X1)

# Write
label = preds$predictions
df_sub <- data.frame(1:length(label), label)
names(df_sub) <- c('index', 'label')
write_csv(format(df_sub, digits=0), path = "data/submission.txt")
