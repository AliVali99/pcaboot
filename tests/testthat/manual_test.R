# ============================================================
# manual_test.R — Manual test protocol (single file)
# Usage: source("manual_test.R")
# ============================================================

suppressPackageStartupMessages({
  if (!requireNamespace("devtools", quietly = TRUE))
    stop("The 'devtools' package is required.")
})
devtools::load_all(quiet = TRUE)

# --- Test runner ---
.pass <- 0L
.fail <- 0L
.fail_names <- character(0)

run_test <- function(name, fn) {
  warns <- character(0)
  ok <- tryCatch({
    withCallingHandlers(
      { fn(); TRUE },
      warning = function(w) {
        warns <<- c(warns, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  }, error = function(e) {
    cat(sprintf("    \u21b3 Error: %s\n", conditionMessage(e)))
    FALSE
  })

  if (ok) {
    .pass <<- .pass + 1L
    cat(sprintf("\u2705 PASS  %s\n", name))
    if (length(warns) > 0)
      cat(sprintf("    \u21b3 Warning: %s\n", paste(warns, collapse = " | ")))
  } else {
    .fail <<- .fail + 1L
    .fail_names <<- c(.fail_names, name)
    cat(sprintf("\u274c FAIL  %s\n", name))
  }
}

cat("\n========== MANUAL TEST PROTOCOL ==========\n\n")

# ---------- Test 1: Basic functionality (iris) ----------
run_test("Test 1: Basic run - iris", function() {
  set.seed(42)
  boot1 <- boot_loadings(iris[, 1:4], n_boot = 20)
  stopifnot(
    inherits(boot1, "boot_loadings"),
    boot1$n_boot == 20,
    nrow(boot1$mean_loadings) == 4,
    ncol(boot1$mean_loadings) == 4
  )
})

# ---------- Test 2: Structure ----------
run_test("Test 2: Structure - 7 elements", function() {
  set.seed(42)
  boot1 <- boot_loadings(iris[, 1:4], n_boot = 20)
  expected <- c("mean_loadings", "sd_loadings", "ci_lower",
                "ci_upper", "sign_consistency", "n_boot",
                "pca_reference")
  stopifnot(
    is.list(boot1),
    identical(names(boot1), expected)
  )
})

# ---------- Test 3: $ access ----------
run_test("Test 3: $ access and internal consistency", function() {
  set.seed(42)
  boot1 <- boot_loadings(iris[, 1:4], n_boot = 20)
  stopifnot(
    all(boot1$ci_lower <= boot1$ci_upper),
    all(boot1$sd_loadings >= 0),
    all(boot1$sign_consistency >= 0 & boot1$sign_consistency <= 1)
  )
})

# ---------- Test 4: numeric_only (Cars93) ----------
run_test("Test 4: numeric_only - Cars93", function() {
  data(Cars93, package = "MASS")
  set.seed(1)
  boot2 <- suppressWarnings(
    boot_loadings(Cars93, n_boot = 20, na_action = "omit")
  )
  stopifnot(
    nrow(boot2$mean_loadings) == 17,
    ncol(boot2$mean_loadings) == 17
  )
})

# ---------- Test 5: numeric_only = FALSE (legacy behaviour) ----------
run_test("Test 5: numeric_only = FALSE - error expected", function() {
  data(Cars93, package = "MASS")
  err <- tryCatch(
    boot_loadings(Cars93, n_boot = 10, numeric_only = FALSE),
    error = function(e) conditionMessage(e)
  )
  stopifnot(is.character(err), grepl("must be numeric", err))
})

# ---------- Test 6: Fully categorical input ----------
run_test("Test 6: Fully categorical - error expected", function() {
  df <- data.frame(a = letters[1:5], b = LETTERS[1:5])
  err <- tryCatch(
    boot_loadings(df),
    error = function(e) conditionMessage(e)
  )
  stopifnot(is.character(err), grepl("no numeric", err))
})

# ---------- Test 7: NA handling ----------
run_test("Test 7: NA - error and omit", function() {
  X_na <- matrix(c(1, 2, NA, 4, 5, 6, 7, 8, 9, 10, 11, 12), ncol = 3)

  # 7a: default behaviour -> error
  err <- tryCatch(boot_loadings(X_na, n_boot = 5),
                  error = function(e) conditionMessage(e))
  stopifnot(is.character(err), grepl("contains NA", err))

  # 7b: na_action = "omit" -> runs
  boot_na <- suppressWarnings(
    boot_loadings(X_na, n_boot = 5, na_action = "omit")
  )
  stopifnot(nrow(boot_na$mean_loadings) == 3)
})

# ---------- Test 8: n_components ----------
run_test("Test 8: n_components limits output", function() {
  set.seed(42)
  boot3 <- boot_loadings(iris[, 1:4], n_boot = 10, n_components = 2)
  stopifnot(
    ncol(boot3$mean_loadings) == 2,
    identical(colnames(boot3$mean_loadings), c("PC1", "PC2"))
  )
})

# ---------- Test 9: rotate changes loadings ----------
run_test("Test 9: rotate = varimax changes output", function() {
  set.seed(42)
  boot_raw <- boot_loadings(iris[, 1:4], n_boot = 20)
  set.seed(42)
  boot_rot <- boot_loadings(iris[, 1:4], n_boot = 20, rotate = "varimax")
  stopifnot(
    !identical(boot_raw$mean_loadings, boot_rot$mean_loadings),
    any(abs(boot_raw$mean_loadings - boot_rot$mean_loadings) > 0.01)
  )
})

# ---------- Test 10: CI logic ----------
run_test("Test 10: CI bounds bracket the mean", function() {
  set.seed(42)
  boot1 <- boot_loadings(iris[, 1:4], n_boot = 20)
  stopifnot(
    all(boot1$ci_lower <= boot1$mean_loadings),
    all(boot1$mean_loadings <= boot1$ci_upper)
  )
})

# ---------- Test 11: Same seed -> same result ----------
run_test("Test 11: Same seed, same result", function() {
  set.seed(123)
  r1 <- boot_loadings(iris[, 1:4], n_boot = 20)
  set.seed(123)
  r2 <- boot_loadings(iris[, 1:4], n_boot = 20)
  stopifnot(identical(r1$mean_loadings, r2$mean_loadings))
})

# ---------- Test 12: Different seed -> different result ----------
run_test("Test 12: Different seed, different result", function() {
  set.seed(1)
  r1 <- boot_loadings(iris[, 1:4], n_boot = 20)
  set.seed(2)
  r2 <- boot_loadings(iris[, 1:4], n_boot = 20)
  stopifnot(!identical(r1$mean_loadings, r2$mean_loadings))
})

# ---------- Test 13: Close to reference PCA ----------
run_test("Test 13: Mean loadings close to reference PCA", function() {
  set.seed(42)
  boot <- boot_loadings(iris[, 1:4], n_boot = 100)
  diff <- abs(abs(boot$mean_loadings) - abs(boot$pca_reference$rotation))
  stopifnot(max(diff) < 0.15)
})

# ---------- Test 14: Unnamed matrix ----------
run_test("Test 14: Unnamed matrix gets V1..V5", function() {
  m <- matrix(rnorm(100), ncol = 5)
  colnames(m) <- NULL
  set.seed(42)
  boot <- boot_loadings(m, n_boot = 10)
  stopifnot(identical(rownames(boot$mean_loadings),
                      paste0("V", 1:5)))
})

# ---------- Test 15: Only 2 observations ----------
run_test("Test 15: 2 observations - error expected", function() {
  m <- matrix(1:4, nrow = 2)
  err <- tryCatch(boot_loadings(m),
                  error = function(e) conditionMessage(e))
  stopifnot(grepl("At least 3 observations", err))
})

# ---------- Test 16: Only 1 variable ----------
run_test("Test 16: 1 variable - error expected", function() {
  m <- matrix(1:10, ncol = 1)
  err <- tryCatch(boot_loadings(m),
                  error = function(e) conditionMessage(e))
  stopifnot(grepl("At least 2 variables", err))
})

# ---------- Test 17: Vector input ----------
run_test("Test 17: Vector - error expected", function() {
  err <- tryCatch(boot_loadings(1:10),
                  error = function(e) conditionMessage(e))
  stopifnot(grepl("matrix or data.frame", err))
})

# ---------- Test 18: 30 variables (scaling) ----------
run_test("Test 18: 30 variables - scaling", function() {
  set.seed(1)
  big <- matrix(rnorm(500 * 30), ncol = 30)
  set.seed(1)
  boot_big <- boot_loadings(big, n_boot = 20)
  stopifnot(
    nrow(boot_big$mean_loadings) == 30,
    ncol(boot_big$mean_loadings) == 30
  )
})

# ---------- Summary ----------
cat("\n========== SUMMARY ==========\n")
cat(sprintf("Total  : %d\n", .pass + .fail))
cat(sprintf("PASS   : %d\n", .pass))
cat(sprintf("FAIL   : %d\n", .fail))
if (.fail > 0) {
  cat("\nFailed tests:\n")
  for (n in .fail_names) cat("  -", n, "\n")
}
cat("=============================\n")

if (.fail == 0) {
  cat("\n\U0001f389 All tests passed.\n\n")
} else {
  cat("\n\u26a0\ufe0f  Some tests failed. See the error messages above.\n\n")
}
