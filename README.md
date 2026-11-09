
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pcaboot

<!-- badges: start -->

<!-- badges: end -->

The goal of **pcaboot** is to provide **bootstrap confidence intervals
and stability metrics for Principal Component Analysis (PCA) loadings**.

Standard PCA reports loadings from a single run. There is no measure of
how much those loadings would change if the data were slightly
different. `pcaboot` fills this gap by running PCA on many bootstrap
resamples, aligning component signs, and reporting for each loading:

- **Mean loading** across bootstrap runs
- **Standard deviation** (how much it varies)
- **95% confidence interval** (a plausible range)
- **Sign consistency** (fraction of runs with the same sign)

This lets you answer the question: *“Is this loading reliable, or is it
noise?”*

## Installation

You can install the development version of pcaboot from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("AliVali99/pcaboot")
```

## Example

A minimal example using the built-in `iris` dataset:

``` r
library(pcaboot)

# Run bootstrap PCA on the first four columns of iris
boot <- boot_loadings(iris[, 1:4], n_boot = 100)

# Mean loadings
boot$mean_loadings
#>                     PC1         PC2        PC3        PC4
#> Sepal.Length  0.5213418 -0.37434401  0.7190830  0.2592292
#> Sepal.Width  -0.2629209 -0.92255636 -0.2459332 -0.1207564
#> Petal.Length  0.5805746 -0.02189861 -0.1443227 -0.7999201
#> Petal.Width   0.5651321 -0.06148692 -0.6310394  0.5258951

# 95% confidence intervals
boot$ci_lower
#>                     PC1         PC2        PC3        PC4
#> Sepal.Length  0.4981105 -0.47163548  0.6852642  0.2024040
#> Sepal.Width  -0.3426954 -0.95710379 -0.3212235 -0.1506327
#> Petal.Length  0.5669548 -0.06675725 -0.2003519 -0.8111498
#> Petal.Width   0.5529503 -0.11571424 -0.6705715  0.4761118
boot$ci_upper
#>                     PC1          PC2         PC3         PC4
#> Sepal.Length  0.5417824 -0.287696409  0.75022776  0.32141665
#> Sepal.Width  -0.1637178 -0.878189728 -0.17769216 -0.09235286
#> Petal.Length  0.5949384  0.028956295 -0.08099335 -0.78873717
#> Petal.Width   0.5785492  0.008406343 -0.59172000  0.56867683

# Sign consistency (1.0 = very stable)
boot$sign_consistency
#>              PC1  PC2 PC3 PC4
#> Sepal.Length   1 1.00   1   1
#> Sepal.Width    1 1.00   1   1
#> Petal.Length   1 0.80   1   1
#> Petal.Width    1 0.96   1   1
```

The output tells you, for each variable and each component, how stable
its loading is across resamples.

## What’s inside

`boot_loadings()` returns a list with:

| Element            | Description                                |
|--------------------|--------------------------------------------|
| `mean_loadings`    | Average loading per variable per component |
| `sd_loadings`      | Standard deviation across bootstrap runs   |
| `ci_lower`         | Lower 2.5% bound of the 95% CI             |
| `ci_upper`         | Upper 97.5% bound of the 95% CI            |
| `sign_consistency` | Fraction of runs with the same sign        |
| `n_boot`           | Number of successful bootstrap runs        |
| `pca_reference`    | Reference PCA from the full data           |

## Parameters

| Parameter      | Default   | Description                               |
|----------------|-----------|-------------------------------------------|
| `data`         | —         | Numeric matrix or data.frame              |
| `n_boot`       | `100`     | Number of bootstrap resamples             |
| `n_components` | `NULL`    | Components to keep (NULL = all)           |
| `rotate`       | `NULL`    | Optional rotation (`"varimax"` or `NULL`) |
| `na_action`    | `"error"` | `"error"` to stop, `"omit"` to drop rows  |

## Getting help

- See `?boot_loadings` for full documentation
- See `vignette("getting-started")` for a longer tutorial
- Report issues at [GitHub
  Issues](https://github.com/AliVali99/pcaboot/issues)

## License

MIT © Ali
