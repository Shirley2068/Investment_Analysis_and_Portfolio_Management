********************************************************************************
********************************FIN3080 HW2*************************************
********************************************************************************

*=======================Q 2=======================*

//process monthly return
import excel "/Users/xuelingzhao/Desktop/3080 data/MonthlyReturn.xlsx", sheet("sheet1") firstrow clear

//generate month 

* generate date
gen date_ymd = date(TradingMonth, "YM")

* convert date into month
gen month = mofd(date_ymd)
format month %tm

save "/Users/xuelingzhao/Desktop/3080 data/processed_MonthlyReturn.dta", replace


//process PBratio
use "/Users/xuelingzhao/Desktop/3080 data/P:B ratio.dta", clear
drop if PBratio <0
gen date_ymd = date(TradingMonth, "YM")

* convert date into month
gen month = mofd(date_ymd)
format month %tm

* merge
merge 1:1 StockCode date_ymd using "/Users/xuelingzhao/Desktop/3080 data/processed_MonthlyReturn.dta"
drop if _merge == 2
drop _merge

* 按日期和PB ratio大小分组
bysort month: egen portfolio = xtile(PBratio), nq(10)

* 计算每个月不同portfolio的个数
bysort month portfolio: egen number = count(portfolio)

* 计算每个portfolio return的总和
bysort month portfolio: egen agg_return = sum(MonthlyReturnWithoutCashDivi * (1/number))
duplicates drop month agg_return, force

* 画图
xtset portfolio month
xtline agg_return
xtline agg_return, overlay title("Time Series for Ten Portfolios")

