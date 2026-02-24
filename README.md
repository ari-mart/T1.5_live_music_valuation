# Live Music Economic Contribution (OpenMusE)

This repository contains the data and code required to replicate the estimation of the **direct economic contribution of live music**, as presented in Section 1 of Deliverable D1.5.

The calculation combines:

- Eurostat national accounts  
- Eurostat employment statistics  
- Input–Output–based structural coefficients  
- Survey-based expenditure data  

These elements are integrated to estimate the direct contribution of live music to:

- Gross Value Added (GVA)  
- Employment (Full-Time Equivalents – FTE)  

**Note:** The results reflect *direct effects only* and do not include indirect or induced multiplier effects.

## Repository Structure
```bash
T1.5_live_music_valuation/
│
├── README.md
│
├── code/
│ ├── R/
│ │ └── 01_download_eurostat_data.R
│ │
│ └── Stata/
│   ├── 02_prepare_io_coefficients.do
│   └── 03_calculate_live_music_contribution.do
│
├── data_raw/
│ ├── eurostat/
│ └── survey/
│
├── data_processed/
│
└── output/
```
## How to reproduce the results

### 1) Download Eurostat data (R)
Run:
- `code/R/01_download_eurostat_data.R`

Outputs saved to:
- `data_raw/eurostat/`

Csv datasets downloaded not included as very large:
- `naio_10_cp1700` (Output `P1` and GVA `B1G`)
- `nama_10_a64_e` (hours worked for employment)

---

### 2) Prepare IO coefficients (Stata)
Run:
- `code/Stata/02_prepare_io_coefficients.do`

This script:
- Converts hours worked into FTE
- Aggregates sectors (G, H, I, R)
- Computes:
  - `GVA_COEFFICIENT = B1G / P1`
  - `EMP_COEFFICIENT = FTE / P1`

Outputs saved to:
- `data_processed/FTE_PER_PRODUCT.dta`
- `data_processed/VA_EMP_COEFFICIENT.dta`

---

### 3) Calculate live music contribution (Stata)
Run:
- `code/Stata/03_calculate_live_music_contribution.do`

This script:
- Merges survey expenditure data + attendance values
- Applies the IO coefficients
- Produces GVA and employment contributions

Final output saved to:
- `output/LIVE_MUSIC_CONTRIBUTION.xlsx`

---

## Country coverage
- IT, DE, FR, ES, HU, SK, PL  
Reference year: **2020**
