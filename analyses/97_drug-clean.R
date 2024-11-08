library(data.table)
data <- data.table(ID = c(1, 2),
                   text = c("3TC ABC DTG", "3TC DTG ABC"))

# `3TC ABC DTG`
data[, c("text1", "text2", "text3") := tstrsplit(text, " ", fixed = TRUE)]

# reshaping
data_long <- melt(data, 
                  id.vars = c("ID"),
                  measure.vars =  c("text1", "text2", "text3"), 
                  na.rm = TRUE)

result <- dcast(data,
                ID ~ variable,
                function (x) paste(x, collapse = " "))

# https://stackoverflow.com/questions/66553021/how-can-i-sort-words-of-variable-in-r-data-table
data[, text_new := lapply( strsplit( text, " " ), function(x) paste0( sort(x), collapse = " ")) ]
str(data)
data[, text_new := as.character(text_new)]
