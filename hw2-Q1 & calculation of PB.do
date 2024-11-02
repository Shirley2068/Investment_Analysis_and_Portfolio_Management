********************************************************************************
********************************FIN3080 HW2*************************************
********************************************************************************

*======================================================*
*-------Data processing and transformation-------------*
*======================================================*


*=======================Computing PB Ratio=======================*
//PB = market value/ total assets - total liability

//process market value
import excel "/Users/xuelingzhao/Desktop/3080 data/total market value.xlsx", sheet("sheet1") firstrow clear
gen date_ymd = date(TradingMonth, "YM")
format date_ymd %td
gen date_yq = qofd(date_ymd)
format date_yq %tq

* 考虑信息滞后性因此market value应对应上一季度统计的total equity
gen FiscalQuarter = date_yq -1
format FiscalQuarter %tq

* scale market value
replace TotalMarketValue = TotalMarketValue*1000 

duplicates drop StockCode date_ymd, force
drop date_ymd
save "/Users/xuelingzhao/Desktop/3080 data/processed market value.dta", replace


//process total asset and total liability
import excel "/Users/xuelingzhao/Desktop/3080 data/TA & TL.xlsx", sheet("sheet1") firstrow clear

* process quarter
gen date_ymd = date(EndingDateofStatistics, "YMD")
gen date_yq = qofd(date_ymd)
format date_yq % tq
gen FiscalQuarter = date_yq

* generate total equity
gen TotalEquity = TotalAssets - TotalLiabilities

* delete reduntant variables
duplicates drop StockCode date_yq, force
drop StockShortName TotalAssets TotalLiabilities date_ymd

save "/Users/xuelingzhao/Desktop/3080 data/process_TotalEquity.dta", replace

//merge
use "/Users/xuelingzhao/Desktop/3080 data/processed market value.dta", clear
merge m:1 StockCode FiscalQuarter using "/Users/xuelingzhao/Desktop/3080 data/process_TotalEquity.dta"
drop if _merge == 1
drop if _merge == 2
drop _merge

//calculate P/B ratio
gen PBratio = TotalMarketValue / TotalEquity
save "/Users/xuelingzhao/Desktop/3080 data/P:B ratio.dta", replace

*=======================Q 1=======================*
//process volatility
import excel "/Users/xuelingzhao/Desktop/3080 data/2010.10.31 volatility.xlsx", sheet("sheet1") firstrow clear
gen quarter_volatility = ReturnVolatility^(1/4)
gen date_ymd = date(TradingDate, "YMD")
gen date_yq = qofd(date_ymd)
format date_yq % tq

duplicates drop StockCode date_yq, force
drop ReturnVolatility date_ymd

save "/Users/xuelingzhao/Desktop/3080 data/processed_volatility.dta", replace

//process ROE
import excel "/Users/xuelingzhao/Desktop/3080 data/2010.12.31 ROE.xlsx", sheet("sheet1") firstrow clear
gen date_ymd = date(EndingDateofFiscalYear, "YMD")
gen date_yq = qofd(date_ymd)
format date_yq % tq

duplicates drop StockCode date_yq, force
drop StockShortName date_ymd

save "/Users/xuelingzhao/Desktop/3080 data/processed_ROE.dta", replace

//merge
use "/Users/xuelingzhao/Desktop/3080 data/P:B ratio.dta", clear
keep if date_yq == 203 //选取2010q4季度数据
merge m:1 StockCode date_yq using "/Users/xuelingzhao/Desktop/3080 data/processed_volatility.dta"
drop if _merge == 1
drop if _merge == 2
drop _merge
merge m:1 StockCode date_yq using "/Users/xuelingzhao/Desktop/3080 data/processed_ROE.dta"
drop if _merge == 1
drop if _merge == 2
drop _merge
gen date_ymd = date(TradingMonth, "YM")
keep if date_ymd == 18597 //选取2010 12月的P B当作2010q4的PB

//regression
reg PBratio quarter_volatility ReturnonEquityTTM
reg PBratio ReturnonEquityTTM
reg PBratio quarter_volatility

//将PB ratio小于零的drop后regression
drop if PBratio < 0
reg PBratio quarter_volatility ReturnonEquityTTM
reg PBratio ReturnonEquityTTM
reg PBratio quarter_volatility
