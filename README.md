# BIOM M235 — Causal Inference Final Project

**Does having health insurance affect whether U.S. adults get a blood-sugar
screening?** A causal analysis of the NHANES 2017–March 2020 pre-pandemic cycle.

- **Exposure (A):** health-insurance coverage (`HIQ011`, insured vs. uninsured)
- **Outcome (Y):** blood-sugar screening in the past 3 years (`DIQ180`)
- **Estimand:** average treatment effect (ATE) of insurance on screening

## Team

- **Sujit Silas Armstrong** 
- **Janvi Bharucha** 
- **Amanda Millatt**

## Repository layout

```
.
├── nhanes_data_prep.Rmd                
├── nhanes_dag.Rmd                       
├── nhanes_insurance_screening_analytic.csv   
├── modeling/                           
│   ├── outcome_regression.Rmd         
│   ├── ipw.Rmd                         
│   └── doubly_robust.Rmd               
├── sensitivity/
│   └── sensitivity_analysis.Rmd        
├── report/                             
│   ├── main.tex
│   └── references.bib
└── archive/                             
    ├── BIOM235 Final code.R            
    └── BIOM235_dataset_AM.xlsx
```
