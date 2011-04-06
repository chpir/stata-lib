
/* define main parameters */

   global WHO="Jan"

   clear
   set matsize 800
   set logtype text
   set linesize 220
   capture set mem 100m

   global qui qui
   global DATA ../../../data/
   global rp restore, preserve


	*additional old programs (e.g. addoutpt) in these original files:
	qui do c:\data\savecoef
	qui do c:\data\usecoefs
    qui do c:\data\runttest

	
	*program & utilities files for matrices, variables, pofo utilities
	qui do C:\Users\osterman\Documents\Work\stata-lib\mat-utils
	qui do C:\Users\osterman\Documents\Work\stata-lib\var-utils
	qui do C:\Users\osterman\Documents\Work\stata-lib\file-utils
	qui do C:\Users\osterman\Documents\Work\stata-lib\pofo-utils
   





/* 
To create the date range, first run MakeDate, then MakeDateRange.  
EX:  use childmaster,clear
 		 MakeDate dob
 		 MakeDateRange dob
 
 Note: We edited this based on the 5/6/09 version. Now need to add
 the following to and dob programs and make a similar range for DOD.
 
 replace dod_est=. if !inrange(year(dod_est),1992,2008)
 
 Note:  sites input Jan 1 as DOB if date is unknown, especially at baseline.
 		 
*/
capture program drop MakeDate
program define MakeDate
	args DATEVAR
	capture drop `DATEVAR'_est
	destring `DATEVAR'_dd, generate (`DATEVAR'_dd_num) force
	destring `DATEVAR'_mm, generate (`DATEVAR'_mm_num) force
	destring `DATEVAR'_yy, generate (`DATEVAR'_yy_num) force


	replace `DATEVAR'_dd_num=. if `DATEVAR'_dd_num>31 | `DATEVAR'_dd_num==0
	replace `DATEVAR'_mm_num=. if `DATEVAR'_mm_num>12 | `DATEVAR'_mm_num==0
	
	replace `DATEVAR'_mm_num=1 if `DATEVAR'_mm=="January"
	replace `DATEVAR'_mm_num=2 if `DATEVAR'_mm=="February"
	replace `DATEVAR'_mm_num=3 if `DATEVAR'_mm=="March"
	replace `DATEVAR'_mm_num=4 if `DATEVAR'_mm=="April"
	replace `DATEVAR'_mm_num=5 if `DATEVAR'_mm=="May"
	replace `DATEVAR'_mm_num=6 if `DATEVAR'_mm=="June"
	replace `DATEVAR'_mm_num=7 if `DATEVAR'_mm=="July"
	replace `DATEVAR'_mm_num=8 if `DATEVAR'_mm=="August"
	replace `DATEVAR'_mm_num=9 if `DATEVAR'_mm=="September"
	replace `DATEVAR'_mm_num=10 if `DATEVAR'_mm=="October"
	replace `DATEVAR'_mm_num=11 if `DATEVAR'_mm=="November"
	replace `DATEVAR'_mm_num=12 if `DATEVAR'_mm=="December"
	
	
	capture drop `DATEVAR'_mi
  capture gen `DATEVAR'_mi=1 if `DATEVAR'_dd_num==.
  capture replace `DATEVAR'_mi=2 if `DATEVAR'_mm_num==. 
  capture replace `DATEVAR'_mi=3 if `DATEVAR'_yy_num==. 
 	
	replace `DATEVAR'_dd_num=15 if missing(`DATEVAR'_dd_num)
	replace `DATEVAR'_mm_num=7 if missing(`DATEVAR'_mm_num)
	
	gen `DATEVAR'_est = mdy(`DATEVAR'_mm_num,`DATEVAR'_dd_num,`DATEVAR'_yy_num)
	
	drop `DATEVAR'_dd_num `DATEVAR'_mm_num `DATEVAR'_yy_num 
	
	gen `DATEVAR'_est_OKMIS = inlist(upper(`DATEVAR'_yy),"UK","UNKNOWN", "-")
	
	label define `DATEVAR'_mi 1 "Day Missing" 2 "Month Missing" 3 "Year Missing" , modify	
	label val `DATEVAR'_mi `DATEVAR'_mi 
	format `DATEVAR'_est %dD_m_cY
	codebook `DATEVAR'_est
