* ==============================================================================
* 02  Property theft by province and year
*
* Input : crime_1390_1400.xlsx, built by hand from the SCI statistical yearbooks
*         (registered theft cases by province). Column names are in Persian.
* Output: $TMP/crime_province.dta
* ==============================================================================

import excel "$CRIME", firstrow clear
rename Year year
rename شرح2 province_fa
drop if year == 1400                    // HIES side stops at 1399

* The yearbook tables mix Arabic and Persian letters (ي/ی, ك/ک) and extra spaces,
* which is why some provinces did not match in the first version of this code.
replace province_fa = ustrregexra(province_fa, "ي", "ی")
replace province_fa = ustrregexra(province_fa, "ك", "ک")
replace province_fa = ustrtrim(itrim(province_fa))
gen key = subinstr(province_fa, " ", "", .)     // compare names without spaces

gen province = .
local i = 0
foreach p in "مرکزی" "گیلان" "مازندران" "آذربایجان شرقی" "آذربایجان غربی" ///
             "کرمانشاه" "خوزستان" "فارس" "کرمان" "خراسان رضوی" "اصفهان"  ///
             "سیستان و بلوچستان" "کردستان" "همدان" "چهارمحال و بختیاری"  ///
             "لرستان" "ایلام" "کهگیلویه و بویراحمد" "بوشهر" "زنجان"      ///
             "سمنان" "یزد" "هرمزگان" "تهران" "اردبیل" "قم" "قزوین"       ///
             "گلستان" "خراسان شمالی" "خراسان جنوبی" "البرز" {
    replace province = `i' if key == subinstr("`p'", " ", "", .)
    local ++i
}
* stop here if any province name is still unmatched
assert !missing(province)

* ---- theft categories ---------------------------------------------------------
* Total property theft = sum of all theft columns in the yearbook table.
local thefts سرقتسایر سرقتقایق احشام لوازمووسایلداخلخودرو موتورسیکلت اتومبیل ///
             مغاره منزل اماکندولتی اماکنخصوصی سرقتاماکنصنعتی سرقتسایراماکن
destring `thefts', replace force

egen theft_total = rowtotal(`thefts')
rename (اتومبیل لوازمووسایلداخلخودرو موتورسیکلت منزل مغاره) ///
       (theft_car theft_carparts theft_motorcycle theft_home theft_shop)

keep province year theft_*
isid province year
save "$TMP/crime_province.dta", replace
