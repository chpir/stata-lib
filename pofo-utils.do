/********************************************************
* Last Modified:  04/07/11, 10:21:15   by Jan Ostermann
* File Name:      C:\Users\osterman\Documents\Work\stata-lib\pofo-utils.do
********************************************************/

capture log c
log using "pofo-utils.log", replace
capture cd ../tmp
*go "C:\Users\osterman\Documents\Work\stata-lib\pofo-utils.do"


/* Utilities specifically developed for POFO */


	global SITES cambodia ethiopia hyderabad kenya nagaland tanzania


	capture program drop doall
	program define doall
	   if "`1'"=="" {
	   	  local what doit
	   }
	   else {
	   	   local what `1'
	   }
		 di "now running `what' for CAMBODIA" 
	   `what' cambodia
		 di "now running `what' for ETHIOPIA" 
	   `what' ethiopia
		 di "now running `what' for HYDERABAD" 
	   `what' hyderabad
		 di "now running `what' for KENYA" 
	   `what' kenya
		 di "now running `what' for NAGALAND" 
	   `what' nagaland
		 di "now running `what' for TANZANIA" 
	   `what' tanzania
	end



	capture program drop RAW
	program define RAW
		if "`2'"=="" {
			local what cmb
		}
		else if lower("`2'")=="ode" {
			local what pofov3original
		}
		else if lower("`2'")=="dde" {
			local what pofov3dde
		}
		capture use "C:\Users\osterman\Documents\Work\Projects\POFO\Data\raw\\`what'_`1'", clear
		if _rc~=0 {
			dir C:\Users\osterman\Documents\Work\Projects\POFO\Data\raw\\`what'_*.dta
			di _n(1) in r "`1' not found, see above for available raw data files."
		}
	end
	
	capture program drop DRV
	program define DRV
		capture use "C:\Users\osterman\Documents\Work\Projects\POFO\Data\drv\child\\`1'", clear
		if _rc~=0 {
			capture use "C:\Users\osterman\Documents\Work\Projects\POFO\Data\drv\caregiver\\`1'", clear
			if _rc~=0 {
			capture use "C:\Users\osterman\Documents\Work\Projects\POFO\Data\drv\location\\`1'", clear
				if _rc~=0 {
					di _n(1) "CHILD:"
					dir C:\Users\osterman\Documents\Work\Projects\POFO\Data\drv\child\*.dta
					di _n(1) "CAREGIVER:"
					dir C:\Users\osterman\Documents\Work\Projects\POFO\Data\drv\caregiver\*.dta
					di _n(1) "LOCATION:"
					dir C:\Users\osterman\Documents\Work\Projects\POFO\Data\drv\location\*.dta
					di _n(1) in r "`1' not found, see above for available derived files."
				}
			}
		}
			
	end

	capture program drop dbChoice
	program define dbChoice
	   syntax [, Double Original Combined Permanent RESET]
	   if "`reset'"~="" {
	      global DB_permanent=""
	   }
	   if "`double'"~="" | "`original'"~="" | "`combined'"~="" {
		   if "`double'"~="" {
	              global DBL="dbl_"
		      local text="Double Data Entry "
		   }
		   if "`original'"~="" {
		      global DBL=""
		      local text="Original Data Entry "
		   }
		   if "`combined'"~="" {
	              global DBL="cmb_"
		      local text="Combined - Original and Double Data Entry "
		   }
		   if "`permanent'"~="" | "$DB_permanent"=="1" {
		      global DB_permanent=1
		      local text2 = "(permanently)"
		   }
		   else {
		      global DB_permanent=""
		   }
	   }   
	   if "`double'"=="" & "`original'"=="" & "`combined'"=="" {
	   	   *global DB_permanent=""
		   if "$DB_permanent"~="1" {
			global WinText "Select:"
			window control static  WinText 10 5 40 10
			window control button "Original" 10 15 37 10 DB_original 
			window control button "Double" 52 15 37 10 DB_double 
			window control button "Combined" 94 15 37 10 DB_combined 
			window control check "Permanently" 52 5 60 7 DB_permanent
			global DB_combined "exit 3002"
			global DB_original "exit 3001"
			global DB_double "exit 3000"
			capture noisily window dialog "Select Database"  400 300 148 43
			
			if _rc==3002 {
			  global DBL="cmb_"
			  local text="Combined - Original and Double Data Entry "
			}
			if _rc==3000 {
			  global DBL="dbl_"
			  local text="Double Data Entry "
			}
			else
			if _rc==3001 {
			  global DBL=""
			  local text="Original Data Entry "
			}  
			if "$DB_permanent"=="1" {
			  local text2 = "(permanently)"
			}
		   }
		   else {
		        if "$DBL" == "dbl_" {
			  local text="Double Data Entry "
		        }
		        else 
		        if "$DBL" == "cmb_" {
			  local text="Combined - Original and Double Data Entry "
		        }
		        else 
		        if "$DBL" == "" {
			  local text="Original Data Entry "
		        }
			if "$DB_permanent"=="1" {
			  local text2 = "(permanently)"
			}
		   }
	   }
	   noi di _n(1) in y "  `text'`text2' " _n(1) 
	end


	capture program drop dbReset
	program define dbReset
		global DB_permanent
	end




	*NOTE: PROGRAM THAT PRIORITIZES ROUNDS
	capture program drop Prioritize
	program define Prioritize
		args VAR IDS ROUNDS 
		*SAMLE: q37 	  "sitestr householdid" "2 0 1 2 3 4 5 6" 
		*SAMLE: childwork "sitestr code" 	"MAX"
		*note only numerics right now
		tempvar r0 r1 r2 r3 r4 r5 r6 rall check1 check2 one
	
		capture drop fromrounds
		capture drop tempround
	
		capture gen tempround=.
		capture gen fromrounds=""
		
		if "`ROUNDS'"=="MAX" {
			foreach Z of num 0/6 {
				preserve
					qui drop if real(substr(round,-1,1))>`Z'
					collapse (max) `VAR', by(`IDS')
					gen round="`Z'"
					qui save temp`Z', replace
				restore
			}
			preserve
				use temp0, clear
				foreach Z of num 1/6 {
					append using temp`Z'
					erase temp`Z'.dta
				}
				ren `VAR' p_`VAR'
				drop if round==""
				qui save temp0, replace
			restore		
			mmerge `IDS' round using temp0, t(n:1)
			di in r "Note: self reports included, if available"
			erase temp0.dta
		}
		else {
			if "`ROUNDS'"=="" {
				local ROUNDS="0 1 2 3 4 5 6"
			}
		   	foreach X of num 0/6 {
		   		capture drop `r`X''
		   		qui egen `r`X''=max(`VAR'*(round=="`X'")), by(`IDS')
				qui gen `check1'=1 if round=="`X'" & `VAR'<.
		   		qui egen `check2'=max(`check1'*(round=="`X'")), by(`IDS')
		   		qui replace `r`X''=. if `check2'~=1
				capture drop `check1' `check2'
				}
		   	qui gen `rall'=.
		   	foreach X of any `ROUNDS' {
		   		qui replace `rall'=`r`X'' if `rall'==. & `r`X''<.
		   	}
			capture drop p_`VAR'
			qui gen p_`VAR'=`rall'
			sort `IDS' round
			*browse `IDS' round `VAR' p_`VAR' 
		}
		foreach Z of num 0/6 {
			qui replace tempround=`Z' if float(`VAR')==float(p_`VAR') & round=="`Z'"
		}
		capture drop `one'
		gen `one'=1
	   	foreach Z of num 0/6 {
	   		capture drop `r`Z''
		   	qui egen `r`Z''=max(`one'*(tempround==`Z')), by(`IDS')
			qui replace fromrounds=fromrounds+"`Z'" if `r`Z''==1
		}
		drop tempround
	end
	


