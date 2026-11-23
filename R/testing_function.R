fit <- boot_loadings(iris[, 1:4], n_boot = 100,
                     na_action = "mean", rotate = "varimax", seed = 1)

fit                                  # sayısal tablo
plot(fit)                            # 2×2 özet (görsel çıkar)
plot(fit, type = "loadings")
plot(fit, type = "ci")
plot(fit, type = "sign")
plot(fit, type = "scree")
plot(fit, type = "biplot")


data(Cars93, package = "MASS")
dim(Cars93)
fit <- boot_loadings(Cars93, n_boot = 100,
                     na_action = "omit", rotate = "varimax",
                     n_components = 3, seed = 1)

fit                                  # sayısal özet tablo
fit$mean_loadings[, "PC1"]
fit$ci_lower[, "PC1"]
fit$ci_upper[, "PC1"]
fit$sign_consistency[, "PC1"]

plot(fit)                            # 2×2 özet (görsel çıkar)


plot(fit, type = "ci")
plot(fit, type = "ci", components = "PC1")
