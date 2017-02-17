library(ranger)

# Modelling
set.seed(1234)
df_train$Y <- as.factor(df_train$Y)

rf <- ranger(Y ~ ., df_train)

# Predictions
preds = predict(rf, data.matrix(df_test[, 2:length(df_test)]))
label = preds$predictions
table(df_test$Y, label)
