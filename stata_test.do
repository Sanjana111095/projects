clear all
set more off

ssc install asgen
*ssc install sumdist



*Problem 1
use "level01.dta", clear
destring state_region hh_size mpce_30_days social_group nss nsc multiplier , replace
generate freq_weight = multiplier/100 if nss == nsc
replace freq_weight = multiplier/200 if nss != nsc
generate hh_freq_weight = freq_weight * hh_size
egen total_population = sum(hh_freq_weight)
generate state_code = int(state_region/10)
label define state_code_l 1 "Jammu & Kashmir" 2 "Himachal Pradesh" 3 "Punjab" 4 "Chandigarh" 5 "Uttaranchal" 6 "Haryana" 7 "Delhi" 8 "Rajasthan" 9 "Uttar Pradesh" 10 "Bihar" 11 "Sikkim" 12 "Arunachal Pradesh" 13 "Nagaland" 14 "Manipur" 15 "Mizoram" 16 "Tripura" 17 "Meghalaya" 18 "Assam" 19 "West Bengal" 20 "Jharkhand" 21 "Orissa" 22 "Chhattisgarh" 23 "Madhya Pradesh" 24 "Gujarat" 25 "Daman & Diu" 26 "Dadra & Nagar Haveli" 27 "Maharashtra" 28 "Andhra Pradesh" 29 "Karnataka" 30 "Goa" 31 "Lakshadweep" 32 "Kerala" 33 "Tamil Nadu" 34 "Pondicherry" 35 "Andaman & Nicobar"
label values state_code state_code_l
replace freq_weight=int(freq_weight)
label variable freq_weight "Individual weights"
label variable hh_freq_weight "Household weights"
label variable total_population "Total Population"
keep mpce_30_days hh_size common_id social_group freq_weight state_code hh_freq_weight total_population
save level01_v2, replace

use "level03.dta", clear
merge m:m common_id using "level01_v2.dta"
label define sex_l 1 "male" 2 "female"
label define social_group_l 1 "scheduled tribe" 2 "scheduled caste" 3 "other backward classes" 9 "others"
drop _merge
destring sex , replace
keep common_id person_srl_no sex social_group freq_weight
label values social_group social_group_l
label values sex sex_l
tabulate social_group [fweight=freq_weight], matcell(freq) matrow(names)

putexcel set test_results.xlsx, sheet("Table1") replace
putexcel A1=("Social Group Code") B1=("Freq.") C1=("Percent")
putexcel A2=matrix(names) B2=matrix(freq) C2=matrix(freq/r(N)*100)

tabulate sex [fweight=freq_weight], matcell(freq) matrow(names)
putexcel set test_results.xlsx, sheet("Table2") modify
putexcel A1=("Gender Code") B1=("Freq.") C1=("Percent")
putexcel A2=matrix(names) B2=matrix(freq) C2=matrix(freq/r(N)*100)


*Problem 2
tab2 social_group sex [fweight = freq_weight], cell nofreq matcell(freq) matrow(names)
putexcel set test_results.xlsx, sheet("Table3") modify
putexcel A1=("Social Group Code") B1=("Male") C1=("Female")
putexcel A2=matrix(names) B2=matrix(freq/r(N)*100)

* Problem 3
use "level01_v2", clear
replace mpce_30_days = mpce_30_days/hh_size
bysort state_code: asgen ampce_30_days = mpce_30_days, weights(hh_freq_weight) by(state_code)
label variable state_code "State"
label variable ampce_30_days "Average monthly per capita consumption expenditure"
egen tag = tag(state_code ampce_30_days)
keep if tag==1
keep state_code ampce_30_days
putexcel set test_results.xlsx, sheet("Table4") modify
export excel using test_results.xlsx, sheet("Table4") firstrow(varlabels)

