********************************************************************************
********************************FIN3080 HW5*************************************
********************************************************************************

***========================EPS data Processing===============================***
import excel "/Users/xuelingzhao/Desktop/3080data/EPS 2010-12-31.xlsx", sheet("sheet1") firstrow clear

*===1.2 Exclude parent statement ===*    
drop if CodeforStatementType == "B"
drop CodeforStatementType

*===1.3 Convert firm-quarter panel into firm-semi-annual panel ===*

// keep semi-annual and annual reports
gen date_ymd =date(EndingDateofStatistics, "YMD")
gen yq = qofd(date_ymd)
format yq %tq
gen quarter = quarter(date_ymd)
drop if quarter == 1 | quarter == 3
gen semi_annual = hofd(date_ymd)
format semi_annual %th

// collapse data from firm-quarter panel to firm-semi-annual panel
destring StockCode, replace
xtset StockCode semi_annual
gen EPS_lag = l.EarningsperShare1
replace EPS_lag = 0 if quarter == 2
replace EarningsperShare1 = EarningsperShare1 - EPS_lag 
rename EarningsperShare1 EPS

*=== 1.4 derive unexpected earnings(UE) ===*
sort StockCode semi_annual
gen EPS_lag2 = EPS[_n-2]
bysort StockCode: gen UE = EPS - EPS_lag2

*=== 1.5 derive standardize unexpected earnings(SUE) ===*
//calculate mean of four UE
gen UE_lag1 = l.UE
gen UE_lag2 = l.UE_lag1
gen UE_lag3 = l.UE_lag2
gen mean_UE = (UE + UE_lag1 + UE_lag2 + UE_lag3)/4

//calculate standard deviation of UEs
gen std_UE = sqrt(((UE-mean_UE)^2 +(UE_lag1-mean_UE)^2 +(UE_lag2-mean_UE)^2 + (UE_lag3-mean_UE)^2)/4)

// generate SUE
bysort StockCode: gen SUE = UE/std_UE

*=== 1.6 derive SUE deciles ===*
//drop redundant varibales
drop EPS_lag EPS_lag2 UE_lag1 UE_lag2 UE_lag3 mean_UE std std_UE

//drop empty value (keep time over 2013/1/1-2022/12/31)
drop if SUE ==.

//derive deciles
bys semi_annual: egen SUE_decile = xtile(SUE), nq(10)
save "/Users/xuelingzhao/Desktop/3080data/processed_EPS.dta", replace

*=== 1.7 statement annoucement dates ===*
import excel "/Users/xuelingzhao/Desktop/3080data/AnnouncementDate.xlsx", sheet("sheet1") firstrow clear
destring StockCode, replace
drop StockAcronym 
save "/Users/xuelingzhao/Desktop/3080data/AnnouncementDate.dta", replace

*=== 1.8 merge announcement dates to the EPS data ===*
use "/Users/xuelingzhao/Desktop/3080data/processed_EPS.dta", clear

// merge
merge 1:1 StockCode EndingDateofStatistics using "/Users/xuelingzhao/Desktop/3080data/AnnouncementDate.dta"
keep if _merge == 3
drop _merge

// exclude firms with ST and PT
drop if strmatch( StockShortName, "*ST*")
drop if strmatch( StockShortName, "*PT*")

// drop redundant variables
drop ReportType

save "/Users/xuelingzhao/Desktop/3080data/processed_EPS.dta", replace


***================== Stock return data Processing ==========================***
//merge data
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/StockReturn.dta", replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr1.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/StockReturn2.dta", replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr2.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/SR3.dta", replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr3.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/sr4.dta",replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr4.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/sr5.dta",replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr5.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/sr6.dta",replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr6.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/sr7.dta",replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr7.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/sr8.dta",replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr8.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/sr9.dta",replace
import excel "/Users/xuelingzhao/Desktop/3080data/TRD_Dalyr9.xlsx", sheet("sheet1") firstrow clear
save "/Users/xuelingzhao/Desktop/3080data/sr10.dta",replace
append using "/Users/xuelingzhao/Desktop/3080data/SR3.dta""/Users/xuelingzhao/Desktop/3080data/sr4.dta""/Users/xuelingzhao/Desktop/3080data/sr5.dta""/Users/xuelingzhao/Desktop/3080data/sr6.dta""/Users/xuelingzhao/Desktop/3080data/sr7.dta""/Users/xuelingzhao/Desktop/3080data/sr8.dta""/Users/xuelingzhao/Desktop/3080data/sr9.dta""/Users/xuelingzhao/Desktop/3080data/StockReturn.dta""/Users/xuelingzhao/Desktop/3080data/StockReturn2.dta"

