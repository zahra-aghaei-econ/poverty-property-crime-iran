* ==============================================================================
* 01  Province-year panel from the Household Income and Expenditure Survey
*
* Input : SumR<yy>.xlsx and SumU<yy>.xlsx (rural / urban summary files), 1390-1399
* Output: $TMP/hies_province.dta, one row per province and year
*
* Variables used from the summary files (names as in SCI's files):
*   ADDRESS  household address code; digits 2-3 are the province code
*   weight   household sampling weight
*   C01      household size
*   C02      number of literate members
*   C05      number of members with an income
*   C09      national expenditure decile of the household (0 = poorest ... 9)
*   A06      activity status of the household head (2 = unemployed)
* Please check these codes against the codebook of your copy of the data.
* ==============================================================================

local poorest 0      // code of the first (poorest) decile in C09

forvalues y = 90/99 {
    foreach area in R U {

        import excel "$HIES/Sum`area'`y'.xlsx", sheet("Sum`area'`y'") firstrow clear

        * ADDRESS comes in as a number in some years and as text in others.
        * The format matters: without %12.0f the leading digits get lost (1394).
        cap confirm string variable ADDRESS
        if _rc tostring ADDRESS, replace format(%12.0f)

        gen byte province = real(substr(ADDRESS, 2, 2))
        gen byte rural    = ("`area'" == "R")

        keep  ADDRESS province rural weight C01 C02 C05 C09 A06
        destring weight C01 C02 C05 C09 A06, replace force

        tempfile f_`area'
        save `f_`area''
    }

    use `f_R', clear
    append using `f_U'
    gen int year = 1300 + `y'
    tempfile y`y'
    save `y`y''
}

use `y90', clear
forvalues y = 91/99 {
    append using `y`y''
}

* ---- household-level measures -------------------------------------------------
drop if missing(province, weight, C01) | C01 == 0
assert inrange(province, 0, 30)
assert inrange(C09, 0, 9) if !missing(C09)

gen double persons   = weight * C01            // people this household stands for
gen literate_share   = C02 / C01
gen earner_share     = C05 / C01
gen byte head_unemp  = (A06 == 2) if !missing(A06)

gen byte dec1    = (C09 == `poorest')
gen byte dec1_2  = inrange(C09, `poorest', `poorest' + 1)
gen byte dec1_3  = inrange(C09, `poorest', `poorest' + 2)
gen byte dec9_10 = inrange(C09, `poorest' + 8, `poorest' + 9)

* ---- province-year averages ---------------------------------------------------
* Decile shares are shares of people, so they are weighted by persons.
* Household characteristics are weighted by the household weight.
preserve
    collapse (sum) pop = persons ///
             (mean) share_dec1 = dec1 share_dec1_2 = dec1_2 ///
                    share_dec1_3 = dec1_3 share_dec9_10 = dec9_10 ///
             [pw = persons], by(province year)
    tempfile shares
    save `shares'
restore

collapse (mean) literate_share earner_share hh_size = C01 head_unemp ///
         [pw = weight], by(province year)
merge 1:1 province year using `shares', assert(match) nogen

label define province ///
     0 "Markazi"            1 "Gilan"              2 "Mazandaran"      ///
     3 "East Azerbaijan"    4 "West Azerbaijan"    5 "Kermanshah"      ///
     6 "Khuzestan"          7 "Fars"               8 "Kerman"          ///
     9 "Razavi Khorasan"   10 "Isfahan"           11 "Sistan & Baluchestan" ///
    12 "Kurdistan"         13 "Hamedan"           14 "Chaharmahal & Bakhtiari" ///
    15 "Lorestan"          16 "Ilam"              17 "Kohgiluyeh & Boyer-Ahmad" ///
    18 "Bushehr"           19 "Zanjan"            20 "Semnan"         ///
    21 "Yazd"              22 "Hormozgan"         23 "Tehran"         ///
    24 "Ardabil"           25 "Qom"               26 "Qazvin"         ///
    27 "Golestan"          28 "North Khorasan"    29 "South Khorasan" ///
    30 "Alborz"
label values province province

label var pop             "Population (sum of weights x household size)"
label var share_dec1      "Share of people in the poorest national decile"
label var share_dec1_2    "Share of people in the two poorest deciles"
label var share_dec1_3    "Share of people in the three poorest deciles"
label var share_dec9_10   "Share of people in the two richest deciles"
label var literate_share  "Literate members / household size"
label var earner_share    "Members with income / household size"
label var hh_size         "Average household size"
label var head_unemp      "Share of households with an unemployed head"

isid province year
assert _N == 31 * 10
save "$TMP/hies_province.dta", replace