end


capture program drop MakeDateRange
program define MakeDateRange
	args DATEVAR

qui {
	*label define `DATEVAR'_mi 1 "Day Missing" 2 "Month Missing" 3 "Year Missing" , modify	
	*yD yM yY  Min: day+14 / mo-1    Max: day-1 / mo+1
	*nD yM yY  Min: 15 / mo-1    Max: last day / mo+1
	*nD nM yY  Min: 1 / 1    Max: 31 / 12

	*possibly: baseline only, nD nM yY : min: 1 / [refdate_mm-agebl_mm-0.5] max: last day / [refdate_mm-agebl_mm]
	*big q: which year?

	tempvar temp1 temp2 temp3

	*yD yM yY  Min: day+14 / mo-1    Max: day-1 / mo+1
	*nD yM yY  Min: 15 / mo-1    Max: last day / mo+1
	*nD nM yY  Min: 1 / 1    Max: 31 / 12
		AddToDate `DATEVAR'_est, m(-1) d(14) gen(`temp1')
		AddToDate `DATEVAR'_est, m(-1) gen(`temp2')
		replace `temp2'=mdy(month(`temp2'),15,year(`temp2'))
		gen `temp3'=mdy(1,1,year(`DATEVAR'_est))
			
		gen `DATEVAR'_min=`temp1' if `DATEVAR'_mi==.
		replace `DATEVAR'_min=`temp2' if `DATEVAR'_mi==1
		replace `DATEVAR'_min=`temp3' if `DATEVAR'_mi==2
	
	capture drop `temp1' 
	capture drop `temp2' 
	capture drop `temp3' 
	
	*yD yM yY  Min: day+14 / mo-1    Max: day-1 / mo+1
	*nD yM yY  Min: 15 / mo-1    Max: last day / mo+1 (equivalent to (1 / M+2)-1)
	*nD nM yY  Min: 1 / 1    Max: 31 / 12
		AddToDate `DATEVAR'_est, m(1) d(-1) gen(`temp1')
		AddToDate `DATEVAR'_est, m(2) gen(`temp2')
		replace `temp2'=mdy(month(`temp2'),1,year(`temp2'))-1
		gen `temp3'=mdy(12,31,year(`DATEVAR'_est))
			
		gen `DATEVAR'_max=`temp1' if `DATEVAR'_mi==.
		replace `DATEVAR'_max=`temp2' if `DATEVAR'_mi==1
		replace `DATEVAR'_max=`temp3' if `DATEVAR'_mi==2

	format `DATEVAR'_min `DATEVAR'_max %dD_m_cY
}
	
	codebook `DATEVAR'_min `DATEVAR'_est `DATEVAR'_max 
	l `DATEVAR'_min `DATEVAR'_est `DATEVAR'_max  in 1/20
