********************************************************************************
********************************FIN3080 HW4*************************************
********************************************************************************

***============================Data Processing===============================***

*===weekly individual stock return===*
import excel "/Users/xuelingzhao/Desktop/3080 data/weekly ret without reinvested.xlsx", sheet("sheet1") firstrow clear
rename WeeklyReturnWithoutCashDivid week_return
drop if week_ret ==.

//generate week variable
gen week = weekly(TradingWeek, "YW")
format week %tw
drop if week ==.

save "/Users/xuelingzhao/Desktop/3080 data/weekly stock return.dta", replace

*===weekly aggregated market return===*
import excel "/Users/xuelingzhao/Desktop/3080 data/aggregated mkt return equal-weighted.xlsx", sheet("sheet1") firstrow clear

//leaving only SSE-SZSE A share market return
keep if MarketType == 5
drop MarketType

//generate week variable
gen week = weekly(TradingWeek, "YW")
format week %tw
drop if week ==.

save "/Users/xuelingzhao/Desktop/3080 data/weekly aggregated market return.dta", replace

*===weekly risk free rate===*
import excel "/Users/xuelingzhao/Desktop/3080 data/weekly risk free rate.xlsx", sheet("sheet1") firstrow clear

drop RiskFreeBenchmarkRate
//generate week variable
gen date_ymd =date(StatisticalDate, "YMD")
gen week = wofd(date_ymd)
format week %tw
drop date_ymd StatisticalDate

//drop duplicates
duplicates drop WeeklizedRiskFreeRate week, force

save "/Users/xuelingzhao/Desktop/3080 data/weekly risk free rate.dta", replace

*===Merging data===*
use "/Users/xuelingzhao/Desktop/3080 data/weekly stock return.dta", clear
merge m:1 week using "/Users/xuelingzhao/Desktop/3080 data/weekly aggregated market return.dta"
keep if _merge == 3
drop _merge
merge m:1 week using "/Users/xuelingzhao/Desktop/3080 data/weekly risk free rate.dta"
keep if _merge ==3
drop _merge
save "/Users/xuelingzhao/Desktop/3080 data/processed data.dta", replace

***========================4.1.1 计算个股beta系数==============================***
use "/Users/xuelingzhao/Desktop/3080 data/processed data.dta", clear
destring StockCode, replace

//按时间分为3期，两年为一期
gen week_decile =3 
replace week_decile=2 if week <= 3171
replace week_decile = 1 if week <=3067
save "/Users/xuelingzhao/Desktop/3080 data/grouped data.dta", replace

//用第一期数据计算个股beta数据
use "/Users/xuelingzhao/Desktop/3080 data/grouped data.dta", clear
keep if week_decile == 1
asreg week_ret WeeklyAggregatedMarketReturns, by(StockCode)
rename _b_WeeklyAggregatedMarketReturns beta_i
rename _b_cons alpha_i
duplicates drop beta_i alpha_i StockCode, force
drop _Nobs _R2 _adjR2 alpha_i
save "/Users/xuelingzhao/Desktop/3080 data/个股beta系数.dta", replace

***========================4.1.2 构造股票组合==================================***
use "/Users/xuelingzhao/Desktop/3080 data/个股beta系数.dta", clear
//按照用第一期数据所得的beta 构造股票组合
egen beta_decile = xtile(beta_i), nq(10)
save "/Users/xuelingzhao/Desktop/3080 data/分组好的个股beta系数.dta", replace

//将beta数据merge进第二期数据
use "/Users/xuelingzhao/Desktop/3080 data/grouped data.dta", clear
keep if week_decile == 2

merge m:1 StockCode using "/Users/xuelingzhao/Desktop/3080 data/分组好的个股beta系数.dta"
keep if _merge == 3
drop _merge

//根据组合，对第二期样本数据进行time series 回归
bys beta_decile week: egen portpolio_return = mean(week_ret)
duplicates drop beta_decile week portpolio_return, force
gen return_premium = portpolio_return - WeeklizedRiskFreeRate
gen risk_premium = WeeklyAggregatedMarketReturns - WeeklizedRiskFreeRate
asreg return_premium risk_premium, by(beta_decile)

//记录数据
reg return_premium risk_premium if beta_decile == 1
est store m1
reg return_premium risk_premium if beta_decile == 2
est store m2
reg return_premium risk_premium if beta_decile == 3
est store m3
reg return_premium risk_premium if beta_decile == 4
est store m4
reg return_premium risk_premium if beta_decile == 5
est store m5
reg return_premium risk_premium if beta_decile == 6
est store m6
reg return_premium risk_premium if beta_decile == 7
est store m7
reg return_premium risk_premium if beta_decile == 8
est store m8
reg return_premium risk_premium if beta_decile == 9
est store m9
reg return_premium risk_premium if beta_decile == 10
est store m10
esttab m1 m2 m3 m4 m5, title("回归结果") b t
esttab m6 m7 m8 m9 m10, title("回归结果") b t
esttab m1 m2 m3 m4 m5, title("回归结果") b p
esttab m6 m7 m8 m9 m10, title("回归结果") b p
esttab m1 m2 m3 m4 m5 m6 m7 m8 m8 m10 using 2.rtf,replace title("Table 2:Time series regression results of the first period of sample stocks") mtitle("Portfolio 1" "Portfolio 2" "Portfolio 3" "Portfolio 4" "Portfolio 5" "Portfolio 6" "Portfolio 7" "Portfolio 8" "Portfolio 9" "Portfolio 10") nogap compress s(N r2) star(* 0.1 ** 0.05 *** 0.01)
drop _est_m1 _est_m2 _est_m3 _est_m4 _est_m5 _est_m6 _est_m7 _est_m8 _est_m9 _est_m10

duplicates drop beta_decile, force
drop _Nobs _R2 _adjR2 beta_i week_decile risk_premium return_premium portpolio_return
save "/Users/xuelingzhao/Desktop/3080 data/第二期回归结果.dta", replace

***========================4.2 CAPM的横截面回归================================***
//merge进数据
use "/Users/xuelingzhao/Desktop/3080 data/grouped data.dta", clear
keep if week_decile == 3
merge m:1 StockCode using "/Users/xuelingzhao/Desktop/3080 data/分组好的个股beta系数.dta"
keep if _merge == 3
drop _merge

//计算分组的10个组合在第三期内的周超额收益率平均值
bys beta_decile week: egen portfolio_return = mean(week_ret)
bys beta_decile: egen mean_return = mean(portfolio_return)
gen mean_return_premium = mean_return - WeeklizedRiskFreeRate
duplicates drop beta_decile, force

//merge进第二期beta的数据
merge m:1 beta_decile using "/Users/xuelingzhao/Desktop/3080 data/第二期回归结果.dta"
keep if _merge == 3
drop _merge

//对第三期股票进行横截面回归
reg mean_return_premium _b_risk_premium
est store m1
esttab m1 using 1.rtf,replace title("Table 2:Time series regression results of the first period of sample stocks") mtitle("Portfolio 1" "Portfolio 2" "Portfolio 3" "Portfolio 4" "Portfolio 5" "Portfolio 6" "Portfolio 7" "Portfolio 8" "Portfolio 9" "Portfolio 10") nogap compress s(N r2) star(* 0.1 ** 0.05 *** 0.01)


//画图
twoway lfitci mean_return_premium _b_risk_premium || scatter mean_return_premium _b_risk_premium, xtitle("beta") ytitle("Rp")