*=== 2.2 exclude non-mainboard stocks ===*
//keep the stock whose code start with 000-,60-
keep if substr(StockCode,1,3) == "000" | substr(StockCode,1,2) == "60"

*=== 2.3 merge market return data to individual stock data ===*
//generate Year-Month-Day data for individual stock data
destring StockCode, replace
gen date_ymd =date(TradingDate, "YMD")
save "/Users/xuelingzhao/Desktop/3080data/processed_individual_data.dta", replace

//process market return data
import excel "/Users/xuelingzhao/Desktop/3080data/MarketReturns_equal.xlsx", sheet("sheet1") firstrow clear

//keep the aggregate return for SSE-SZSE A share market
keep if AggregatedMarketType == 5 
drop AggregatedMarketType

//generate Year-Month-Day data for individual stock data
gen date_ymd = date(TradingDate, "YMD")

merge 1:m date_ymd using "/Users/xuelingzhao/Desktop/3080data/processed_individual_data.dta"
keep if _merge == 3
drop _merge

*=== 2.4 derive daily abnormal returns ===*
bysort StockCode date_ymd: gen AR = DailyReturnWithoutCashDivide - DailyAggregatedMarketReturns
save "/Users/xuelingzhao/Desktop/3080data/processed_stock_return.dta", replace


***========================= Main Analysis ==================================***

*===3.1 merge EPS to individual stock return datas ===*
//process EPS
use "/Users/xuelingzhao/Desktop/3080data/processed_EPS.dta", clear
keep StockCode EndingDateofStatistics date_ymd SUE_decile AnnouncementDate
gen event_date = date(AnnouncementDate, "YMD")
gen year = year(event_date)
drop if year < 2015
duplicates drop StockCode event_date, force
save "/Users/xuelingzhao/Desktop/3080data/1_processed_EPS.dta", replace

//count  how many event dates there are for each company
use "/Users/xuelingzhao/Desktop/3080data/AnnouncementDate.dta", clear
sort StockCode
by StockCode: gen eventcount = _N
by StockCode: keep if _n == 1
sort StockCode
keep StockCode eventcount

save "/Users/xuelingzhao/Desktop/3080data/100_eventcount.dta", replace

// merge the number of events with stock return
use "/Users/xuelingzhao/Desktop/3080data/processed_stock_return.dta", clear
sort StockCode
merge m:1 StockCode using "/Users/xuelingzhao/Desktop/3080data/100_eventcount.dta"
keep if _merge ==3
drop _merge


expand eventcount
drop eventcount
sort StockCode date_ymd
by StockCode date_ymd: gen set =_n
sort StockCode set
save "/Users/xuelingzhao/Desktop/3080data/100_processed_stock_return.dta", replace

use "/Users/xuelingzhao/Desktop/3080data/AnnouncementDate.dta", clear
sort StockCode
by StockCode: gen set = _n
sort StockCode set
save "/Users/xuelingzhao/Desktop/3080data/100_2_AnnouncementDate.dta", replace

use "/Users/xuelingzhao/Desktop/3080data/100_processed_stock_return.dta", clear
merge m:1 StockCode set using "/Users/xuelingzhao/Desktop/3080data/100_2_AnnouncementDate.dta"
list StockCode if _merge == 2
keep if _merge == 3
drop _merge
egen group_id = group(StockCode set)

sort group_id date_ymd
by group_id: gen datenum = _n
gen event_date = date(AnnouncementDate, "YMD")
by group_id: gen target = datenum if date_ymd == event_date
egen td = min (target), by(group_id)
drop target
gen dif_trading = datenum - td //difference in trading days
gen dif = event_date-date_ymd // difference in calender days
gen year = year(event_date)
drop if year < 2015
drop year


*=== 3.2 derive cumulative abnormal returns for individual stocks ===*
keep if dif_trading>=-120 & dif_trading <=120
sort StockCode event_date dif_trading
bys StockCode event_date: gen CAR = sum(AR)
merge m:1 StockCode event_date using "/Users/xuelingzhao/Desktop/3080data/1_processed_EPS.dta"
keep if _merge == 3
drop _merge

*=== 3.3 derive cumulative abnormal returns for SUE portfolios ===*
bys dif_trading SUE_decile event_date: egen portfolio_CAR = mean(CAR)


*=== 3.4 Aggregate CARs within SUE portfolios on event time index===*
bys SUE_decile dif_trading: egen aggregate_CAR = mean(portfolio_CAR)
duplicates drop aggregate_CAR dif_trading, force

xtset SUE_decile dif_trading
xtline aggregate_CAR, overlay title("Cumulative Abnormal Returns(CARS) by SUE deciles") ytitle("Cumulative Abnormal Return") xtitle("Event window")


