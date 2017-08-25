//This program attempts to replicate the results of the famous Stock & Watson paper on Vector Autoregression (VAR)//
//http://pubs.aeaweb.org/doi/pdfplus/10.1257/jep.15.4.101//
//The first part of the program gathers the monthly unemployment and fed funds rate data and converts it into quarterly data//
//The second part of the program gathers the monthly inflation data, converts it into quarterly data and merges it with the fed funds rate and unemployment data//
//The final part of the program generates the reduced VAR form and the SVAR form with recursive ordering. Impulse Response Functions (IRFs) are also generated//
clear
drop _all
graph drop _all
quietly{
insheet using "C:\Users\Subash Bharadwaj\Desktop\Spring Semester 2017\EC541\Lab Sessions\SW2001inStata\SW2001inStata\monthly_IR_Emp.csv", names

gen date1 = date(date, "YMD")
format %td date1
tsset date1
gen qtr=qofd(date1)
collapse fyff lhur, by(qtr)
gen datq = tq(1948q1)+_n-1
format %tq datq
keep if datq>=tq(1960q1)
save master_data, replace

clear
insheet using "C:\Users\Subash Bharadwaj\Desktop\Spring Semester 2017\EC541\Lab Sessions\SW2001inStata\SW2001inStata\quarterly_Infl.csv", names
gen datq=date(date,"YMD")
format datq %td
replace datq=qofd(datq)
format datq %tq
tsset datq
* Inflation measured as GDP deflator
gen infl = 400*(ln(gdpd)-ln(L.gdpd))
drop gdpd
merge 1:1 datq using master_data, nogen
drop if infl==.
keep if datq>=tq(1960q1)
set autotabgraphs on
}

* Graph the final data on Inflation, Unemployment and Fed Funds Rate
tsline infl, title("Annualized Inflation (GDP Deflator)") ytitle(Inflation) ttitle(Time) name(Fig1)
tsline lhur, title("Unemployment Rate (16 years & Older)") ytitle(Unemployment) ttitle(Time) name(Fig2)
tsline fyff, title("Federal Funds Rate") ytitle(Interest Rate) ttitle(Time) name(Fig3)

* VAR estimate
var infl lhur fyff, lags(1/4)

* Granger causality test
vargranger

* "Structural" vector autoregression with recursive ordering
matrix A = (1,0,0\.,1,0\.,.,1)
matrix B = (.,0,0\0,.,0\0,0,.)

svar infl lhur fyff, lags(1/4) aeq(A) beq(B)

* Stores the IRF Results in IRFRes.irf
irf create StockWatson, set(IRFRes) step(24) replace
* Creates the impulse response functions
irf cgraph (StockWatson infl infl sirf) ///
(StockWatson infl lhur sirf) ///
(StockWatson infl fyff sirf) ///
(StockWatson fyff infl sirf) ///
(StockWatson fyff lhur sirf) ///
(StockWatson fyff fyff sirf) ///
(StockWatson lhur infl sirf) ///
(StockWatson lhur lhur sirf) ///
(StockWatson lhur fyff sirf) ///
,title("Impulse Response Functions")
