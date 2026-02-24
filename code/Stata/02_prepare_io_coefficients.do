/*******************************************************************************
CALCULATE VALUE-ADDED AND EMPLOYMENT COEFFICIENTS
(from Eurostat national accounts / input–output related tables)

OVERVIEW
- This script computes, by country and by broad product class:
    (1) Value-added coefficient = B1G / P1
    (2) Employment coefficient  = FTE / P1

DATA INPUTS (downloaded beforehand via R script: 01_download_eurostat_data.R)
1) nama_10_a64_e.csv
   - Employment in hours worked (THS_HW) for employees (EMP_DC)
   - Used to approximate FTE

2) naio_10_cp1700.csv
   - Output (P1) and gross value added (B1G) in million euro (MIO_EUR)
   - Used to compute value-added coefficient and to scale employment coefficient

COUNTRY COVERAGE
- IT, DE, FR, ES, HU, SK, PL

TIME
- Year = 2020 only

PRODUCT CLASSES (mapped from NACE/sector letters)
1 Merchandise (retail margin)      = G
2 Transport                        = H
3 Hospitality (food & accommodation)= I
4 Creative industries (live perf.) = R

NOTES / ASSUMPTIONS
- FTE conversion uses: 1720 hours/year (approx. full-time benchmark)
  FTE = (hours_worked * 1000) / 1720, because THS_HW is in thousand hours.
- We use broad sectors because finer categories are missing for some countries.
*******************************************************************************/

clear all
set more off

*------------------------------*
* User settings
*------------------------------*
local year 2020
local countries "IT DE FR ES HU SK PL"

* Define consistent product labels once
label define categories ///
    1 "Merchandise (retail margin)" ///
    2 "Transport" ///
    3 "Hospitality (food & accommodation)" ///
    4 "Creative industries (live performance)", replace

/*******************************************************************************
PART A — BUILD FTE BY COUNTRY × PRODUCT
Source: nama_10_a64_e.csv
Goal: produce FTE_PER_PRODUCT.dta with variables:
      geo product FTE
*******************************************************************************/

import delimited "nama_10_a64_e.csv", delimiter(comma) bindquote(strict) ///
    varnames(1) encoding(UTF-8) clear

* Keep only:
* - unit THS_HW: thousand hours worked
* - na_item EMP_DC: employees (check definition in dataset metadata)
* - selected countries and year
keep if unit == "THS_HW"
keep if na_item == "EMP_DC"
keep if inlist(geo, "IT","DE","FR","ES","HU","SK","PL")
keep if time_period == `year'

* Map NACE sections to the 4 product classes of interest
gen product = .

* Merchandise / retail margin
replace product = 1 if nace_r2 == "G"

* Transport
replace product = 2 if nace_r2 == "H"

* Hospitality (food + accommodation)
replace product = 3 if nace_r2 == "I"

* Creative industries / tickets (arts, entertainment, recreation)
replace product = 4 if nace_r2 == "R"

label values product categories
drop if missing(product)

* Convert thousand hours worked to FTE:
* values is in THS_HW -> multiply by 1000 to hours,
* then divide by 1720 hours/year to get FTE equivalents
gen FTE = (values * 1000) / 1720

keep geo product FTE
save "FTE_PER_PRODUCT.dta", replace


/*******************************************************************************
PART B — BUILD VALUE ADDED COEFFICIENT AND EMPLOYMENT COEFFICIENT
Source: naio_10_cp1700.csv
Goal:
- Collapse B1G and P1 to country × product
- Compute:
    GVA_COEFFICIENT = B1G / P1
    EMP_COEFFICIENT = FTE / P1
- Save VA_EMP_COEFFICIENT.dta
*******************************************************************************/

import delimited "naio_10_cp1700.csv", delimiter(comma) bindquote(strict) ///
    varnames(1) encoding(UTF-8) clear

* Keep only totals and required aggregates:
* - stk_flow TOTAL (no import/export split)
* - B1G (gross value added) and P1 (output)
* - unit MIO_EUR (million euro)
* - selected countries and year
keep if stk_flow == "TOTAL"
keep if inlist(geo, "IT","DE","FR","ES","HU","SK","PL")
keep if prd_ava == "B1G" | prd_ava == "P1"
keep if unit == "MIO_EUR"
keep if time_period == `year'

* Derive broad sector letter from prd_use
* (Assumption: the 5th character identifies the NACE section letter)
gen sector = ""
replace sector = "G" if substr(prd_use, 5, 1) == "G"
replace sector = "H" if substr(prd_use, 5, 1) == "H"
replace sector = "I" if substr(prd_use, 5, 1) == "I"
replace sector = "R" if substr(prd_use, 5, 1) == "R"

* Map sector to product class
gen product = .
replace product = 1 if sector == "G"   // Merchandise (retail margin)
replace product = 2 if sector == "H"   // Transport
replace product = 3 if sector == "I"   // Hospitality
replace product = 4 if sector == "R"   // Creative industries

label values product categories
drop if missing(product)

* Optional diagnostic: see which prd_use codes feed each product class
tab product prd_use

* Aggregate: sum values by country × product × (B1G/P1)
collapse (sum) values, by(prd_ava geo product)

* Reshape to have separate columns for B1G and P1
reshape wide values, i(geo product) j(prd_ava) string

* Value-added coefficient (dimensionless)
gen GVA_COEFFICIENT = valuesB1G / valuesP1

* Merge in FTE from Part A
merge 1:1 geo product using "FTE_PER_PRODUCT.dta"
drop if _merge == 2   // if any FTE rows have no matching P1/B1G
drop _merge

* Employment coefficient: FTE per million euro of output (FTE / MIO_EUR)
gen EMP_COEFFICIENT = FTE / valuesP1

save "VA_EMP_COEFFICIENT.dta", replace

/*******************************************************************************
OUTPUTS
- FTE_PER_PRODUCT.dta:
    geo product FTE

- VA_EMP_COEFFICIENT.dta:
    geo product valuesB1G valuesP1 GVA_COEFFICIENT FTE EMP_COEFFICIENT
*******************************************************************************/
