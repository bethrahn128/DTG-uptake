library(tidyverse)

# toy
data <- tibble(ID = c(1, 2, 3), 
               text = c("3TC ABC DTG", "3TC DTG ABC", "DTG 3TC TDF DTG"))

data %>% 
  tidyr::separate_rows(text, sep = " ") %>% 
  group_by(ID) %>% 
  arrange(text) %>% 
  summarise(text = paste(text, collapse = " "))

# real 
tblART_end <- fst::read_fst("data/tblART_end.feather")

graph <- tblART_end %>%
  filter(patient %in% c("AFA0928099")) %>% 
  mutate(art_ed = if_else(is.na(art_ed),
                          as.Date("2020-09-30"), art_ed)) %>% 
  mutate(x = row_number())

ggplot(graph) +
  geom_linerange(mapping = aes(x = trt, 
                               ymin = art_sd, ymax = art_ed)) +
  coord_flip() + 
  xlab("Medication")

ggplot(graph) +
  geom_linerange(mapping = aes(x = factor(trt_order), 
                               ymin = art_sd, ymax = art_ed)) +
  coord_flip() + 
  scale_x_discrete(label = as.character(graph$trt)) + 
  xlab("Medication")

# funky! large amount of meds, times without neds too
graph <- tblART_end %>%
  filter(patient %in% c("TLTC027729")) %>% 
  mutate(art_ed = if_else(is.na(art_ed),
                          as.Date("2020-09-30"), art_ed)) %>% 
  mutate(x = row_number())

ggplot(graph) +
  geom_linerange(mapping = aes(x = trt, 
                               ymin = art_sd, ymax = art_ed)) +
  coord_flip() + 
  xlab("Medication")

ggplot(graph) +
  geom_linerange(mapping = aes(x = factor(trt_order), 
                               ymin = art_sd, ymax = art_ed)) +
  coord_flip() + 
  scale_x_discrete(label = as.character(graph$trt)) + 
  xlab("Medication")

# would have to check if only last treatment is NA on end date !!!
data <- tblART_end %>%
  filter(patient %in% c("AFA1149190", "AFA0928099", "AFA0814630", "AFA0800630"))  %>%
  # filter(patient == "AFA0928099")  %>%
  # filter(patient == "AFA0800630")  %>%
  select(patient, art_sd, art_ed, trt, trt_order) %>% 
  group_by(patient) %>% 
  mutate(temp = max(trt_order)) %>% 
  ungroup() %>% 
  mutate(art_ed = if_else(is.na(art_ed) & temp == trt_order,
                          as.Date("2020-09-30"), art_ed)) %>% 
  mutate(art_ed = if_else(is.na(art_ed),
                          as.Date("2020-09-30"), art_ed)) %>% 
  mutate(duration = as.numeric(art_ed - art_sd)) %>% 
  select(-trt_order, -temp)

data_exp <- data %>%
  group_by(patient, art_sd ,art_ed ,trt, duration) %>% 
  summarize(start = min(art_sd), end = max(art_ed)) %>%
  do(data.frame(art_sd_new = seq(.$start, .$end, by = "1 day"))) %>% 
  ungroup() %>% 
  mutate(art_ed_new = art_sd_new + 1)

# nrow(data_exp) == sum(data$duration)

data_agg1 <- data_exp %>% 
  group_by(patient, art_sd_new, art_ed_new) %>% 
  summarize(trt_corr = paste0(trt, collapse = " ")) %>% 
  ungroup() %>% 
  distinct() %>%
  tidyr::separate_rows(trt_corr, sep = " ") %>% 
  group_by(patient, art_sd_new, art_ed_new) %>% 
  arrange(trt_corr) %>% 
  summarise(trt_corr = paste(trt_corr, collapse = " ")) %>% 
  ungroup() %>% 
  distinct() %>%
  arrange(patient, art_sd_new)

data_agg2 <- data_exp %>% 
  group_by(patient, art_sd_new, art_ed_new) %>% 
  summarize(trt_corr = paste0(trt, collapse = " ")) %>% 
  ungroup() %>% 
  distinct() %>%
  tidyr::separate_rows(trt_corr, sep = " ") %>% 
  mutate(trt_corr = strsplit(trt_corr, " ")
         %>% map(sort) %>% 
           map(unique) %>% 
           map_chr(paste, collapse = " ")) %>% 
  distinct() %>%
  arrange(patient, art_sd_new)

data_agg3 <- merge(data_exp,
                   aggregate(text ~ patient, data, function(x){
                     paste(sort(unique(unlist(strsplit(x, " ")))), 
                           collapse = " ")}), by = "patient")

identical(data_agg1, data_agg2)

library(microbenchmark)

mbm <- microbenchmark(
  
  solution1 = data_exp %>% 
    group_by(patient, art_sd_new, art_ed_new) %>% 
    summarize(trt_corr = paste0(trt, collapse = " ")) %>% 
    ungroup() %>% 
    distinct() %>%
    tidyr::separate_rows(trt_corr, sep = " ") %>% 
    group_by(patient, art_sd_new, art_ed_new) %>% 
    arrange(trt_corr) %>% 
    summarise(trt_corr = paste(trt_corr, collapse = " ")) %>% 
    ungroup() %>% 
    distinct() %>%
    arrange(patient, art_sd_new),
  
  solution2 =  data_exp %>% 
    group_by(patient, art_sd_new, art_ed_new) %>% 
    summarize(trt_corr = paste0(trt, collapse = " ")) %>% 
    ungroup() %>% 
    distinct() %>%
    tidyr::separate_rows(trt_corr, sep = " ") %>% 
    mutate(trt_corr = strsplit(trt_corr, " ")
           %>% map(sort) %>% 
             map(unique) %>% 
             map_chr(paste, collapse = " ")) %>% 
    distinct() %>%
    arrange(patient, art_sd_new)
  )

mbm 



