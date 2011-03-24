/* Get, save, and use coeffiecient vectors, standard errors, and vc matrices
GetCoefs
SaveCoef
usecoef
GetSes
GetVce
SaveVce
:

*/


	capture program drop GetCoefs
	program define GetCoefs
	   mat coeffs = e(b)
	   mat coeffs = coeffs'
	
	   drop _all
	   svmat coeffs
	   global blah : rowname coeffs
	   global blah : rowfullnames coeffs
	   local i = 1
	   parse "$blah", p(" ")
	
	   capture drop name
	   gen str8 name=""
	
	   while "``i''"~="" {
			replace name = "``i''" in `i'
			local i = `i'+1
		}
	   *sort name
	end

    capture program drop SaveCoef
    program define SaveCoef
        global whtname_ `1'
        save tempdata, replace
        GetCoefs
        save tempcoef, replace
        GetSes
        global vars_: rowfullnames v
        global varn_: word count $vars_
        mmerge name using tempcoef
        save tempcoef, replace
        GetVce
        mmerge name using tempcoef
        capture gen _id=.
        local i=1
        parse "$vars_", p(" ")
        while "``i''"~="" {
	   	   replace _id = `i' if name=="``i''"
		   local i = `i'+1
		}
        *for num 1/$varn_ \ any $vars_: replace _id=X if name=="Y"
        sort _id
        drop _merge _id
        order name coeffs se1
        drop v$varn_
        local i=1
        parse "$vars_", p(" ")
        while "``i''"~="" {
	   	   capture rename v`i' ``i''
		   local i = `i'+1
		}
        *for num 1/$varn_ \ any $vars_: capture rename vX Y
        save ${whtname_}v, replace
        outfile name coeffs1 se1 using ${whtname_}c.txt, replace
        use tempdata, clear
    end


	capture program drop usecoef
	program define usecoef
		local mname="`1'"
		capture mat l coeffs
		infile str8 name coeffs using `1'.txt, clear
		mkmat coeffs , mat(`mname')
		local i = 1
		qui count
		local N = r(N)    
		while `i' <=`N' {
		        local hold = name in `i'
		        local blah "`blah' `hold'"
		        local i = `i' +1
		        }
		
		noi di "-blah- consists of |`blah'|"
		matname `mname' `blah', row(1...) explicit
		mat l `mname'
		mat `mname' = `mname''
		global matvars `blah'
	end 

	capture program drop GetSes
	program define GetSes
	   mat v= get(VCE)
	   mat se = vecdiag(v)
	   mat se = se'
	   local i=rowsof(se)
	   for num 1/`i': mat se[X,1] = sqrt(se[X,1])
	   drop _all
	   svmat se
	   global blah : rownames se
	   global blah : rowfullnames se
	   local i = 1
	   parse "$blah", p(" ")
	   capture drop name
	   gen str8 name=""
	   while "``i''"~="" {
			replace name = "``i''" in `i'
			local i = `i'+1
	 	}
	   *sort name
	end

	capture program drop GetVce
	program define GetVce
	   drop _all
	   gen str8 name=""
	   svmat v
	   global blah : rowfullnames v
	   global blah : rownames v
	   global blah : rowfullnames v
	   local i=1
	   parse "$blah", p(" ")
	   capture drop name
	   gen str8 name=""
	
	   while "``i''"~="" {
		replace name = "``i''" in `i'
		local i = `i'+1
		}
	end

    capture program drop SaveVce
    program define SaveVce
        save tempdata, replace
        GetCoefs
        save tempcoef, replace
        GetSes
        global vars_: rowname v
        global varn_: word count $vars_
        mmerge name using tempcoef
        save tempcoef, replace
        GetVce
        mmerge name using tempcoef
        capture gen _id=.
        for num 1/$varn_ \ any $vars_: replace _id=X if name=="Y"
        sort _id
        drop _merge _id
        order name coeffs se1
        save `1'v, replace
        outfile name coeffs1 se1 using `1'c.txt, replace
        use tempdata, clear
    end




capture program drop UseMat
program define UseMat
	local mname="`1'"
	preserve
		qui insheet using `1'.out, clear
		qui AllVars
		local NAMEVAR: word 1 of $AllVars
		qui AllVars, e(`NAMEVAR')
		
		mkmat $AllVars, mat(`mname')
		local i = 1
		qui count
		local N = r(N)    
		while `i' <=`N' {
		        local hold = `NAMEVAR' in `i'
		        local blah "`blah' `hold'"
		        local i = `i' +1
		        }
		*noi di "-blah- consists of |`blah'|"
		matname `mname' `blah', row(1...) explicit
		mat l `mname'
		*mat `mname' = `mname'
		global matvars `blah'
	restore
end 



   /* save table results after table X Y [Z], [c(abc)] replace */
   capture program drop SaveTable
   program define SaveTable
      qui AllVars *, e(table*)
      qui foreach X of var $AllVars {
         qui sum `X'
         local `X'=r(max)
         capture replace `X' =``X''+1 if `X'==.
      }
      sort $AllVars
      local i: word 1 of $AllVars
      local j: word 2 of $AllVars
      local k: word 3 of $AllVars
  if "`j'"~="" {
      qui if "`k'"~="" {
         reshape wide table*, i(`i' `j') j(`k')
         reshape wide table*, i(`j') j(`i')
         local which `j'
      }
      qui else {
         reshape wide table*, i(`i') j(`j')
         local which `i'
      }
      qui AllVars table1*
      global AllVars: subinstr global AllVars "table1" "table@", all
      qui reshape long $AllVars, i(`which') j(stat)
      AllVars, char
      mkmat table*, mat(result)
      l, noobs nod
      if "$AllVars"~="" {
         qui count
         local n=r(N)
         foreach X of num 1/`n' {
            local name=$AllVars[`X']
            matname result `name', r(`X') explicit
         }
      }
      if "`k'"~="" {
         di _n(1) in g "Column headings:" in w " `k' x `i'" 
      }
      else {
         di _n(1) in g "Column headings:" in w " `j'" 
      }
	}
	else { 
		di _n(1) in g "Nothing to do... (only one " in w "by" in g " variable)"
	}
   end      

   
   
   /* save table results after table X Y [Z], [c(abc)] replace */
   capture program drop SaveMat
   program define SaveMat
      args MATNAME FILENAME
      preserve
      qui drop _all
      qui svmat `MATNAME', n(col)
      local r=rowsof(`MATNAME')
      local n: rownames `MATNAME'
      qui gen str80 _varname=""
      local i=1
      qui while `i'<=`r' {
      	 local j: word `i' of `n'
      	 replace _varname="`j'" if _n==`i'
      	 local i=`i'+1
      }
      order _varname
      rename _varname _`MATNAME'
      qui outsheet using "`FILENAME'", replace
      l, noobs nod
      di in g "   Saved as: " in y "`FILENAME'.out"
   end
         
