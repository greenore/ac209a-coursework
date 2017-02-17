## Creat Environment
if (any(search() %in% "projEnvironment")) detach("projEnvironment")
projEnvironment <- new.env()

## Get the class of variables in a dataframe
projEnvironment$getVarClass <- function(data){
  vec <- sapply(data, class)
  df.class <- data.frame(var_name = names(vec), class_long = as.character(vec), 
                         class_short = substr(as.character(vec), 1, 1), stringsAsFactors = FALSE)
  df.class
}

## Sanitas colors
projEnvironment$sanCol <- function(col = NULL, alpha = 255){
  df.col <- list()
  df.col$green1 <- rgb(0, 118, 90, alpha = alpha, maxColorValue = 255)
  df.col$green2 <- rgb(91, 172, 38, alpha = alpha, maxColorValue = 255)
  df.col$green3 <- rgb(148, 191, 59, alpha = alpha, maxColorValue = 255)
  df.col$green4 <- rgb(0, 78, 70, alpha = alpha, maxColorValue = 255)
  df.col$green5 <- rgb(0, 116, 117, alpha = alpha, maxColorValue = 255)
  df.col$black <- rgb(0, 0, 0, alpha = alpha, maxColorValue = 255)
  df.col$grey <- rgb(155, 155, 155, alpha = alpha, maxColorValue = 255)
  if (is.null(col)) {
    as.character(unlist(df.col))
  } else {
    df.col[col]
  }
}

attach(projEnvironment)
rm(projEnvironment)
