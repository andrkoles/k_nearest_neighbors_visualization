library(tibble)

# Half the size of the dataset
size <- 100

# Synthetic dataset
set.seed(20)
df <- tibble(
  x = c(
    rnorm(n = size, mean = 3, sd = 1),
    rnorm(n = size, mean = 5, sd = 1)
  ),
  y = c(
    rnorm(n = size, mean = 3, sd = 1),
    rnorm(n = size, mean = 5, sd = 1)
  ),
  class = c(
    rep("Class a", size),
    rep("Class b", size)
  )
)
