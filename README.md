
# ffDSM

<!-- badges: start -->
Imports:
    terra,
    sf,
    rsi,
    OGC,
    elevatr

<!-- badges: end -->

**Fast-and-Furious Digital Soil Mapping in R**

ffDSM provides a fast, standardized, and uncertainty-aware baseline workflow for Digital Soil Mapping (DSM).  
It is designed to move directly from data to usable maps with minimal tuning and explicit assumptions.

---

## Motivation

Digital Soil Mapping often requires combining multiple data sources (terrain, remote sensing, climate) and making numerous methodological decisions before producing a first usable map.  
In practice, this leads to fragmented workflows, steep learning curves, and low reproducibility.

ffDSM addresses this gap by providing an **end-to-end DSM baseline** that prioritizes speed, robustness, and reproducibility over exhaustive optimization.

---

## Philosophy

ffDSM follows a *Fast-and-Furious* approach to DSM:

- **Fast**  
  Automated workflows with reasonable defaults and minimal hyperparameter tuning.

- **Furious**  
  A direct path from raw data to spatial predictions, avoiding unnecessary complexity.

- **Baseline, not optimal**  
  The goal is to produce defensible and reproducible maps, not the best possible model.

- **Uncertainty by design**  
  Quantile-based predictions using Quantile Random Forests (QRF) are the default, not an add-on.

This makes ffDSM particularly suitable for exploratory studies, baselines, and operational projects.

---

## What ffDSM does

- Implements an end-to-end Digital Soil Mapping workflow
- Automates the acquisition of environmental covariates:
  - Digital Elevation Models and terrain attributes
  - Remote sensing indices
  - Climate variables
- Performs covariate selection using Recursive Feature Elimination (RFE)
- Fits Quantile Random Forest models
- Produces spatial predictions with explicit uncertainty estimates

---

## What ffDSM does NOT do

- Hyperparameter optimization or model tuning
- Model benchmarking or algorithm comparison
- Deep learning or complex ensemble methods
- Replacement of expert-driven DSM workflows

ffDSM is intended as a **starting point**, not a final or optimal solution.

---

## Conceptual workflow

The typical ffDSM workflow follows these steps:

Soil observations + Area of Interest  
→ Environmental covariate acquisition  
→ Data preparation and feature selection  
→ Quantile Random Forest modeling  
→ Spatial prediction and uncertainty mapping

*OGC covariates are optional and intended to capture broad spatial trends rather than environmental processes.

---

## Typical use cases

- Preliminary or scoping Digital Soil Mapping studies
- Baseline generation for MRV and environmental monitoring
- Teaching and training in DSM workflows
- Applied consulting projects requiring fast and reproducible results

---

## Package status

ffDSM is under active development.  
The API and internal workflows may change as the package evolves.

Contributions, feedback, and issue reports are welcome.

## Installation

You can install the development version of ffDSM like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(ffDSM)
## basic example code
```

