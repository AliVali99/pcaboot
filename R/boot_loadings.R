#' Bootstrap PCA Loadings
#'
#' @param data Numeric matrix or data.frame.
#' @param n_boot Bootstrap samples. Default 100.
#' @param n_components Components to keep. Default all.
#' @param rotate `NULL`/`"none"`, `"varimax"` or `"promax"`.
#' @param na_action `"error"`, `"omit"`, `"mean"`, `"median"` or `"knn"`
#'   (via \pkg{mice} / \pkg{VIM}).
#' @param k_nn Neighbours for knn. Default 5.
#' @param seed Optional integer seed.
#' @return List of class `"boot_loadings"`.
#'
#' @importFrom stats prcomp sd quantile na.omit varimax promax median
#' @export
boot_loadings <- function(data, n_boot = 100, n_components = NULL,
                          rotate = NULL, na_action = "error",
                          k_nn = 5, seed = NULL) {

  if (!is.null(seed)) set.seed(seed)
  if (!is.null(rotate) && !rotate %in% c("none", "varimax", "promax"))
    stop("rotate: 'none', 'varimax' or 'promax'")

  if (is.data.frame(data))
    data <- data[, vapply(data, is.numeric, logical(1)), drop = FALSE]
  data <- as.matrix(data)
  if (!is.numeric(data)) stop("data must be numeric.")

  data <- .impute_na(data, na_action, k_nn)

  n <- nrow(data); p <- ncol(data)
  if (n < 3 || p < 2) stop("Need >=3 rows and >=2 columns.")

  pca_ref <- prcomp(data, center = TRUE, scale. = TRUE)
  if (is.null(n_components)) n_components <- ncol(pca_ref$rotation)
  n_components <- min(n_components, ncol(pca_ref$rotation))
  ref_L <- pca_ref$rotation[, seq_len(n_components), drop = FALSE]

  arr <- array(NA_real_, c(p, n_components, n_boot))
  n_ok <- 0
  for (b in seq_len(n_boot)) {
    pca_b <- tryCatch(
      prcomp(data[sample(n, replace = TRUE), , drop = FALSE],
             center = TRUE, scale. = TRUE),
      error = function(e) NULL
    )
    if (is.null(pca_b)) next
    L <- pca_b$rotation[, seq_len(n_components), drop = FALSE]
    sgn <- sign(colSums(L * ref_L)); sgn[sgn == 0] <- 1
    L <- sweep(L, 2, sgn, "*")
    if (!is.null(rotate) && rotate != "none" && n_components >= 2)
      L <- .rotate_loadings(L, rotate)
    n_ok <- n_ok + 1
    arr[, , n_ok] <- L
  }
  if (n_ok == 0) stop("All bootstrap resamples failed.")
  arr <- arr[, , seq_len(n_ok), drop = FALSE]

  mean_L <- apply(arr, c(1, 2), mean, na.rm = TRUE)
  sd_L   <- apply(arr, c(1, 2), sd,   na.rm = TRUE)
  ci_lo  <- apply(arr, c(1, 2), quantile, 0.025, na.rm = TRUE)
  ci_hi  <- apply(arr, c(1, 2), quantile, 0.975, na.rm = TRUE)
  sign_cons <- apply(arr, c(1, 2), function(v)
    mean(sign(v) == sign(mean(v, na.rm = TRUE)), na.rm = TRUE))

  vn <- colnames(data); if (is.null(vn)) vn <- paste0("V", seq_len(p))
  pn <- paste0("PC", seq_len(n_components))
  dn <- list(vn, pn)
  dimnames(mean_L)    <- dn
  dimnames(sd_L)      <- dn
  dimnames(ci_lo)     <- dn
  dimnames(ci_hi)     <- dn
  dimnames(sign_cons) <- dn
  structure(list(mean_loadings = mean_L, sd_loadings = sd_L,
                 ci_lower = ci_lo, ci_upper = ci_hi,
                 sign_consistency = sign_cons, n_boot = n_ok,
                 pca_reference = pca_ref, rotate = rotate,
                 na_action = na_action),
            class = "boot_loadings")
}

# --- NA via mice / VIM ---
.impute_na <- function(data, method, k = 5) {
  method <- match.arg(method, c("error", "omit", "mean", "median", "knn"))
  if (!anyNA(data)) return(data)
  if (method == "error") stop("data has NA.")
  if (method == "omit")  return(na.omit(data))

  if (method == "knn") {
    if (!requireNamespace("VIM", quietly = TRUE))
      stop("Package 'VIM' is required for na_action = 'knn'.")
    return(as.matrix(VIM::kNN(data, k = k, imp_var = FALSE)))
  }

  # mean / median via mice (single-shot, no iteration)
  if (!requireNamespace("mice", quietly = TRUE))
    stop("Package 'mice' is required for na_action = 'mean'/'median'.")
  m <- mice::mice(data, method = method, m = 1, maxit = 1, printFlag = FALSE)
  as.matrix(mice::complete(m, 1))
}

.rotate_loadings <- function(L, rotate) {
  if (ncol(L) < 2) return(L)
  switch(rotate,
         varimax = unclass(stats::varimax(L)$loadings),
         promax  = unclass(stats::promax(L)$loadings))
}

# --- print / summary ---
#' @export
print.boot_loadings <- function(x, ...) {
  cat("\nBootstrap PCA Loadings\n======================\n")
  cat("Bootstrap runs :", x$n_boot, "\n")
  cat("Variables      :", nrow(x$mean_loadings), "\n")
  cat("Components     :", ncol(x$mean_loadings), "\n")
  if (!is.null(x$rotate) && x$rotate != "none")
    cat("Rotation       :", x$rotate, "\n")
  cat("NA handling    :", x$na_action, "\n\n")
  print(round(x$mean_loadings, 3))
  invisible(x)
}

