************************************************************************
*** This is a suggested solution to Homework 1 Question 1 (FIN 3080) ***
*** Date: 2023/3/5  Author: Sijie Wang (sijiewang@link.cuhk.edu.cn) ****
************************************************************************

*** 0. Set program options and specify raw data path ***

* Set the following option off to enable uninterrupted screen outputs *
set more off  // Set this option off to enable 

* Change the following path to your own path to the raw data *
global path_to_data ="/Users/sjwang222/Desktop/Term6/FIN3080/hw1/sol" 

* Change current working directory to the raw data folder *
cd $path_to_data

*** Step 1. Load & process monthly individual stock return data ***

* Import raw individual stock return data *
insheet using "individual_stock.csv", clear

* Save raw individual stock return data as .dta *
save raw_stock_return, replace

* Rename variables *
rename stkcd stock_code
rename trdmnt raw_date
rename mclsprc price
rename msmvttl market_value
rename markettype market

* Exculde B-share stocks *
drop if market == 2 | market == 8

* Generate market type indicator for main board,  *
gen market_type = "Main"
replace market_type = "GEM" if market == 16| market == 32
replace market_type = "SME" if stock_code >= 2000 & stock_code < 3000

* Convert original string dates to Year-Month dates *
gen date_ym = monthly(raw_date, "YM")

* Format year-month dates *
format date_ym %tm

* Construct year-quarter dates from year-month dates *
gen date_yq = qofd(dofm(date_ym))
format date_yq %tq

* Keep obs at end of quarters only (in other words, the last obs for each stock in each quarter)  *
keep if mod(month(dofm(date_ym)), 3) == 0 

* Claim data set structure as stock-quarter panel *
xtset stock_code date_yq

* Generate quarterly stock return *
gen stock_ret = ((price - l.price)/(l.price))*100

* Recover market cap into yuan *
replace market_value = market_value * 1000

* Drop unwanted variables *
drop raw_date market date_ym

* Save processed data *
duplicates drop stock_code date_yq, force
save processed_stock_return, replace



*** Step 2. Load & process quarterly balance sheet data *** 

* Import raw balance sheet data *
insheet using "balance_sheet.csv", clear

* Save raw balance sheet data as .dta *
save raw_balance_sheet, replace

* Rename variables *
rename stkcd stock_code
rename accper raw_date
rename typrep statement_type
rename a001000000 total_asset
rename a002000000 total_liabilities

* Convert original string dates to Year-Month-Day dates *
gen date_ymd = date(raw_date, "YMD")

* Format year-month dates *
format date_ymd %td

* Construct year-quarter dates from year-month dates *
gen date_yq = qofd(date_ymd)
format date_yq %tq

* Keep necessary variables *
keep stock_code date_yq total_asset total_liabilities

* Save processed balance sheet data *
duplicates drop stock_code date_yq, force
save processed_balance_sheet, replace



*** Step 3. Loan & process quarterly income statement data ***

* Import raw income statement data *
insheet using "income_statement.csv", clear

* Save raw income statement data as .dta *
save raw_income_statement, replace

* Rename variables *
rename stkcd stock_code
rename accper raw_date
rename typrep statement_type
rename b001000000 total_profit
rename b003000000 earnings_per_share
rename b001216000 rd_expense

* Convert original string dates to Year-Month-Day dates *
gen date_ymd = date(raw_date, "YMD")

* Format year-month dates *
format date_ymd %td

* Construct year-quarter dates from year-month dates *
gen date_yq = qofd(date_ymd)
format date_yq %tq

* Keep necessary variables *
keep stock_code date_yq total_profit earnings_per_share rd_expense

* Save processed balance sheet data *
duplicates drop stock_code date_yq, force
save processed_income_sheet, replace


*** Step 4. Load & process quarterly company profile data ***

* Import raw income statement data *
insheet using "company_profile.csv", clear

* Save raw income statement data as .dta *
save raw_company_profile, replace