end









    capture program drop addoutpt
    program define addoutpt
        qui save tempdata, replace
        qui set more off
        global type=e(cmd)
        global depvar=e(depvar)
        global depvar: subinstr global depvar " " "_", all
        global bign=e(N)
        *global littlen=2*(e(df_m)+2)
        if "$type"=="svylogit" {
           if e(N_sub)~=. { global bign=e(N_sub) }
           if "e(subpop)"~="." { local subpop=e(subpop) }
           if "e(subpop)"=="." { local subpop=1 }
           qui tab $depvar if e(sample) & $depvar==1 & `subpop'~=0, matcell(temp)
           global numyes=temp[1,1]
        }
        capture erase addtemp1v.dta
        qui SaveCoef addtemp1
        use addtemp1v, clear
        qui capture gen bigid=2*_n-1
        qui capture gen id=1
        qui save, replace
        qui keep bigid id name coeffs1 
        qui save addtemp2, replace
        qui use bigid id name se1 using addtemp1v, clear
        qui rename se1 coeffs1
        qui replace id=2
        qui append using addtemp2
        qui rename coeffs1 $depvar
        qui sort bigid
        global littlen=_N+2
        set obs $littlen
        replace name="numobs" if _n==${littlen}-1 
        replace ${depvar}=${bign} if _n==${littlen}-1 
        replace bigid=${littlen}-1 if _n==${littlen}-1 
        replace id=1 if _n==${littlen}-1 
        replace name="numyes" if _n==${littlen} 
        
        if "$type"=="svylogit" {
           replace ${depvar}=${numyes} if _n==${littlen} 
        }
        replace bigid=${littlen}-1 if _n==${littlen} 
        replace id=1 if _n==${littlen} 
        qui save addtemp1v, replace
        local new=0
        capture use $path\addoutpt_`1'
        if _rc==0 {
           global temp $depvar
           capture gen $depvar=1
           if _rc==110 { 
              local x=2
              while `x'>1 {
                 global temp $depvar
                 global temp ${temp}`x'
                 capture gen $temp=1
                 if _rc==110 { local x=`x'+1 }
                 else if _rc==0 { 
                    local x=1
                 }
              }
           }
           qui use addtemp1v, clear
           capture rename $depvar $temp
           global depvar $temp
        }
        qui capture mmerge name id using $path\addoutpt_`1', simple
        qui capture drop _merge
        qui order id name
        qui sort bigid name id
        gen zz=1
        move $depvar zz
        drop zz
        l, noobs nod
        qui save $path\addoutpt_`1', replace
        qui set more on
        qui use tempdata, clear
    end


    capture program drop finalize
    program define finalize
        preserve
        qui use if _n<1 using $path\addoutpt_`1', clear
        qui drop name bigid id
        qui for any depvars global: gen X=1 \ order X
        qui outsheet using $path\depvars.do, noq replace 
        qui do $path\depvars.do
        qui use $path\addoutpt_`1', clear
        qui sort bigid name id
        qui local n: word count $depvars
        qui for any $depvars \ num 1/`n': gen str12 or_Y=string(round(exp(X),0.01)) if mod(id,2)==1 \ gen str6 temp_Y1=string(round(exp(X[_n-1]-1.96*X),0.01)) \ gen str6 temp_Y2=string(round(exp(X[_n-1]+1.96*X),0.01))
        qui for Y in num 1/`n': replace or_Y="0"+or_Y if index(or_Y,".")==1 \ replace or_Y=or_Y+".00" if index(or_Y,".")==0 \ replace or_Y=or_Y+"0" if length(or_Y)-index(or_Y,".")==1
        qui for Y in num 1/`n': replace temp_Y1="0"+temp_Y1 if index(temp_Y1,".")==1 \ replace temp_Y2="0"+temp_Y2 if index(temp_Y2,".")==1
        qui for Y in num 1/`n': replace temp_Y1=temp_Y1+".00" if index(temp_Y1,".")==0 \ replace temp_Y2=temp_Y2+".00" if index(temp_Y2,".")==0
        qui for Y in num 1/`n': replace temp_Y1=temp_Y1+"0" if length(temp_Y1)-index(temp_Y1,".")==1 \ replace temp_Y2=temp_Y2+"0" if length(temp_Y2)-index(temp_Y2,".")==1
        qui for Y in num 1/`n': replace or_Y="[" + temp_Y1 + ";" + temp_Y2 + "]" if mod(id,2)==0
        qui for Y in num 1/`n': replace or_Y="" if name=="_cons"
        qui drop temp*
        qui replace name="" if mod(id,2)==0
        qui for X in any $depvars \ Y in num 1/`n': gen str3 sg_Y="   x"  if abs(X/X[_n+1])>=1.96  & mod(id,2)==1
        qui for X in any $depvars \ Y in num 1/`n': replace  sg_Y="  xx"  if abs(X/X[_n+1])>=2.575 & mod(id,2)==1
        qui for X in any $depvars \ Y in num 1/`n': replace  sg_Y=" xxx"  if abs(X/X[_n+1])>=3.29  & mod(id,2)==1

        qui for X in any $depvars \ Y in num 1/`n': gen str8 pr_Y=string(round(2*(1-norm(abs(X/X[_n+1]))),0.0000001)) if mod(id,2)==1
        qui for Y in num 1/`n': replace pr_Y="" if name=="numobs" | name=="numyes" 
        qui for Y in num 1/`n': replace sg_Y="" if name=="numobs" | name=="numyes" 
        qui for X in any $depvars \ Y in num 1/`n': replace or_Y=string(X) if name=="numobs" | name=="numyes" 
        
        qui save $path\addoutpt_`1'_final, replace
        qui outsheet id name $depvars using $path\addoutpt_`1'_coeffs, replace

        qui for X in any $depvars \ Y in num 1/`n': replace or_Y=string(X) if name=="numobs" | name=="numyes"
        qui for Y in num 1/`n': replace sg_Y="" if name=="numobs" | name=="numyes"
        qui drop $depvars
        qui for X in any $depvars \ Y in num 1/`n': rename or_Y X
        qui outsheet id name $depvars using $path\addoutpt_`1'_oratio, replace
        qui drop $depvars
        qui for X in any $depvars \ Y in num 1/`n': rename sg_Y X
        qui outsheet id name $depvars using $path\addoutpt_`1'_signif, replace
        qui drop $depvars
        qui for X in any $depvars \ Y in num 1/`n': rename pr_Y X
        qui outsheet id name $depvars using $path\addoutpt_`1'_pvalue, replace

        qui use $path\addoutpt_`1'_final, clear
        qui for X in num 1/`n': replace sg_X=subinstr(sg_X,"x","*",.)
        qui drop bigid
        qui for num 1/`n' \ any $depvars : move sg_X Y
        qui for num 1/`n' : move pr_X sg_X
        qui for num 1/`n' : move or_X pr_X
        qui for num 1/`n' \ any $depvars : move Y or_X
        qui save $path\addoutpt_`1'_ordered, replace
        qui outsheet using $path\addoutpt_`1'_ordered, replace
        
        if index("`2'","c") + index("`2'","C") > 0 { 
           local keep `keep' $depvars 
           if index("`2'","o") + index("`2'","O") > 0 { local keep `keep' or_* }
           if index("`2'","p") + index("`2'","P") > 0 { local keep `keep' pr_* }
           if index("`2'","s") + index("`2'","S") > 0 { local keep `keep' sg_* }
        }
        else {
           /* if default should be coef/se and ***, then comment out the next 2 lines */
           qui drop $depvars
           qui for X in any $depvars \ Y in num 1/`n': rename or_Y X
           local keep `keep' $depvars 
           if index("`2'","p") + index("`2'","P") > 0 { local keep `keep' pr_* }
           if index("`2'","s") + index("`2'","S") > 0 { local keep `keep' sg_* }
           if "`2'"=="" { local keep `keep' sg_* }
        }
        keep id name `keep'
        if "`3'"=="wide" {
           tempfile file2
           preserve
           replace name=name[_n-1] if id==2
           drop if id==1
           for var *: rename X c2_X
           save `file2'
           restore
           drop if id==2
           gen bigid=_n
           mmerge name using `file2', t(1:1) udrop(c2_id) umatch(c2_name)
           sort bigid
           drop bigid _merge
        }
        qui outsheet using $path\addoutpt_`1'_combined, replace
        
        *qui use tempdata, clear
        noi display _n(1) _col(3) in y "Coeffs / SEs" in w " output to $path\addoutpt_" in r "`1'" in y "_coeffs" in w ".out"
        noi display _col(3) in y "Odds Ratios " in w " output to $path\addoutpt_" in r "`1'" in y "_oratio" in w ".out"
        noi display _col(3) in y "Significance" in w " output to $path\addoutpt_" in r "`1'" in y "_signif" in w ".out"
        noi display _col(3) in y "P-Values    " in w " output to $path\addoutpt_" in r "`1'" in y "_pvalue" in w ".out"
        noi display _col(3) in y "COMBINATION " in w " output to $path\addoutpt_" in r "`1'" in y "_combined" in w ".out"
        restore
    end 

   capture program drop finalize2
   program define finalize2
      preserve
      /* finalize <filename> <"varnames"> */
      set type double
      qui drop _all
      qui insheet using $path\addoutpt_`1'_combined.out
      local varnames `2'
      qui qui AllVars, e(id name sg_*)
      global depvars $AllVars
      global ndepvars $NAllVars
      qui AllVars, e(id name)
   
      tempvar in
      qui gen byte `in'=0   
      qui replace `in'=1 if index("`varnames'",name)>0 & name~=""
      qui replace `in'=1 if index("`varnames'",name[_n-1])>0  & name[_n-1]~=""
      qui keep if `in'==1
      drop `in'
   
      set type str18
      qui xpose, clear v
      qui xpose, clear v
      local j=_N+1
      local k=_N+2
     
      qui set obs `k'
      qui for num 1/$NAllVars \ any $AllVars : replace Y=string(X) if _n==`j' | _n==`k'
      qui replace name=name[_n-1] if name==""
      drop _v
      qui replace id="1" if _n==`j' 
      qui replace id="2" if _n==`k'
      qui replace name="N" if _n==`j'
      qui replace name="N" if _n==`k'
   
      qui reshape wide $AllVars, i(id) j(name) string
   
      global expnames
      global ordnames
      qui foreach X of any `varnames' {
        global expnames $expnames @`X'
        global ordnames $ordnames `X'*
      }
      qui reshape long $expnames @N, i(id) j(depvar) string    
   
      qui drop if N==""
      qui destring N, replace
      qui for num 1/$NAllVars \ any $AllVars : replace depvar="Y" if N==X
      sort N id
      set type float
      
      qui gen sg=mod(N,2)==0
      qui replace N=N-1 if mod(N,2)==0
      qui gen str4 n=string(N)+"_"+id
   
      qui reshape wide depvar `varnames', i(n) j(sg) 
      drop N id depvar1
      order n depvar0 $ordnames
      qui replace n="0"+n if length(n)<4
      sort n
      l, nod
      qui outsheet using $path\addoutpt_`1'_coefficients, replace
      restore
   end




   





   capture program drop ttestschisq
   program define ttestschisq
      args 1 2 VARS 
      qui tabstat `VARS', by(`1') save
      mat StatTot=r(StatTot)'
      local NAMES="`1'"+r(name1)+" "+"`1'"+r(name2)
      qui AllVars `VARS'
      local n=$NAllVars
      matrix ttest_`2'=J(`n',5,9999)
      local i=1
      qui di `n'
      qui while `i'<=`n' {
         local j : word `i' of $AllVars
         di "`j'"
         
         capture tab `j'
         local r=r(r)
         if `r'>2 {         
            capture ttest `j' , by(`1') 
            mat ttest_`2'[`i',1]=r(mu_1)
            mat ttest_`2'[`i',2]=r(mu_2)
            mat ttest_`2'[`i',3]=r(p)
            mat ttest_`2'[`i',4]=r(N_1)
            mat ttest_`2'[`i',5]=r(N_2)
         }
         if `r'==2 {         
            capture ttest `j' , by(`1') 
            mat ttest_`2'[`i',1]=r(mu_1)
            mat ttest_`2'[`i',2]=r(mu_2)
            mat ttest_`2'[`i',4]=r(N_1)
            mat ttest_`2'[`i',5]=r(N_2)
            capture tab `j' `1', chi
            mat ttest_`2'[`i',3]=r(p)
         }
         local i=`i'+1
      }

      mat ttest_`2'=ttest_`2',StatTot
      matname ttest_`2' `NAMES' p N_1 N_2 StatTot, c(1...) explicit

      preserve
         qui drop _all
         qui set obs `n'
      
         qui svmat ttest_`2', n(col)
         qui gen str10 name=""
         qui for X in num 1/`n' \ Y in any $AllVars: replace name="Y" if _n==X
         order name
       
         *for var `NAMES' StatTot: replace X=X*100 if !inlist(name,"age","numsympt","numsymptif")
         if "`4'"=="" {
         qui for var `NAMES' StatTot: replace X=X*100 if !inlist(name,"age","numsympt","numsymptif") & !inlist(name,"sexpart","riskindex","n8numberof") & !inlist(name,"rel_service","chancehiv") \ capture format X %8.2f
         }
         format `NAMES' %12.6g
         qui outsheet using ttests_`2'.txt, replace
         l, noobs nod
         di in g "  Note: saved as ttests_`2'.txt"
      restore
   end



