# BIOM M235 — Causal Inference Final Project

**Does having health insurance affect whether U.S. adults get a blood-sugar
screening?** A causal analysis of the NHANES 2017–March 2020 pre-pandemic cycle.

- **Exposure (A):** health-insurance coverage (`HIQ011`, insured vs. uninsured)
- **Outcome (Y):** blood-sugar screening in the past 3 years (`DIQ180`)
- **Estimand:** average treatment effect (ATE) of insurance on screening

## Team

- **Sujit Silas Armstrong** — data preparation, doubly robust (AIPW) estimation
- **Janvi Bharucha** — outcome regression (survey-weighted logistic)
- **Amanda Millatt** — DAG / identification, inverse-probability weighting (IPW)

## Repository layout

```
.
├── nhanes_data_prep.Rmd                 # Sujit — download, merge, recode, positivity (builds the CSV)
├── nhanes_dag.Rmd                       # Amanda — DAG and adjustment-set justification
├── nhanes_insurance_screening_analytic.csv   # shared analytic dataset (input to all models)
├── modeling/                            # the three estimators of the causal effect
│   ├── outcome_regression.Rmd           #   Janvi — survey-weighted logistic regression
│   ├── ipw.Rmd                          #   Amanda — inverse-probability weighting (placeholder)
│   └── doubly_robust.Rmd                #   Sujit — augmented IPW (AIPW)
├── sensitivity/
│   └── sensitivity_analysis.Rmd         # robustness checks (E-value, trimming, imputation; placeholder)
├── report/                              # LaTeX write-up
│   ├── main.tex
│   └── references.bib
└── archive/                             # superseded work, kept for reference
    ├── BIOM235 Final code.R             #   Amanda's earlier nhanesA-based data prep
    └── BIOM235_dataset_AM.xlsx
```

## Workflow

1. Knit `nhanes_data_prep.Rmd` first — it downloads the NHANES `P_` files and
   writes `nhanes_insurance_screening_analytic.csv`, the single dataset every
   model reads.
2. The three documents in `modeling/` each load that CSV (via a relative path
   that works whether knit from `modeling/` or run from the project root) and
   estimate the insurance effect with a different method.
3. `sensitivity/` probes the assumptions behind those estimates.

## Conventions

All `.Rmd` files share the same header format (`title` / `subtitle` / `author` /
`date`, with an HTML output and a self-installing package `setup` chunk) so the
documents render consistently.
