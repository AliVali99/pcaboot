test_that("boot_loadings returns correct structure", {
  set.seed(42)
  res <- boot_loadings(iris[, 1:4], n_boot = 20)

  expect_type(res, "list")

  # Tüm elemanlar var mı, isimleri doğru mu?
  expect_named(res, c("mean_loadings", "sd_loadings", "ci_lower",
                      "ci_upper", "sign_consistency", "n_boot",
                      "pca_reference"))

  # Matris boyutları doğru mu? iris 4 değişken, 4 bileşen üretir.
  expect_equal(dim(res$mean_loadings), c(4, 4))

  # n_boot doğru dönmüş mü?
  expect_equal(res$n_boot, 20)

  # Satır ve sütun isimleri doğru mu?
  expect_equal(rownames(res$mean_loadings), colnames(iris[, 1:4]))
  expect_equal(colnames(res$mean_loadings), paste0("PC", 1:4))
})
