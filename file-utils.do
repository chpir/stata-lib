/********************************************************
* Last Modified:  04/06/11, 10:29:50   by Jan Ostermann
* File Name:      C:\Users\osterman\Documents\Work\stata-lib\file-utils.do
********************************************************/

capture log c
log using "file-utils.log", replace
capture cd ../tmp
*go "C:\Users\osterman\Documents\Work\stata-lib\file-utils.do"



	*start a git bash in the nearest (up) directory with a git repository
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


	*New instance of stata in the same directory
	capture program drop New
	program define New
	  local i: pwd
	  winexec "C:\Program Files (x86)\Stata11\Stata-64.exe"
	end


	*substitute for "do"
	capture program drop go
	program define go
		args FPATH
		local i=strpos(reverse("`FPATH'"),"\")
		local j=strpos(reverse("`FPATH'"),"/")
		local k=min(`i',`j')
		if `k'==0 {
			local k=max(`i',`j')
		}
		if `k'>0 {
		local PATH=substr("`FPATH'",1,length("`FPATH'")-`k')
		cd "`PATH'"
		}
		do "`FPATH'"
	end




