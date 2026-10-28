* ==============================================================================
* Poverty and property theft in Iran's provinces, 1390-1399
* Course project, Social Economics, Sharif University of Technology (2024)
* Zahra Aghaei
*
* Runs the whole project in order. Set ROOT to the folder of this repository.
* ==============================================================================

clear all
set more off
version 17

global ROOT ""                      // e.g. "C:/Users/me/poverty-property-crime-iran"
if "$ROOT" == "" global ROOT "`c(pwd)'"

global HIES   "$ROOT/data/hies"     // SumR90.xlsx ... SumU99.xlsx
global CRIME  "$ROOT/data/crime_1390_1400.xlsx"
global TMP    "$ROOT/output/temp"
global OUT    "$ROOT/output"

cap mkdir "$ROOT/output"
cap mkdir "$TMP"
cap mkdir "$OUT/figures"
cap mkdir "$OUT/tables"

* estout is used for the regression tables (ssc install estout)
cap which esttab
if _rc ssc install estout, replace

do "$ROOT/code/01_hies_province_panel.do"
do "$ROOT/code/02_crime_panel.do"
do "$ROOT/code/03_analysis.do"
