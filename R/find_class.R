library(dplyr)

# Finds the class of a new observation. It is assumed that the respective dista-
# nces from the new observation have been appended to the initial dataset.
find_class <- function(data, k) {
  data |> 
    slice_min(order_by = distances, n = k) |> 
    count(class) |> 
    slice_max(n) |> 
    pull(class)
}
