/******************************************************************************** 
    SB508 Characteristics and Health Care Expenditures of VA Health System Users 
          versus Other Veterans, 2014-15 (average annual) 
    Program Wriiten By: Pradip K. Muhuri
    This program generates estimates for Table 1 of the Stat Brief.
**********************************************************************************/

OPTIONS nocenter obs=max ps=58 ls=132 nodate nonumber;
libname pufmeps  'S:\CFACT\Shared\PUF SAS files\SAS V8' access=readonly;
proc datasets nolist kill; quit;
proc format;
 value agefmt      1 ='18-64'
                   2 = '65+';
				   
  value VAusefmt  0= 'All Veterans'
                  1= 'VA-User'
                  2 = 'Non-Var User';
                  
 value sexfmt   1 = 'Male'
                2 = 'Female'; 
			
VALUE RacethxF  
  .  = 'Missing'
  1 = 'Hispanic'
  2 = 'NH White'
  3 = 'NH Black'
  4 = "NH Aisan"
  5 = "NH Other"
  ;
value povcatF 
        1 = 'POOR/NEAR POOR' 
		2 = 'LOW INCOME' 
		3 = 'MIDDLE INCOME'  
		4 = 'HIGH INCOME' ;

 VALUE RTHLTHfmt   
  0 = 'Total'
  1 = 'Good-Very Good-Excellent'
  2 = 'Poor-Fair'  
  . =' ';
run;
%let vars_kept = dupersid agelast sex race:
                 HONRDC31  HONRDC42  HONRDC53
                 VARPSU VARSTR perwt: 
                 povcat: race: RTHLTH: totexp: totva:;
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
               
  * age categories;
	  if 18<=agelast<=64  then age_grp=1;
          else if agelast>=65  then age_grp=2;

  /*create the perceived health status variable*/
	 if RTHLTH53>0 then RTHLTH = RTHLTH53;
         else if RTHLTH53 <0 and RTHLTH42>0 then RTHLTH = RTHLTH42;
         else RTHLTH= RTHLTH31;

          if RTHLTH <0 then r_RTHLTH=.;  
          else if RTHLTH in (1,2,3) then r_RTHLTH=1; 
          else if RTHLTH in (4,5) then r_RTHLTH=2; 

  /* Create a new variable, X_POVCATyy by collapsing categories 1 and 2 for the POVCATyy variable */
   if povcat&yr in (1,2) then x_povcat&yr = 1;
   else x_povcat&yr = povcat&yr - 1;
  
     format  age_grp agefmt. 
             sex sexfmt.  VA_paid VAusefmt. 
             x_povcat&yr povcatF. 
             racethx racethxF. r_RTHLTH RTHLTHfmt. ;
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
		    x_povcat=x_povcat14;
			totexp=totexp14;
		  end;

		 else if year=2015 then do;
		     perwt14_15f=perwt15f/2;
		     x_povcat=x_povcat15;
             totexp=totexp15; 
		end;
proc freq data=FYC14_15_ana; tables veteran; run;

proc sort data=	FYC14_15_ana; by varpsu varstr; run;
  proc crosstab data=FYC14_15_ana filetype=sas DESIGN=WR;
        nest varpsu varstr / missunit;
	subpopn veteran=1 & totexp>0 & perwt14_15f>0;
        weight perwt14_15f;
	rformat x_povcat povcatF.;
	subgroup veteran  va_paid age_grp  sex racethx x_povcat r_RTHLTH ;
 	levels    2           2       2      2     5     4        2  ;
	tables va_paid*age_grp  va_paid*sex  va_paid*racethx
               va_paid*x_povcat va_paid*r_RTHLTH ;
            setenv colwidth=18 decwidth=0;
            PRINT NSUM="Sample Size" 
                  WSUM = "Weighted Size" 
                  rowper= "Row %"  
                  serow /style=nchs
	          nsumfmt=F10.0 
                  wsumfmt=F10.0  
                  rowperfmt=F5.1 
                  serowfmt=F5.2;
	       run;
 
	 
