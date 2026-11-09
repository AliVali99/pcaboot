
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pcaboot

Bootstrap confidence intervals and stability metrics for Principal
Component Analysis (PCA) loadings.

## What it does

Standard PCA reports loadings from a single run. There is no measure of
how much those loadings would change if the data were slightly
different. `pcaboot` fills this gap by running PCA on many bootstrap
resamples, aligning component signs, and reporting for each loading:

- **Mean loading** across bootstrap runs
- **Standard deviation** (how much it varies)
- **95% confidence interval** (a plausible range)
- **Sign consistency** (fraction of runs with the same sign)

This lets you answer: *“Is this loading reliable, or is it noise?”*

## Installation

Install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("AliVali99/pcaboot")
```

## Quick example

`boot_loadings()` accepts numeric matrices and data.frames. When a
data.frame has mixed column types, non-numeric columns are dropped
automatically:

``` r
library(pcaboot)

# Cars93 has 27 columns: 17 numeric, 10 categorical
data(Cars93, package = "MASS")

# boot_loadings() keeps the numeric columns and warns about the rest
boot <- boot_loadings(Cars93, n_boot = 100, na_action = "omit")
#> Warning: Dropping 9 non-numeric column(s): Manufacturer, Model, Type, AirBags,
#> DriveTrain, Cylinders, Man.trans.avail, Origin, Make
#> Warning in boot_loadings(Cars93, n_boot = 100, na_action = "omit"): Removed 11
#> rows containing NA.

# Mean loadings for the first 3 components
round(boot$mean_loadings[, 1:3], 3)
#>                       PC1    PC2    PC3
#> Min.Price           0.237  0.306  0.172
#> Price               0.226  0.355  0.178
#> Max.Price           0.209  0.380  0.176
#> MPG.city           -0.251 -0.071  0.230
#> MPG.highway        -0.229 -0.142  0.225
#> EngineSize          0.277 -0.065 -0.104
#> Horsepower          0.241  0.278 -0.071
#> RPM                -0.120  0.401  0.256
#> Rev.per.mile       -0.236  0.148  0.238
#> Fuel.tank.capacity  0.265  0.092 -0.023
#> Passengers          0.176 -0.292  0.359
#> Length              0.269 -0.137  0.005
#> Wheelbase           0.269 -0.103  0.132
#> Width               0.261 -0.132 -0.165
#> Turn.circle         0.237 -0.168 -0.180
#> Rear.seat.room      0.170 -0.227  0.545
#> Luggage.room        0.210 -0.281  0.211
#> Weight              0.287  0.048 -0.079
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
| `pca_reference`    | Reference PCA computed on the full data    |

## Parameters

| Parameter      | Default   | Description                               |
|----------------|-----------|-------------------------------------------|
| `data`         | —         | Numeric matrix or data.frame              |
| `n_boot`       | `100`     | Number of bootstrap resamples             |
| `n_components` | `NULL`    | Components to keep (`NULL` = all)         |
| `rotate`       | `NULL`    | Optional rotation (`"varimax"` or `NULL`) |
| `na_action`    | `"error"` | `"error"` to stop, `"omit"` to drop rows  |
| `numeric_only` | `TRUE`    | Drop non-numeric columns from data.frames |

## Example with rotation

Varimax rotation produces a cleaner “simple structure”, which is easier
to interpret with many variables:

``` r
boot_rot <- boot_loadings(
  Cars93,
  n_boot = 100,
  n_components = 3,
  rotate = "varimax",
  na_action = "omit"
)
#> Warning: Dropping 9 non-numeric column(s): Manufacturer, Model, Type, AirBags,
#> DriveTrain, Cylinders, Man.trans.avail, Origin, Make
#> Warning in boot_loadings(Cars93, n_boot = 100, n_components = 3, rotate =
#> "varimax", : Removed 11 rows containing NA.

round(boot_rot$mean_loadings, 3)
#>                       PC1    PC2    PC3
#> Min.Price           0.015  0.343  0.108
#> Price              -0.005  0.384  0.091
#> Max.Price          -0.019  0.402  0.074
#> MPG.city           -0.292 -0.102  0.085
#> MPG.highway        -0.250 -0.152  0.105
#> EngineSize          0.282  0.028  0.055
#> Horsepower          0.178  0.286 -0.040
#> RPM                -0.301  0.308  0.009
#> Rev.per.mile       -0.335  0.072  0.016
#> Fuel.tank.capacity  0.208  0.149  0.047
#> Passengers         -0.011 -0.100  0.414
#> Length              0.228 -0.016  0.150
#> Wheelbase           0.155  0.030  0.218
#> Width               0.331 -0.045  0.025
#> Turn.circle         0.314 -0.074  0.020
#> Rear.seat.room     -0.116 -0.021  0.511
#> Luggage.room        0.104 -0.108  0.308
#> Weight              0.256  0.120  0.042
```

After rotation, each variable typically loads strongly on one component
and weakly on the others.

## Documentation

- `?boot_loadings` — full parameter documentation
- `vignette("getting-started")` — a longer tutorial using `Cars93`
- [Report issues](https://github.com/AliVali99/pcaboot/issues)

## License

MIT © Ali
