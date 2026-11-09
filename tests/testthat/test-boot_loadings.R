# tests/testthat/test-boot_loadings.R

test_that("boot_loadings works on Cars93 with auto numeric selection", {
  data(Cars93, package = "MASS")
  set.seed(42)

  expect_warning(
    res <- boot_loadings(Cars93, n_boot = 10, na_action = "omit"),
    "Dropping"
  )

  expect_type(res, "list")
  expect_equal(nrow(res$mean_loadings), 18)
})

test_that("boot_loadings errors if no numeric columns", {
  df <- data.frame(a = letters[1:5], b = LETTERS[1:5])
  expect_error(boot_loadings(df), "no numeric columns")
})

test_that("boot_loadings scales to 18 variables", {
  data(Cars93, package = "MASS")
  set.seed(1)
  res <- boot_loadings(Cars93, n_boot = 10, n_components = 3,
                       na_action = "omit")
  expect_equal(dim(res$mean_loadings), c(18, 3))
})
