
library(bench)
library(ggplot2)
library(profvis)

set.seed(1)
X <- matrix(rnorm(93 * 18), nrow = 93)
colnames(X) <- paste0("V", 1:18)

system.time(
  fit <- boot_loadings(X, n_boot = 100)
)


set.seed(1)
X <- matrix(rnorm(93 * 18), nrow = 93)

bm <- bench::mark(
  n_boot_100  = boot_loadings(X, n_boot = 100),
  n_boot_500  = boot_loadings(X, n_boot = 500),
  n_boot_1000 = boot_loadings(X, n_boot = 1000),
  check = FALSE,
  iterations = 5
)

bm[, c("expression", "median", "mem_alloc", "gc")]


set.seed(1)
X <- matrix(rnorm(93 * 18), nrow = 93)

res_boot <- bench::press(
  n_boot = c(50, 100, 500, 1000),
  bench::mark(boot_loadings(X, n_boot = n_boot), check = FALSE)
)

res_boot