#' @export
summary.boot_loadings <- function(object, ...) {
  for (nm in c("mean_loadings", "sd_loadings", "ci_lower",
               "ci_upper", "sign_consistency")) {
    cat(nm, ":\n"); print(round(object[[nm]], 3)); cat("\n")
  }
  invisible(object)
}

# --- plots (ggplot2) ---
#' @export
plot.boot_loadings <- function(x,
                               type = c("all", "scree", "loadings",
                                        "ci", "sign", "biplot"),
                               components = NULL) {
  type <- match.arg(type)

  pick  <- function(M) if (is.null(components)) M else M[, components, drop = FALSE]
  to_df <- function(M) {
    df <- as.data.frame(as.table(M))
    names(df) <- c("variable", "component", "value")
    df$variable  <- factor(df$variable,  levels = rev(rownames(M)))
    df$component <- factor(df$component, levels = colnames(M))
    df
  }

  p_scree <- function() {
    v <- x$pca_reference$sdev^2
    ggplot2::ggplot(data.frame(i = seq_along(v), v = v), ggplot2::aes(i, v)) +
      ggplot2::geom_line() + ggplot2::geom_point(size = 2) +
      ggplot2::labs(title = "Scree", x = "Component", y = "Variance") +
      ggplot2::theme_minimal()
  }

  p_loadings <- function() {
    M <- pick(x$mean_loadings); df <- to_df(M); z <- max(abs(M))
    ggplot2::ggplot(df, ggplot2::aes(component, variable, fill = value)) +
      ggplot2::geom_tile() +
      ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", value)), size = 3) +
      ggplot2::scale_fill_gradient2(low = "#2166AC", mid = "white",
                                    high = "#B2182B", midpoint = 0,
                                    limits = c(-z, z)) +
      ggplot2::labs(title = "Mean Loadings", x = "Component", y = "") +
      ggplot2::theme_minimal()
  }

  p_sign <- function() {
    df <- to_df(pick(x$sign_consistency))
    ggplot2::ggplot(df, ggplot2::aes(component, variable, fill = value)) +
      ggplot2::geom_tile() +
      ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", value)), size = 3) +
      ggplot2::scale_fill_gradient(low = "#F7F7F7", high = "#2166AC",
                                   limits = c(0, 1)) +
      ggplot2::labs(title = "Sign Consistency", x = "Component", y = "") +
      ggplot2::theme_minimal()
  }

  p_ci <- function() {
    M <- pick(x$mean_loadings); LO <- pick(x$ci_lower); HI <- pick(x$ci_upper)
    df <- do.call(rbind, lapply(seq_len(ncol(M)), function(j)
      data.frame(variable = rownames(M), component = colnames(M)[j],
                 mean = M[, j], lo = LO[, j], hi = HI[, j])))
    df$variable  <- factor(df$variable, levels = rev(rownames(M)))
    df$component <- factor(df$component, levels = colnames(M))
    g <- ggplot2::ggplot(df, ggplot2::aes(mean, variable, color = mean >= 0)) +
      ggplot2::geom_vline(xintercept = 0, linetype = 2) +
      ggplot2::geom_errorbarh(ggplot2::aes(xmin = lo, xmax = hi), height = 0.2) +
      ggplot2::geom_point(size = 2) +
      ggplot2::scale_color_manual(values = c("#B2182B", "#2166AC"), guide = "none") +
      ggplot2::labs(x = "Loading (95% CI)", y = "") +
      ggplot2::theme_minimal()
    if (ncol(M) > 1) g + ggplot2::facet_wrap(~ component, scales = "free_x")
    else g + ggplot2::labs(title = colnames(M)[1])
  }

  p_biplot <- function() {
    pca <- x$pca_reference
    obs <- data.frame(PC1 = pca$x[, 1], PC2 = pca$x[, 2])
    mlt <- min(max(abs(obs$PC1)) / max(abs(pca$rotation[, 1])),
               max(abs(obs$PC2)) / max(abs(pca$rotation[, 2])))
    vr  <- data.frame(v = rownames(pca$rotation),
                      PC1 = pca$rotation[, 1] * mlt,
                      PC2 = pca$rotation[, 2] * mlt)
    ggplot2::ggplot() +
      ggplot2::geom_point(data = obs, ggplot2::aes(PC1, PC2), alpha = 0.4) +
      ggplot2::geom_segment(data = vr,
                            ggplot2::aes(0, 0, xend = PC1, yend = PC2),
                            arrow = grid::arrow(length = grid::unit(0.2, "cm")),
                            color = "#B2182B") +
      ggplot2::geom_text(data = vr, ggplot2::aes(PC1, PC2, label = v),
                         color = "#B2182B", size = 3, vjust = -0.5) +
      ggplot2::labs(title = "PCA Biplot", x = "PC1", y = "PC2") +
      ggplot2::theme_minimal()
  }

  # --- KRİTİK: switch sonucu g değişkenine atanır ---
  g <- switch(type,
              scree    = p_scree(),
              loadings = p_loadings(),
              ci       = p_ci(),
              sign     = p_sign(),
              biplot   = p_biplot(),
              all      = {
                ps <- list(p_scree(), p_loadings(), p_ci(), p_sign())
                if (requireNamespace("patchwork", quietly = TRUE)) {
                  patchwork::wrap_plots(ps, ncol = 2)
                } else {
                  for (p in ps) print(p)
                  return(invisible(x))
                }
              }
  )

  print(g)          # görseli ekrana basar
  invisible(g)
}
