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

capture program drop DescribeStrings
program define DescribeStrings
    syntax varname [, Text(string) REPLACE]
	*This is to identify occurrences of word stems in string variables,
	*count them, replace them with blanks and redisplay remainder
	qui {
		tempvar temp
		local `temp'=`varlist'
		tab `temp'
		replace `temp'=lower(`temp')
		replace `temp'=subinstr(`temp',","," ",.)
		replace `temp'=subinstr(`temp',"."," ",.)
		gen `varlist'_`text'= 1 if regexm(`temp',"`text'[a-z0-9]*")==1
		if `replace'~="" {
			replace `varlist'=`temp'
			replace `varlist'=regexr(`varlist',"`text'[a-z0-9]*","")
			replace `varlist'=subinstr(`varlist',"  "," ",.)	
			tab `varlist', sort
		}
	}
	qui count if `varlist'_`text'==1
	local i=r(N)
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
