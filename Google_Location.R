install.packages("jsonlite")
library(jsonlite)
library(ggplot2)

system.time(x <- fromJSON("C:/Users/Sinja/Desktop/Standortverlauf.json"))

# extracting the locations dataframe
loc = x$locations

# converting time column from posix milliseconds into a readable time scale
loc$time = as.POSIXct(as.numeric(x$locations$timestampMs)/1000, origin = "1970-01-01")

# converting longitude and latitude from E7 to GPS coordinates
loc$lat = loc$latitudeE7 / 1e7
loc$lon = loc$longitudeE7 / 1e7

head(loc)

# how many rows are in the data frame?
nrow(loc)

min(loc$time)
max(loc$time)

# calculate the number of data points per day, month and year
library(lubridate)
library(zoo)

loc$date <- as.Date(loc$time, '%Y/%m/%d')
loc$year <- year(loc$date)
loc$month_year <- as.yearmon(loc$date)

points_p_day <- data.frame(table(loc$date), group = "day")
points_p_month <- data.frame(table(loc$month_year), group = "month")
points_p_year <- data.frame(table(loc$year), group = "year")


# set up plotting theme
library(ggplot2)
library(ggmap)

my_theme <- function(base_size = 12, base_family = "sans"){
  theme_grey(base_size = base_size, base_family = base_family) +
    theme(
      axis.text = element_text(size = 12),
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      axis.title = element_text(size = 14),
      panel.grid.major = element_line(color = "grey"),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = "aliceblue"),
      strip.background = element_rect(fill = "lightgrey", color = "grey", size = 1),
      strip.text = element_text(face = "bold", size = 12, color = "navy"),
      legend.position = "right",
      legend.background = element_blank(),
      panel.margin = unit(.5, "lines"),
      panel.border = element_rect(color = "grey", fill = NA, size = 0.5)
    )
}

points <- rbind(points_p_day[, -1], points_p_month[, -1], points_p_year[, -1])

ggplot(points, aes(x = group, y = Freq)) + 
  geom_point(position = position_jitter(width = 0.2), alpha = 0.3) + 
  geom_boxplot(aes(color = group), size = 1, outlier.colour = NA) + 
  facet_grid(group ~ ., scales = "free") + my_theme() +
  theme(
    legend.position = "none",
    strip.placement = "outside",
    strip.background = element_blank(),
    strip.text = element_blank(),
    axis.text.x = element_text(angle = 0, vjust = 0.5, hjust = 0.5)
  ) +
  labs(
    x = "",
    y = "Number of data points",
    title = "How many data points did Google collect about me?",
    subtitle = "Number of data points per day, month and year",
    caption = "\nGoogle collected between 0 and 1500 data points per day
    (median ~500), between 0 and 40,000 per month (median ~15,000) and 
    between 80,000 and 220,000 per year (median ~140,000)."
  )


accuracy <- data.frame(accuracy = loc$accuracy, group = ifelse(loc$accuracy < 800, "high", ifelse(loc$accuracy < 5000, "middle", "low")))

accuracy$group <- factor(accuracy$group, levels = c("high", "middle", "low"))

ggplot(accuracy, aes(x = accuracy, fill = group)) + 
  geom_histogram() + 
  facet_grid(group ~ ., scales="free") + 
  my_theme() +
  theme(
    legend.position = "none",
    strip.placement = "outside",
    strip.background = element_blank(),
    axis.text.x = element_text(angle = 0, vjust = 0.5, hjust = 0.5)
  ) +
  labs(
    x = "Accuracy in metres",
    y = "Count",
    title = "How accurate is the location data?",
    subtitle = "Histogram of accuracy of location points",
    caption = "\nMost data points are pretty accurate, 
but there are still many data points with a high inaccuracy.
    These were probably from areas with bad satellite reception."
  )

# Plot on map

germany <- get_map(location = 'Germany', zoom = 5)

ggmap(germany) + geom_point(data = loc, aes(x = lon, y = lat), alpha = 0.5, color = "red") + 
  theme(legend.position = "right") + 
  labs(
    x = "Longitude", 
    y = "Latitude", 
    title = "Location history data points in Europe",
    caption = "\nA simple point plot shows recorded positions.")

