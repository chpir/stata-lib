/********************************************************
* Last Modified:  03/29/11, 09:38:44   by Jan Ostermann
* File Name:      C:\Users\osterman\Documents\Work\stata-lib\var-utils.do
********************************************************/

capture log c
log using "var-utils.log", replace
capture cd ../tmp
*go "C:\Users\osterman\Documents\Work\stata-lib\var-utils.do"



/* Variable utilities */

capture program drop DrvLbl
program define DrvLbl
	label var `1' ">`2'"
end

capture program drop lf
program define lf
	lookfor `1'
end
 
capture program drop DrvLbls
program define DrvLbls
      syntax [varlist] [, Prefix(string) Suffix(string) Label(string) ]
      unab vlist : `varlist'
      di "/// begin DrvLbls for: `vlist'"
	  foreach X of var `varlist' {
	  	 local oldlbl: var l `X'
	  	 *use existing label
	  	 if "`label'"=="" {
		  	 if substr("`oldlbl'",1,1)==">" {
		  	 	local j=">`prefix'" + substr("`oldlbl'",2,80-length("`prefix'`suffix'")) + "`suffix'"
		  		label var `X' "`j'"	
		  	 }
		  	 else {
		  	 	local j=">`prefix'" + substr("`oldlbl'",1,79-length("`prefix'`suffix'")) + "`suffix'"
		  		label var `X' "`j'"	
				}	
		  	 }
		 }
		 *new label with >
		 else {
		  	local j=">`prefix'" + substr("`label'",1,79-length("`prefix'`suffix'")) + "`suffix'"
			label var `X' "`j'"	
		 }
	  }
      dd `varlist'
      di "/// end DrvLbls for: `vlist'"
end

capture program drop vFilter
program define vFilter
    syntax varname [, Text(string) GENerate(string) REPLACE UPDATE]
	*This is to identify occurrences of word stems in string variables,
	*count them, replace them with blanks and redisplay remainder
	qui {
		tempvar temp out
		
		*clean/lowercase  variable
		gen `temp'=`varlist'
		replace `temp'=lower(trim(`temp'))
		replace `temp'=subinstr(`temp',","," ",.)
		replace `temp'=subinstr(`temp',"."," ",.)
		replace `temp'=subinstr(`temp',";"," ",.)
		
		*flag relevant observations and replace source variable if 'replace' option
		capture gen `out'=.	
		foreach X of any `text' {
			di "`X'"
			replace `out'= 1 if regexm(`temp',"`X'[a-z0-9]*")==1
			if "`replace'"~="" {
				replace `temp'=regexr(`temp',"`X'[a-z0-9]*","")
				replace `temp'=subinstr(`temp',"  "," ",.)	
				replace `varlist'=`temp'
				tab `varlist', sort
			}
		}
		
		
		if "`generate'"~="" {
			capture confirm v `generate'
			if _rc==0 {
				if "`update'"=="" {
					di in r "NOTE: `generate' existed previously - dropped!!!"
					capture drop `generate'
					gen `generate'=`out'
				}
				else {
					replace `generate'=`out' if `out'==1
				}
			}
			else {
				gen `generate'=`out'	
			}
			qui count if `generate'==1
		}
		else {
			gen `varlist'_`text=`out'
			qui count if `varlist'_`text==1
		}
	}
	local i=r(N)
	qui drop `out' `temp'
	di in r "`text': `i' occurrences"
end


capture program drop FindNearby
program define FindNearby
    syntax varname [, Number(string) ]
    qui AllVars
    local i: word count $AllVars
    foreach X of num 1/`i' {
    	local j: word `X' of $AllVars
    	if "`j'"=="`varlist'" {
    		local k=`X'
    	}
    }
    if "`number'"=="" {
    	local number 5
    }
    local i=`k'-`number'
    local j=`k'+`number'
    local i: word `i' of $AllVars
    local j: word `j' of $AllVars
    qui AllVars `i'-`j'
    dd $AllVars
    di in b "Variable " in r "`varlist'" in b " found in position " in r `k'
end


capture program drop ParseIt
program define ParseIt
   syntax varname [, NAME(string) Suffix(string) CHAR]
   tempvar temp
   qui replace `varlist'=trim(`varlist')
   local i: format `varlist'
   local i: subinstr local i "%" "", all
   local i: subinstr local i "s" "", all  
   if "`name'" ~="" {
       local VARNAME `name'
   }
   else if "`suffix'" ~="" {
       local VARNAME `varlist'`suffix'
   }
   else {
       local VARNAME `varlist'_
   }      
   if `i'<1 {
       exit 198   
   }
   else {
      di in y "`varlist'  has `i' items; converted to `VARNAME'*"
   }
   foreach X of num 1/`i' {
      capture drop `VARNAME'`X'
      qui gen `VARNAME'`X'=substr(`varlist',`X',1)
    if "`char'"=="" {
       qui destring `VARNAME'`X', replace force
    }
   }
    qui compress
   if "`char'"=="" {
      sum `VARNAME'*
   }
   else {
      codebook `VARNAME'*
   }
