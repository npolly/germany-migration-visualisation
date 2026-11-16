# loading required packages
library(ggplot2)
library(dplyr)
library(ggtext) # for the html tags in text

# loading data 
temp_env <- new.env()
loaded_names <- load("data.RData", envir = temp_env)
my_data <- temp_env[[loaded_names[1]]]

# rename the first three columns
colnames(my_data)[1:3] <- c("year", "population", "migration_rate")

# make sure the columns are numbers
my_data$year <- as.numeric(my_data$year)
my_data$population <- as.numeric(my_data$population)
my_data$migration_rate <- as.numeric(my_data$migration_rate)

# remove missing years and put the data in order
my_data <- my_data |> 
  filter(!is.na(year)) |> 
  arrange(year)

# change population to millions if needed
if (max(my_data$population, na.rm = TRUE) > 1000000) {
  my_data$population <- my_data$population / 1000000
}

# these are the periods where the line should be grey
grey_periods <- my_data |> 
  filter(year <= 1952 |
      (year >= 1973 & year <= 1984) |
      (year >= 2000 & year <= 2007)) |> 
  mutate(grey_group = case_when(
      year <= 1952 ~ 1,
      year >= 1973 & year <= 1984 ~ 2,
      year >= 2000 & year <= 2007 ~ 3
    )
  )

# years that need labels
key_years <- c(1950, 1973, 1980, 1984, 1991, 2000, 2007, 2016, 2022)

labels_data <- my_data |> 
  filter(year %in% key_years) |> 
  mutate(
    move_x = case_when(
      year == 1950 ~ 0.45,
      year == 1984 ~ -0.35,
      year == 1973 ~ 0.35,
      year == 2007 ~ -0.35,
      year == 2000 ~ 0.35,
      TRUE ~ 0
    ),
    move_y = case_when(
      year == 1950 ~ 0,
      year == 1973 ~ -0.1,
      year == 1980 ~ -0.5,
      year == 1984 ~ 0,
      year == 1991 ~ 0.5,
      year == 2000 ~ 0,
      year == 2007 ~ 0,
      year == 2016 ~ 0.5,
      year == 2022 ~ -0.5,
      TRUE ~ 0.35
    )
  )

# the grey dots
grey_highlight_years <- c(1950, 1980, 2000, 2007)

# keep the same year colours for the whole graph
min_yr <- min(my_data$year)
max_yr <- max(my_data$year)

# start making the graph
final_plot <- ggplot(
  my_data, aes(x = population, y = migration_rate)) +
  
# add the zero line
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.5) +
  
# draw the main line with colours changing over time
  geom_path(aes(color = year), linewidth = 2.5, alpha = 0.35) +
  
