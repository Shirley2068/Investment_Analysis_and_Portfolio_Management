********************************************************************************
********************************FIN3080 HW3*************************************
********************************************************************************

*=======================Q 2=======================*

*** processing ROE ***
import excel "/Users/xuelingzhao/Desktop/3080 data/data and code/FI_T5.xlsx", sheet("sheet1") firstrow clear

//generate quarter
gen date_ymd = date(EndingDateofFiscalYear, "YMD")
gen quarter = qofd(date_ymd)
format quarter %tq

//generate last quarter ROE
destring StockCode, replace
duplicates drop StockCode quarter, force
xtset StockCode quarter
gen lag_ROE = l.ReturnonEquityTTM
drop ReturnonEquityTTM

drop if date_ymd == 18992 // drop 2011-12-31 data
save "/Users/xuelingzhao/Desktop/3080 data/data and code/ROE.dta", replace


*** transforming monthly returns into quarterly returns ***
use "/Users/xuelingzhao/Desktop/3080 data/data and code/return.dta", clear

//generate quarter
gen quarter = qofd(date_ymd)
format quarter %tq

//accumulate monthly return to quarterly return
bys StockCode quarter: gen double QuarterlyReturn = sum(ln(MonthlyReturnWithoutCashDivi +1))
replace QuarterlyReturn = exp(QuarterlyReturn) -1
sort StockCode month
sort StockCode quarter
quietly by StockCode quarter: gen dup = cond(_N==1,0,_n)
keep if dup == 3
drop dup lag_return MonthlyReturnWithoutCashDivi
save "/Users/xuelingzhao/Desktop/3080 data/data and code/Quarterly_return.dta", replace

//merging data
use "/Users/xuelingzhao/Desktop/3080 data/data and code/ROE.dta", clear
merge 1:1 quarter StockCode using "/Users/xuelingzhao/Desktop/3080 data/data and code/Quarterly_return.dta"
keep if _merge == 3
drop _merge

//generate ROE deciles by quarter
bys quarter: egen ROE_decile = xtile(lag_ROE), nq(10)
bys quarter ROE_decile: egen quarter_return = mean(QuarterlyReturn)
drop QuarterlyReturn
duplicates drop quarter ROE_decile, force
drop if ROE_decile == .


//generate cumulative return
sort ROE_decile quarter
bys ROE_decile: gen double cumulative_return = sum(ln(quarter_return +1))
replace cumulative_return = exp(cumulative_return) -1
tostring ROE_decile, gen(Portfolio)
replace Portfolio = "Portfolio " + Portfolio

* draw time series
xtset ROE_decile quarter
xtline cumulative_return, overlay title("Time Series for Ten Portfolios")

//generate decile-month panel for average portfolio returns
bys ROE_decile: egen avg_return = mean(quarter_return)
duplicates drop ROE_decile, force
graph bar avg_return, over(ROE_decile)
