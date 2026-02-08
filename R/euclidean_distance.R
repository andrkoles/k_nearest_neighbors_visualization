library(dplyr)
library(purrr)

# Returns Euclidean distances from a point to all points in a 2D dataset
euclidean_distance <- function(data, point) {
  df <- data |> select(x, y)
  distances <- map2_df(df, point, `-`) ^ 2 |>
    apply(MARGIN = 1, FUN = sum) |>
    sqrt()
  return(distances)
}