# draw the grey parts without connecting separate periods
  geom_path(data = grey_periods, aes(group = grey_group),
    color = "grey65",linewidth = 2.5) +
  
  # add the small dots along the line
  geom_point(aes(color = year),size = 1.2) +
  
  # make the small dots in the grey periods grey too
  geom_point(data = grey_periods, color = "grey55", size = 1.25) +
  
  # add the bigger dots for the labelled years
  geom_point(data = filter(labels_data, !year %in% grey_highlight_years),
    aes(fill = year),
    shape = 21,
    color = "black",
    size = 2.2,
    stroke = 0.6
  ) +
  
  # these highlighted years have grey dots instead
  geom_point(
    data = filter(labels_data, year %in% grey_highlight_years),
    fill = "grey55", shape = 21, color = "black", size = 2.2, stroke = 0.6) +
  
  # put the year labels next to the dots
  geom_text(
    data = labels_data,
    aes(x = population + move_x, y = migration_rate + move_y, label = year),
    size = 3.2, fontface = "bold", color = "#222222") +
  
  # colours from yellow to orange to pink
  scale_color_gradientn(colors = c("#f6d258", "#e27442", "#c2335b"),
    limits = c(min_yr, max_yr),
    guide = "none") +
  scale_fill_gradientn(colors = c("#f6d258", "#e27442", "#c2335b"),
    limits = c(min_yr, max_yr),
    guide = "none") +
  
  # set the x and y axes
  scale_x_continuous(breaks = seq(69, 84, by = 1),
    labels = function(x) paste0(x, "M"),
    limits = c(68, 84.5),
    expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(-12, 10, by = 2),
    limits = c(-12.5, 10.5),
    expand = c(0, 0)) +
  
  # add the title and source
  labs(
    title = "Germany's population growth has been driven by immigration",
    subtitle = paste(
      "In the postwar era, Germany has experienced three periods",
      "of population growth. Only the first was significantly driven by births."
    ),
    x = "",
    y = "",
    caption = paste0(
      "Population based on Germany's current borders<br>",
      "Chart: Luc Guillemot • Source: United Nations"
    )) +
  
  # labels inside the graph
  annotate("text", x = 68.1, y = 10, label = "Net migration rate",
    fontface = "bold", hjust = 0,
    size = 3.3, color = "grey40") +
  annotate("text", x = 84.3, y = -12, label = "Total population",
    fontface = "bold", hjust = 1, size = 3.3, color = "grey40") +
  
  # explain what positive and negative migration mean
  annotate("text", x = 68.1, y = 1.5, 
    label = "▲\nMore immigration\nthan emigration",
    size = 2.2, hjust = 0, color = "#555555") +
  annotate("text", x = 68.1, y = -1.5,
    label = "More emigration\nthan immigration\n▼",
    size = 2.2, hjust = 0, color = "#555555") +
  
  # show the direction of the line
  annotate("richtext", x = 71.3, y = -4.5, 
    label = "**Time follows<br>the line**",size = 2.8, hjust = 0,
    fill = NA, label.color = NA) +
  annotate("point", x = 71.3, y = -3.9, shape = 17, size = 1.2) +
  
  # explain the first part of the graph
  annotate("richtext", x = 69.5, y = -7.5,
    label = "Immigration<br>increases<br>dramatically<br>post WWII",
    size = 2.2, hjust = 0.5, color = "#555555", fill = NA, label.color = NA) +
  annotate("segment", x = 70.3, y = -7.5, xend = 70.9, yend = -7.5,
    color = "#888888", linewidth = 0.3) +
  
  # explain population growth during the economic miracle
  annotate("richtext", x = 72, y = 5.5,
    label = paste0(
      "During the \"economic miracle,\" millions of<br>",
      "**guest workers** come to Germany.<br>",
      "The **fertility rate is also still high**, which explains<br>",
      "this dramatic population growth."),
    size = 2.2, hjust = 0, color = "#555555",fill = NA, label.color = NA) +
  
  annotate("segment", x = 73, y = 4,
    xend = 73, yend = 1.5, color = "#888888", linewidth = 0.3) +
  
  # explain the decline between 1973 and 1980
  annotate("richtext", x = 78.5, y = -5,
    label = paste0(
      "Between 1973 and 1980, the world is in crisis.<br>",
      "Immigration slows and the population declines.<br>",
      "In the 1970s, Germany passes **family reunification**<br>",
      "**laws**, which help to restart immigration."),
    size = 2.2, hjust = 0.5,
    color = "#555555", fill = NA, label.color = NA) +
  
  annotate("segment", x = 78.5, y = -3.5,
    xend = 78.5, yend = -0.5, color = "#888888", linewidth = 0.3) +
  
  # explain growth before reunification
  annotate("richtext", x = 78, y = 8.5,
    label = paste0(
      "Immigration drives renewed<br>",
      "population growth in the<br>",
      "years leading up to<br>",
      "German reunification."),
    size = 2.2, hjust = 0.5,
    color = "#555555",
    fill = NA, label.color = NA) +
  
  annotate("segment", x = 78, y = 7.2, xend = 78, yend = 5.5,
    color = "#888888", linewidth = 0.3) +
  
  # explain the growth after the eu expanded
  annotate("richtext", x = 81.5, y = 8.5,
    label = paste0(
      "After the **expansion of the EU** in the 2000s,<br>",
      "many Eastern Europeans migrate to Germany,<br>",
      "mainly from Poland and Romania."),
    size = 2.2, hjust = 0.5,
    color = "#555555", fill = NA, label.color = NA) +
 
  annotate("segment", x = 81.5, y = 7.2,
    xend = 81.5, yend = 4.5,color = "#888888", linewidth = 0.3) +
  
  # keep the graph clean and adjust the text
  theme_minimal() +
  theme(
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "grey30", linewidth = 0.4),
    axis.text = element_text(size = 10, color = "grey40"),
    plot.title = element_text(
      size = 17, face = "bold",
      margin = margin(b = 6)
    ),
    plot.subtitle = element_text(
      size = 11.5,
      margin = margin(b = 20)
    ),
    plot.caption = element_markdown(
      hjust = 0,
      lineheight = 1.5,
      margin = margin(t = 18)
    ),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.margin = margin(15, 15, 15, 15)
  )

# show the graph
print(final_plot)

# save the graph 
ggsave(
  "output.png",
  plot = final_plot,
  width = 12.4,
  height = 8.8,
  dpi = 200,
  units = "in",
  bg = "white"
)