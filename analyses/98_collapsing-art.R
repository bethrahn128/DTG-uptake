library(data.table)
data <- data.table(ID = c(1, 1, 
                          2, 2, 
                          3, 3), 
                   start = anytime::anydate(c("2009-12-01", "2009-12-15", 
                                              "2009-12-01", "2009-12-15", 
                                              "2009-12-01", "2009-12-10")), 
                   end = anytime::anydate(c("2009-12-14", "2009-12-31", 
                                            "2009-12-15", NA, 
                                            "2009-12-15", "2009-12-31")), 
                   treatment = c("A", "A",
                                 "B", "B",
                                 "A","B"))

result <- data.table(ID = c(1, 
                            2, 
                            3, 3), 
                     start = anytime::anydate(c("2009-12-01", 
                                                "2009-12-01", 
                                                "2009-12-01", "2009-12-10")), 
                     end = anytime::anydate(c("2009-12-31", 
                                              NA, 
                                              "2009-12-15", "2009-12-31")), 
                     treatment = c("A",
                                   "B",
                                   "A","B"))

# test
setorder(data, ID, start, end, na.last = FALSE)

data[, start2 := min(start), by = list(ID, treatment)]
data[, end2 := max(end), by = list(ID, treatment)]

unique(data, by = c("ID", "start2", "end2", "treatment"))

# https://stackoverflow.com/questions/66458588/how-can-i-conditionally-collapse-groups-of-records-in-r-data-table

# stack 1
data[, .(start = min(start), 
         end = max(end), 
         treatment = first(treatment), 
         ID = first(ID)), 
     rleid(treatment)]

# stack 2
data[, .(start = min(start), 
         end = max(end)), 
     by = .(ID, treatment)][, .(ID, start, end, treatment)]