summarize ampce_30_days, detail
local varmax = r(max)
keep if inlist(float(ampce_30_days),float(`varmax'))
putexcel set test_results.xlsx, sheet("Table5") modify
export excel using test_results.xlsx, sheet("Table5") firstrow(varlabels)

 
* Problem 4
use "level01_v2", clear
replace mpce_30_days = mpce_30_days/hh_size
generate hh_freq_weight_int = floor(hh_freq_weight)
xtile quartile = mpce_30_days [fw=hh_freq_weight_int], nq(10)
asgen avg_mpce_30_days = mpce_30_days, weights(hh_freq_weight) by(quartile)
save "level01_v2", replace

replace hh_freq_weight = floor(hh_freq_weight)
collapse (mean) avg_mpce=mpce_30_days (min) min_mpce=mpce_30_days (max) max_mpce=mpce_30_days [fw=hh_freq_weight], by(quartile)
label variable avg_mpce "Average per capita expenditure"
label variable min_mpce "Minimum per capita expenditure"
label variable max_mpce "Maxixmum per capita expenditure"
putexcel set test_results.xlsx, sheet("Table6") modify
export excel using test_results.xlsx, sheet("Table6") firstrow(varlabels)



*tabstat mpce_30_days [fw=freq_weight], by(quartile) statistics(mean max min range) columns(statistics) save
*sumdist mpce_30_days [fw=freq_weight], n(10)



* Problem 5
use level03, clear
merge m:1 common_id using "level01_v2.dta"
drop _merge
gen common_id2 =  common_id + person_srl_no
sort common_id2
keep common_id2 sex freq_weight hh_freq_weight total_population hh_freq_weight_int quartile avg_mpce_30_days
save "level03_v2", replace

use level04, clear
gen common_id2 =  common_id + person_srl_no
sort common_id2
merge m:m common_id2 using "level03_v2.dta"
drop _merge
destring freq_weight age sex pri_activity_status , replace
keep if age >= 15 & age <= 59
label define sex_l 1 "male" 2 "female"
label values sex sex_l
generate employment_status = 1 if pri_activity_status <=51
replace employment_status = 0 if pri_activity_status > 51
label define employment_l 1 "employed" 0 "unemployed"
label values employment_status employment_l
tabulate employment_status sex if sex == 2 [fweight=freq_weight], cell nofreq matcell(freq) matrow(names)
putexcel set test_results.xlsx, sheet("Table7") modify
putexcel A1=("Employment Status") B1=("Female")
putexcel A2=matrix(names) B2=matrix(freq/r(N)*100)

tabulate employment_status sex if sex == 1 [fweight=freq_weight], cell nofreq matcell(freq) matrow(names)
putexcel set test_results.xlsx, sheet("Table8") modify
putexcel A1=("Employment Status") B1=("Male")
putexcel A2=matrix(names) B2=matrix(freq/r(N)*100)

prtest employment_status, by(sex)


* Problem 6

use level04, clear
gen common_id2 =  common_id + person_srl_no
sort common_id2
merge m:m common_id2 using "level03_v2.dta"
drop _merge
destring freq_weight age sex pri_activity_status , replace
keep if age >= 15 & age <= 59
label define sex_l 1 "male" 2 "female"
label values sex sex_l
generate employment_status = 1 if pri_activity_status <=51
replace employment_status = 0 if pri_activity_status > 51
label define employment_l 1 "employed" 0 "unemployed"
label values employment_status employment_l
egen freq_gender = count(sex), by(sex quartile)
egen freq_gender_employ = count(sex), by(sex quartile employment_status)
gen prop_gender_employ = freq_gender_employ/freq_gender*100
egen tag = tag(prop_gender_employ employment_status sex quartile)
keep if tag==1 & employment_status==1 & sex==2
keep prop_gender_employ employment_status sex quartile avg_mpce_30_days
label variable employment_status "Employment status"
label variable prop_gender_employ "Proportion of females employed"
label variable quartile "Decile group"
label variable avg_mpce_30_days "Avg. monthly per capita consumption expenditure)"

sort quartile
putexcel set test_results.xlsx, sheet("Table9") modify
export excel using test_results.xlsx, sheet("Table9") firstrow(varlabels)
twoway line prop_gender_employ avg_mpce_30_days
graph export "C:\Users\sanjana gupta\Desktop\NSS 61 for STATA TEST\lineplot.png", replace
erase "level01_v2.dta" 
erase "level03_v2.dta"

***trying editing on git****
***trying editing on git branch1****
***trying editing locally*****
