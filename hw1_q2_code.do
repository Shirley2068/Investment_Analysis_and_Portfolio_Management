************************************************************************
*** This is a suggested solution to Homework 1 Question 2 (FIN 3080) ***
*** Date: 2023/3/5  Author: Sijie Wang (sijiewang@link.cuhk.edu.cn) ****
************************************************************************

*** 0. Set program options and specify raw data path ***

* Set the following option off to enable uninterrupted screen outputs *
set more off  // Set this option off to enable 

* Change the following path to your own path to the raw data *
global path_to_data ="/Users/sjwang222/Desktop/Term6/FIN3080/hw1/sol" 

* Change current working directory to the raw data folder *
cd $path_to_data

*** Plot median PE ratio by market type over time ***

* Load merged stock-quarter panel data *
use merged_stock_quarter_panel, clear

* Keep necessary variables only *
keep market_type date_yq pe_ratio

gen date_ymd = dofq(date_yq)
format date_ymd % td

* By market and quarter generate median pe ratio *
bys market_type date_yq: egen median_pe = median(pe_ratio)

* Convert data to market-quarter panel *
duplicates drop market_type date_yq, force

* Drop unnecessary columns and outliers *
drop pe_ratio 
drop if median_pe > 500

* Save output data *
save market_quarter_pe, replace
