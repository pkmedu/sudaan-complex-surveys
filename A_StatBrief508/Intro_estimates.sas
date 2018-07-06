
/******************************************************************************** 
    SB508 Characteristics and Health Care Expenditures of VA Health System Users 
          versus Other Veterans, 2014-15 (average annual) 
    Program Wriiten By: Pradip K. Muhuri
    This program generates estimates that are added to the text/footnote on the 
    first page of the Stat Brief.
**********************************************************************************/


OPTIONS nocenter obs=max ps=58 ls=132 nodate nonumber;
libname pufmeps  'S:\CFACT\Shared\PUF SAS files\SAS V8' access=readonly;
proc datasets nolist kill; quit;
proc format;
value VAfmt 0 ='Total'
            1='Veteran'
            2 = 'Non-Veteran';
value VAusefmt  0= 'All Veterans'
                  1= 'VA-User'
                  2 = 'Non-Var User';
value yesnofmt  1= 'Yes'
                2 = 'No';
run;
%let vars_kept = agelast HONRDC31  HONRDC42  HONRDC53
                 VARPSU VARSTR perwt:
                 obtotv: optotv: ertot: ipdis: 
                 rxtot: dvtot:
                 totva:
                 totexp:  obvexp: optexp: ertexp: iptexp: rxexp: dvtexp:;
* Create data for 2014-2015;
%macro loop(dslist);
%local i yr;
  %let yr=14;
  %DO i = 1 %to %sysfunc(countw(&dslist, %str(|)));
   data FY_20&yr (drop = _:);
     set %scan(&dslist, &i, |)  (keep=&vars_kept);
	       year=20&yr.;

 /****************HONRDC31,  HONRDC42,  HONRDC53 ************* 
(Whether HONORABLY DISCHARGED FROM MILITARY) 
 9 NOT ASCERTAINED 
-8 DK 
-7 REFUSED 
-1 INAPPLICABLE 
1 YES - HONORABLY DISCHARGED 
2 NO - NOT HONORABLY DISCHARGED 
3 16 OR YOUNGER - INAPPLICABLE 
4 NOW ACTIVE DUTY 
*******************************************************/
*Create a variable called VETERAN that deternines the Vetaran status;
          Array Honvars[3] HONRDC31  HONRDC42  HONRDC53;
		  do _i = 1 to 3;
		   if Honvars[_i] <0 or Honvars[_i]=3 then veteran=.;
		   else if Honvars[_i] = 1 then veteran=1;
		   else if Honvars[_i] in (2,4) then veteran=2;
		  end;    

 /*Create a variable called (VA_paid) that determines 
  whether veterans used the VA facility */
 
  if veteran=1 then VA_paid = IFN(totva&yr >0, 1,2);

  *Create "ANYUSE" (any of 6 services) variable;;
   anyuse&yr = IFN(sum(obtotv&yr, optotv&yr, ertot&yr, ipdis&yr, 
                    rxtot&yr, dvtot&yr)>0,1,2);
   *Create "ANYEXP" (total medical expeditures >0) ;
	anyexp&yr= IFN(totexp&yr>0, 1, 2);
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
		  	anyuse=anyuse14;
		  	anyexp=anyexp14;
			totexp=totexp14;
			obvexp=obvexp14;
            optexp=optexp14;
            ertexp=ertexp14;
            iptexp=iptexp14;
            rxexp=rxexp14;
            dvtexp=dvtexp14;
		  end;

		 if year=2015 then do;
		  perwt14_15f=perwt15f/2;
		  totexp=totexp15; 
		  obvexp=obvexp15;
          optexp=optexp15;
          ertexp=ertexp15;
          iptexp=iptexp15;
          rxexp=rxexp15;
       	  anyuse=anyuse15;
		  anyexp=anyexp15;
         end;
format  Veteran VAfmt. VA_paid VAusefmt.
        anyuse anyexp yesnofmt.;
run;

proc sort data=FYC14_15_ana; by varpsu varstr; run;
  proc crosstab data=FYC14_15_ana filetype=sas DESIGN=WR;
            nest varpsu varstr / missunit;
       		subpopn veteran>=1 & totexp>0 & perwt14_15f>0;
            weight perwt14_15f;
			subgroup  veteran; 
       		levels      2  ;
    		tables veteran;
            setenv colwidth=18 decwidth=0;
            PRINT NSUM="Sample Size" WSUM = "Weighted Size" rowper= "Row %"  serow /style=nchs
	        nsumfmt=F10.0 wsumfmt=F10.0  rowperfmt=F5.1 serowfmt=F5.2;
	       run;
  
  proc crosstab data=FYC14_15_ana filetype=sas DESIGN=WR;
            nest varpsu varstr / missunit;
       		subpopn veteran=1 & totexp>0 & perwt14_15f>0;
            weight perwt14_15f;
			subgroup va_paid ;
       		levels    2   ;
    		tables va_paid;
            setenv colwidth=18 decwidth=0;
            PRINT NSUM="Sample Size" WSUM = "Weighted Size" rowper= "Row %"  serow /style=nchs
	        nsumfmt=F10.0 wsumfmt=F10.0  rowperfmt=F5.1 serowfmt=F5.2;
	       run;
 
proc crosstab data=FYC14_15_ana filetype=sas DESIGN=WR;
            nest varpsu varstr / missunit;
       		subpopn veteran=1 & totexp=0 & perwt14_15f>0;
            weight perwt14_15f;
			subgroup  anyuse; 
       		levels      2    ;
    		tables anyuse;
            setenv colwidth=18 decwidth=0;
            PRINT NSUM="Sample Size" WSUM = "Weighted Size" rowper= "Row %"  serow /style=nchs
	        nsumfmt=F10.0 wsumfmt=F10.0  rowperfmt=F5.1 serowfmt=F5.2;
	       run;	  