end


   capture program drop AllVars
   program define AllVars
      syntax [varlist] [, Exclude(varlist) CHAR D Label(string)]
      global AllVars `varlist' 
      if "`varlist'"~="" { 
	     unab unaball : `varlist'
      }
      else { 
      	  global AllVars `unabexc' 
      }
      if "`exclude'"~="" { 
      	  unab unabexc : `exclude'
      }
      tokenize `unabexc'
      while `"`1'"'!="" {
         global AllVars : subinstr global AllVars "`1'" "", word
         global AllVars : subinstr global AllVars "  " " ", all
         mac shift
      }
      if "`char'"~="" { 
      	foreach X of any $AllVars {
            local i : type `X'
            if substr("`i'",1,3)=="str" { 
            local j `j' `X'
            }
         }
         global AllVars `j'
      }
		local j
      if "`lable'"~="" { 
      	foreach X of any $AllVars {
            local i : variable label `X'
            if index(lower("`i'"),lower("`lable'"))>0 { 
            local j `j' `X'
            }
         }
         global AllVars `j'
      }
      global NAllVars: word count $AllVars
      di _n(1) in y "\$AllVars (${NAllVars}):" " $AllVars"
      if "`d'"~="" { 
      	 dd $AllVars
         }
   end


   capture program drop WriteTo
   program define WriteTo
      syntax [varlist] [, VALues(string) OBS(string) ]
      if "`varlist'"=="" {
      	 qui AllVars
      }
      if "`varlist'"~="" {
      	 qui AllVars `varlist'
      }
      local j: word count `values'
      if `j'~=$NAllVars {
      	 di in r "unequal number of arguments:" in y " $NAllVars variables vs. `j' values" _n
      	 exit
      }

      qui count
      local i=r(N)
      if "`obs'"=="" { 
         local i=`i'+1
      }
      else {
         if `obs'>r(N) { 
            set obs `obs'
            local i=`obs'
         }
         if `obs'<=r(N) { local i=`obs' }
      }
      foreach X of num 1/$NAllVars {
         local var: word `X' of $AllVars
         local val: word `X' of `values'
         local type: type `var'
         if substr("`type'",1,3)=="str" {
            qui replace `var'="`val'" if _n==`i'
         }
         else {
            qui replace `var'=`val' if _n==`i'
         }
      }
      l `varlist' if _n==`i', nod 
   end



capture program drop AddToDate
program define AddToDate

   syntax varname(numeric) [, Years(integer 0) Months(integer 0) Days(integer 0) Generate(string) replace]
   qui {

        if "`generate'" != "" & "`replace'" != "" {
                di as err "{p}options generate and replace are mutually exclusive{p_end}"
                exit 198
        }
        if "`generate'" == "" & "`replace'" == "" {
                di as err "{p}must specify either generate or replace option{p_end}"
                exit 198
        }
        local DATEVAR `varlist'
        
        if "`generate'" != "" {
                local ct1: word count `generate'
                if `ct1' != 1 {
                        di as err "{p}number of variables in generate(newvarlist) must be 1{p_end}"
                        exit 198
                }
                local NEWVAR `generate'
        }
        else {
		capture drop _`DATEVAR'
        	local NEWVAR _`DATEVAR'
        }
        
        
*   args DATEVAR NEWVAR YEARS MONTHS DAYS 
   	tempvar DD1 MM1 YY1  DD2 MM2 YY2 
	if "`years'"~="" {
		local YEARS=`years'	
	}
	else {
		local YEARS=0
	}
	if "`months'"~="" {
		local MONTHS=`months'	
	}
	else {
		local MONTHS=0
	}
	if "`days'"~="" {
		local DAYS=`days'	
	}
	else {
		local DAYS=0
	}

   	capture gen `NEWVAR'=`DATEVAR'
   	replace `NEWVAR'=`DATEVAR' + `DAYS' if real("`DAYS'")~=.
   	gen `DD2'=day(`NEWVAR')
   	gen `MM1'=month(`NEWVAR')
   	gen `YY1'=year(`NEWVAR')

	* add days, months years to integers 
   	gen `MM2'=`MM1' 
   	replace `MM2'=`MM2'+real("`MONTHS'") if real("`MONTHS'")~=.
   	gen `YY2'=`YY1' 
   	replace `YY2'=`YY2'+real("`YEARS'") if real("`YEARS'")~=.
   	
   	* update years depending on months 
   	replace `YY2'=`YY2' + int(`MM2'/12) if `MM2'>12
   	replace `MM2'=`MM2' - 12*int(`MM2'/12) if `MM2'>12
   	
   	replace `YY2'=`YY2' - abs(int(`MM2'/12)+1) if `MM2'<=0
   	replace `MM2'=`MM2' + 12*abs(int(`MM2'/12)+1) if `MM2'<=0

	*account for fewer days in some months -- replace with last day
	replace `DD2'=min(`DD2',day(mdy(`MM2'+1,1,`YY2')-1))

   	*l `DATEVAR' `DD1' `MM1' `YY1' `DD2' `MM2' `YY2' 
        if "`replace'" != "" { 
	   	replace `DATEVAR'=mdy(`MM2',`DD2',`YY2')
	}
	else {
		replace `NEWVAR'=mdy(`MM2',`DD2',`YY2')
		format `NEWVAR' %dD_m_cY
	}
   }
   
end


capture program drop git
program define git
	local pwd:pwd 
	local i=0
	while `i'==0 & "`pwd'"~="C:\Users\osterman\Documents\" {
		capture confirm f .git/config
		if _rc==0 {
			local i=1	
		   !"C:\Program Files (x86)\Git\bin\sh.exe" --login -i
		}
		else {
		   cd ..	
		}
	}
   cd "`pwd'"
end