* Rename variables *
rename stkcd stock_code
rename listdt raw_list_date
rename estbdt raw_est_date

* Convert original string dates to Year-Month-Day dates *
gen est_date_ymd = date(raw_est_date, "YMD")

* Format year-month dates *
format est_date_ymd %td

* Construct year-quarter dates from year-month dates *
gen est_date_yq = qofd(est_date_ymd)
format est_date_yq %tq

* Keep necessary variables *
keep stock_code est_date_yq

* Save processed balance sheet data *
duplicates drop stock_code, force
save processed_company_profile, replace


*** Step 4. Load & process relative value index data ***

* Import raw income statement data *
insheet using "relative_value_index.csv", clear

* Save raw income statement data as .dta *
save raw_relative_value_index, replace

* Rename variables *
rename stkcd stock_code
rename f100102b pe_ratio
rename f100401a pb_ratio
rename accper raw_date

* Convert original string dates to Year-Month-Day dates *
gen date_ymd = date(raw_date, "YMD")

* Format year-month dates *
format date_ymd %td

* Construct year-quarter dates from year-month dates *
gen date_yq = qofd(date_ymd)
format date_yq %tq

* Keep necessary variables *
keep stock_code date_yq pe_ratio pb_ratio

* Save processed balance sheet data *
duplicates drop stock_code date_yq, force
save processed_relative_value_index, replace



*** Step 5. Merge all data sets to stock return data set ***

* Load processed individual stock return data (obtained from Step 1.)*
use processed_stock_return, clear

* Merge processed balance sheet data onto individual stock return data on "stock_code" & "date_yq" (1:1 merging) *
merge 1:1 stock_code date_yq using processed_balance_sheet
drop if _merge == 2
drop _merge

* Merge processed income sheet data onto individual stock return data on "stock_code" & "date_yq" (1:1 merging) *
merge 1:1 stock_code date_yq using processed_income_sheet
drop if _merge == 2
drop _merge

* Merge processed company profile data onto individual stock return data on "stock_code" (m:1 merging) *
merge m:1 stock_code using processed_company_profile
drop if _merge == 2
drop _merge

* Merge relative value index data onto individual stock return data on "stock_code" (1:1 merging) *
merge m:1 stock_code date_yq using processed_relative_value_index
drop if _merge == 2 
drop _merge

* Calculate firm age over time *
gen firm_age = date_yq - est_date_yq

* Scale large numbers by 10^6 *
replace market_value = market_value/100000
replace total_asset = total_asset/100000
replace total_profit = total_profit/100000
replace rd_expense = rd_expense/1000000

* Save merged stock-quarter panel data *
save merged_stock_quarter_panel, replace

*** Step 6. Summarize variables of interest ***

* Load merged stock-quarter panel data *
use merged_stock_quarter_panel, clear

** By market summarize variables of interest **
* Main board *
estpost summarize stock_ret market_value firm_age total_asset rd_expense total_profit pe_ratio pb_ratio if market_type == "Main", detail
eststo ss_main
esttab ss_main, cell(b(fmt(2)) "count mean p25 p50 p75 sd" ), using ss_main.csv, replace
* GEM board *
estpost summarize stock_ret market_value firm_age total_asset rd_expense total_profit pe_ratio pb_ratio if market_type == "GEM", detail
eststo ss_gem
esttab ss_gem, cell(b(fmt(2)) "count mean p25 p50 p75 sd" ), using ss_gem.csv, replace
* SME board *
estpost summarize stock_ret market_value firm_age total_asset rd_expense total_profit pe_ratio pb_ratio if market_type == "SME", detail
eststo ss_sme
esttab ss_sme, cell(b(fmt(2)) "count mean p25 p50 p75 sd" ), using ss_sme.csv, replace

* Alternative method with 'bysort' *
bys market_type: summarize stock_ret market_value firm_age total_asset rd_expense total_profit pe_ratio pb_ratio, detail



