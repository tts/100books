library(tidyverse)
library(rvest)

# Copy innerHTML with browser dev tools, and add root
html <- read_html("100kirjaa.html")

rank <- html %>% 
  html_nodes(xpath = "//h2[@data-v-e9338603]") %>% 
  html_text()

author_raw <- html %>% 
  html_nodes(xpath = "//p[@class='book-author'][1]") %>% 
  html_text() %>% 
  iconv(from = "UTF-8", to = "ISO-8859-1")

title <- html %>% 
  html_nodes(xpath = "//h3[@data-v-e9338603]") %>% 
  html_text() %>% 
  iconv(from = "UTF-8", to = "ISO-8859-1")

data <- data.frame(rank, author_raw, title)

raw <- data %>% 
  mutate(author = str_extract(author_raw, "^([^\\,]+)"),
         year = str_extract(author_raw, "\\,\\s([^\\s]+)", group = 1),
         publ = str_extract(author_raw, "\\(([^\\)]+)\\)", group = 1))

# Few exceptions
raw[7,]$year <- "2013"
raw[7,]$publ <- "Otava"
raw[27,]$year <- "2015"
raw[27,]$publ <- "Tammi"
raw[62,]$year <- "2004"
raw[62,]$publ <- "Otava"
raw[88,]$author <- "Rosa Liksom"

raw_split_names <- raw %>% 
  mutate(surname = str_extract(author, "^([^\\s]+)\\s([^\\s]+)", group = 2),
         givenname = str_extract(author, "^([^\\s]+)\\s([^\\s]+)", group = 1))

raw_split_names[11,]$surname <- "Hirvonen"
raw_split_names[11,]$givenname <- "Iida Sofia"
raw_split_names[49,]$surname <- "Jääskeläinen"
raw_split_names[49,]$givenname <- "Pasi Ilmari"

books <- raw_split_names %>% 
  select(rank, surname, givenname, title, year, publ) %>% 
  arrange(surname)

# Merge with sentences downloaded from GDrive
text_drive <- read_csv("Ekat lauseet - Sheet1.csv", 
                 col_names = c("rank", "surname", "givenname", "title", "year", "publ", "text"), 
                 col_types = c("c", "c", "c,", "c", "d", "c", "c"),
                 skip = 1)
text <- text_drive %>% 
  mutate(year = as.character(year))

books_text <- left_join(books, text, by = "title") %>% 
  select(ends_with(".x"), text) %>% 
  rename(rank = rank.x,
         surname = surname.x,
         givenname = givenname.x,
         year = year.x,
         publ = publ.x)

write_csv(books_text, "kirjat.csv")
