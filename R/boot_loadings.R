#' Bootstrap PCA Loadings
#'
#' Runs PCA on \code{n_boot} bootstrap resamples and returns per-variable
#' loading distributions. Component signs are aligned to a reference PCA
#' run to resolve the inherent sign ambiguity of principal components.
# Neden Gozukmedi?
#'
#' @param data A numeric matrix or data.frame with observations in rows.
#' @param n_boot Number of bootstrap samples. Default 100.
#' @param n_components Number of components to keep. Default all.
#' @param rotate Optional rotation. Use \code{"varimax"} for orthogonal
#'   rotation or \code{NULL} (default).
#' @param na_action Either \code{"error"} (default) or \code{"omit"}.
#'
#' @return A list of class \code{"boot_loadings"} with elements:
#'   \code{mean_loadings}, \code{sd_loadings}, \code{ci_lower},
#'   \code{ci_upper}, \code{sign_consistency}, \code{n_boot}, and
#'   \code{pca_reference}.
#'
#' @importFrom stats prcomp sd quantile na.omit varimax
#'
#' @examples
#' boot <- boot_loadings(iris[, 1:4], n_boot = 50)
#' boot$mean_loadings
#' boot$ci_lower
#'
#' @export
boot_loadings <- function(data, n_boot = 100, n_components = NULL,
                          rotate = NULL, na_action = "error") {

  # --- 1. Input validation ---
  if (!is.matrix(data) && !is.data.frame(data)) {
    stop("`data` must be a matrix or data.frame.")
  }

  data <- as.matrix(data)

  if (!is.numeric(data)) {
    stop("`data` must be numeric. Convert factor or character columns first.")
  }

  # --- 2. NA handling ---
  if (anyNA(data)) {
    if (na_action == "omit") {
      n_before <- nrow(data)
      data <- na.omit(data)
      warning(sprintf("Removed %d rows containing NA.",
                      n_before - nrow(data)))
    } else {
      stop("`data` contains NA. Use na_action = 'omit'.")
    }
  }

  # --- 3. Dimensions ---
  n <- nrow(data)
  p <- ncol(data)

  if (n < 3) stop("At least 3 observations are required.")
  if (p < 2) stop("At least 2 variables are required.")

  # --- 4. Reference PCA (full data) ---
  pca_ref <- prcomp(data, center = TRUE, scale. = TRUE)

  if (is.null(n_components)) {
    n_components <- ncol(pca_ref$rotation)
  }
  n_components <- min(n_components, ncol(pca_ref$rotation))

  # --- 5. Result array ---
  loadings_array <- array(0, dim = c(p, n_components, n_boot))

  # --- 6. Bootstrap loop ---
  for (b in seq_len(n_boot)) {

    idx <- sample(n, size = n, replace = TRUE)
    data_b <- data[idx, , drop = FALSE]

    pca_b <- tryCatch(
      prcomp(data_b, center = TRUE, scale. = TRUE),
      error = function(e) NULL
    )

    if (is.null(pca_b)) next

    L <- pca_b$rotation[, seq_len(n_components), drop = FALSE]

    # --- Sign alignment ---
    for (j in seq_len(n_components)) {
      if (sum(L[, j] * pca_ref$rotation[, j]) < 0) {
        L[, j] <- -L[, j]
      }
    }

    # --- Rotation (optional) ---
    if (!is.null(rotate) && rotate == "varimax" && n_components >= 2) {
      L <- varimax(L)$loadings
    }

    loadings_array[, , b] <- L
  }

  # --- 7. Summary statistics ---
  mean_L <- apply(loadings_array, c(1, 2), mean, na.rm = TRUE)
  sd_L   <- apply(loadings_array, c(1, 2), sd,   na.rm = TRUE)
  ci_lo  <- apply(loadings_array, c(1, 2), quantile,
                  probs = 0.025, na.rm = TRUE)
  ci_hi  <- apply(loadings_array, c(1, 2), quantile,
                  probs = 0.975, na.rm = TRUE)

  # --- 8. Sign consistency ---
  sign_cons <- matrix(0, p, n_components)
  for (i in seq_len(p)) {
    for (j in seq_len(n_components)) {
      signs <- sign(loadings_array[i, j, ])
      target <- sign(mean_L[i, j])
      sign_cons[i, j] <- mean(signs == target, na.rm = TRUE)
    }
  }

  # --- 9. Naming ---
  var_names <- colnames(data)
  if (is.null(var_names)) var_names <- paste0("V", seq_len(p))
  pc_names <- paste0("PC", seq_len(n_components))

  rownames(mean_L) <- rownames(sd_L) <- rownames(ci_lo) <-
    rownames(ci_hi) <- rownames(sign_cons) <- var_names
  colnames(mean_L) <- colnames(sd_L) <- colnames(ci_lo) <-
    colnames(ci_hi) <- colnames(sign_cons) <- pc_names

  # --- 10. Result ---
  result <- list(
    mean_loadings    = mean_L,
    sd_loadings      = sd_L,
    ci_lower         = ci_lo,
    ci_upper         = ci_hi,
    sign_consistency = sign_cons,
    n_boot           = n_boot,
    pca_reference    = pca_ref
  )

  class(result) <- "boot_loadings"
  result
}

# --- Print method ---
#' @rdname boot_loadings
#' @export
print.boot_loadings <- function(x, ...) {
  cat("\nBootstrap PCA Loadings\n")
  cat("======================\n")
  cat("Bootstrap runs   :", x$n_boot, "\n")
  cat("Variables        :", nrow(x$mean_loadings), "\n")
  cat("Components       :", ncol(x$mean_loadings), "\n\n")

  show_k <- min(3, ncol(x$mean_loadings))
  cat(sprintf("Mean loadings (first %d components):\n", show_k))
  print(round(x$mean_loadings[, seq_len(show_k), drop = FALSE], 3))

  cat("\nSign consistency (first", show_k, "components):\n")
  print(round(x$sign_consistency[, seq_len(show_k), drop = FALSE], 2))

  invisible(x)
}
