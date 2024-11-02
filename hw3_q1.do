********************************************************************************
********************************FIN3080 HW3*************************************
********************************************************************************


import excel "/Users/xuelingzhao/Desktop/3080 data/data and code/TRD_Mnth.xlsx", sheet("sheet1") firstrow clear
//generate month
gen date_ymd = date(TradingMonth, "YM")
gen month = mofd(date_ymd)
format month %tm

//generate last month return
destring StockCode, replace
xtset StockCode month
gen lag_return = l.MonthlyReturnWithoutCashDivi
drop if date_ymd == 18962 //drop 2011.Dec data

save "/Users/xuelingzhao/Desktop/3080 data/data and code/return.dta", replace

//generate deciles for last month return within each month
bys month: egen return_decile = xtile(lag_return), nq(10)

//generate portfolios' average return in one month 
bys month return_decile: egen month_return = mean(MonthlyReturnWithoutCashDivi)
duplicates drop month return_decile, force
drop if return_decile == .


//generate cumulative return
sort return_decile month
bys return_decile: gen double cumulative_return = sum(ln(month_return +1))
replace cumulative_return = exp(cumulative_return) -1
tostring return_decile, gen(Portfolio)
replace Portfolio = "Portfolio " + Portfolio

* draw time series
xtset return_decile month
xtline cumulative_return, overlay title("Time Series for Ten Portfolios")

//generate decile-month panel for average portfolio returns
bys return_decile: egen avg_return = mean(month_return)
duplicates drop return_decile, force
graph bar avg_return, over(return_decile)






