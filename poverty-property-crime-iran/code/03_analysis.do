* ==============================================================================
* 03  Merge, figures and regressions
*
* Question: do provinces with a larger share of poor people have more property
* theft? Panel of 31 provinces x 10 years (1390-1399), province fixed effects.
* ==============================================================================

use "$TMP/hies_province.dta", clear
merge 1:1 province year using "$TMP/crime_province.dta", assert(match) nogen

* rates per 10,000 people
foreach v of varlist theft_* {
    gen rate_`=substr("`v'", 7, .)' = `v' / pop * 10000
}
label var rate_total "Property theft per 10,000 people"

gen poor_rich = share_dec1_2 / share_dec9_10
label var poor_rich "Two poorest deciles / two richest deciles"

save "$OUT/province_panel.dta", replace

* ---- figures ------------------------------------------------------------------
graph hbox rate_total, over(province, sort(1) descending label(labsize(vsmall))) ///
    ytitle("Property thefts per 10,000 people") ///
    title("Property theft by province, 1390-1399", size(medsmall))
graph export "$OUT/figures/property_theft_by_province.png", width(2000) replace

foreach t in car carparts motorcycle home shop {
    graph hbox rate_`t', over(province, sort(1) descending label(labsize(vsmall))) ///
        ytitle("Cases per 10,000 people") title("`t'", size(medsmall))
    graph export "$OUT/figures/theft_`t'.png", width(1600) replace
}

* ---- regressions --------------------------------------------------------------
* Province fixed effects absorb anything about a province that does not change
* over the decade (size of the cities, policing traditions, reporting habits).
* Standard errors are clustered by province: 31 clusters.
xtset province year

local controls literate_share earner_share hh_size head_unemp

eststo clear
eststo: xtreg rate_total share_dec1,                 fe vce(cluster province)
eststo: xtreg rate_total share_dec1   `controls',    fe vce(cluster province)
eststo: xtreg rate_total share_dec1_2 `controls',    fe vce(cluster province)
eststo: xtreg rate_total share_dec1_3 `controls',    fe vce(cluster province)
* adding year effects: national shocks (inflation, sanctions) hit every province
eststo: xtreg rate_total share_dec1   `controls' i.year, fe vce(cluster province)
eststo: xtreg rate_total share_dec1_2 share_dec9_10 poor_rich `controls', ///
        fe vce(cluster province)

esttab using "$OUT/tables/main_results.rtf", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label ///
    indicate("Year FE = *.year") ///
    stats(N r2_w, labels("Observations" "Within R-squared")) ///
    title("Property theft per 10,000 people and the share of poor households")

esttab, b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label indicate("Year FE = *.year") ///
    stats(N r2_w)
