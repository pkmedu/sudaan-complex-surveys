******************************************************************************** 
    SB508 Characteristics and Health Care Expenditures of VA Health System Users 
          versus Other Veterans, 2014-15 (average annual) 
    Program Wriiten By: Pradip K. Muhuri
    This program generates estimates that are used for Figure 3a of the Stat Brief.
**********************************************************************************/

OPTIONS nocenter obs=max ps=58 ls=132 nodate nonumber;
libname pufmeps  'S:\CFACT\Shared\PUF SAS files\SAS V8' access=readonly;
proc datasets nolist kill; quit;
proc format;
value insfmt    1 ='<65 Any Private'	 
				2 ='<65 Public Only' 
				3 ='<65 Uninsured';
value VAusefmt  0= 'All Veterans'
                  1= 'VA-User'
                  2 = 'Non-Var User';
                  
 run;
%let vars_kept = dupersid agelast sex race:
                 HONRDC31  HONRDC42  HONRDC53
                 VARPSU VARSTR perwt: 
                 totexp: totva: insurc:;
* Create data for 2014-2015;
%macro loop(dslist);
%local i yr;
  %let yr=14;
  %DO i = 1 %to %sysfunc(countw(&dslist, %str(|)));
   data FY_20&yr (drop = _:);
     set %scan(&dslist, &i, |)  (keep=&vars_kept);
	       year=20&yr.;

format  VA_paid VAusefmt. insurc&yr insfmt. ;
     run;
    %let yr = %eval(&yr + 1);
   %end;
%mend loop;
%loop(%str(pufmeps.h171 | pufmeps.h181))


*Combine MEPS-HC data for 2014 and 2015;
data FYC14_15_ana;
   set FY_2014 FY_2015;
         if year=2014 then do;
		    perwt14_15f=perwt14f/2;
		    totexp=totexp14;
			insurc=insurc14;
		  end;

		 else if year=2015 then do;
		     perwt14_15f=perwt15f/2;
		     totexp=totexp15; 
			 insurc=insurc15;
		end;
proc sort data=	FYC14_15_ana; by varpsu varstr; run;

proc crosstab data=FYC14_15_ana filetype=sas DESIGN=WR;
            nest varpsu varstr / missunit;
       		subpopn veteran=1 & agelast <65 & totexp>0 
               & (insurc>=1 & insurc<=3) 
               & perwt14_15f>0;
            weight perwt14_15f;
			rformat insurc insfmt.;
			subgroup va_paid insurc;
       		levels   2         3 ;
			tables va_paid*insurc;
    		setenv colwidth=18 decwidth=0;
            PRINT NSUM="Sample Size" WSUM = "Weighted Size" rowper= "Row %"  serow /style=nchs
	        nsumfmt=F10.0 wsumfmt=F10.0  rowperfmt=F5.1 serowfmt=F5.2;
	       run;
 
	 
