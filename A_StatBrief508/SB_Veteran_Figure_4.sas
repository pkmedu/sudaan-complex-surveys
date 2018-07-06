******************************************************************************** 
    SB508 Characteristics and Health Care Expenditures of VA Health System Users 
          versus Other Veterans, 2014-15 (average annual) 
    Program Wriiten By: Pradip K. Muhuri
    This program generates estimates that are used for Figure 4 of the Stat Brief.
**********************************************************************************/

OPTIONS nocenter obs=max ps=58 ls=132 nodate nonumber;
libname pufmeps  'S:\CFACT\Shared\PUF SAS files\SAS V8' access=readonly;
proc datasets nolist kill; quit;
proc format;
  value VAusefmt  0= 'All Veterans'
                  1= 'VA-User'
                  2 = 'Non-Var User';              
run;
%let vars_kept = agelast HONRDC31  HONRDC42  HONRDC53
                 VARPSU VARSTR perwt: 
                 totexp: totva: totslf:  totmcr: totmcd: totptr: ;
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

  *Create a varibale for all other sources;
           tototh&yr = totexp&yr - sum(totslf&yr, totva&yr, 
                                       totmcr&yr, totmcd&yr, totptr&yr); 
   
         format  VA_paid VAusefmt.  ;
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
			totslf=totslf14;
          totva=totva14;
          totmacr=totmcr14;
          totmcd=totmcd14;
          totptr=totptr14;
		  tototh=tototh14;
		  totmcd_oth=sum(totmcd14, tototh14);
		  if tototh=-1 then tototh=0;
		  end;

		 else if year=2015 then do;
		     perwt14_15f=perwt15f/2;
		     totexp=totexp15; 
			 totslf=totslf15;
          totva=totva15;
          totmacr=totmcr15;
          totmcd=totmcd15;
          totptr=totptr15;
		  tototh=tototh15;
		  totmcd_oth=sum(totmcd15, tototh15);
		  if tototh=-1 then tototh=0;
		end;
run;
proc sort data=	FYC14_15_ana; by varpsu varstr; run;

/***Calculate the percentage of total medical expenditures for each of the 5 service types;
    The five service types include: 
    - Hospital inpatients stays
    - Office-based provider visits
    - Prescription medicines
    - Hospital outpatient visits
    - Other services (emergency room visits, dental visits, and others)
*/
 %macro run_ratio (n=, d=) ;
            proc ratio data=FYC14_15_ana filetype=sas DESIGN=WR;
       		nest varpsu varstr  / missunit;
       		subpopn veteran=1 & totexp>0 & perwt14_15f>0;
       		weight perwt14_15f;;
       		numer &n  ;
			denom &d;
    		CLASS va_paid; 
            TABLES va_paid;
SETENV LABWIDTH=20 COLSPCE=1 colwidth=10 decwidth=0; 
print NSUM="Sample" WSUM="PopSize" WYSUM="WYSUM" WXSUM="WXSUM" RHAT="Ratio"
/ NSUMFMT=F6.0 WSUMFMT=F13.0 RHATFMT=F6.4 STYLE=NCHS;
SETENV LABWIDTH=20 COLSPCE=1 colwidth=6 decwidth=4; PRINT RHAT="Ratio" SERHAT="SE" 
LOWRHAT="Lower 95% Limit" UPRHAT="Upper 95% Limit" / STYLE=NCHS;
RTITLE "Proportion of Charges ($) Going into &d";
run;
    %mend run_ratio;
    %run_ratio (n=totslf, d=totexp)
  	%run_ratio (n=totptr, d=totexp)
	%run_ratio (n=totmacr, d=totexp)
	%run_ratio (n=totva, d=totexp)
	%run_ratio (n=totmcd_oth, d=totexp)
;
*** Do statistical tests - VA Users vs. NonVA Users;
%macro run_ratio (n=, d=) ;
          proc ratio data=FYC14_15_ana filetype=sas DESIGN=WR;
       		nest varpsu varstr  / missunit;
       		subpopn veteran=1 & totexp>0 & perwt14_15f>0;
       		weight perwt14_15f;
			CLASS va_paid; 
            numer &n  ;
			denom &d;
    		CONTRAST va_paid=(1 -1) / name="VA Users vs. Non_VA Users";   
            SETENV LABWIDTH=20 COLSPCE=1 colwidth=10 decwidth=0; 
			PRINT RHAT="Difference" SERHAT="SE" T_RHAT="T-Stat" P_RHAT="P-value"
            / STYLE=NCHS rhatfmt=f10.4 serhatfmt=f6.4 p_rhatfmt=f7.4;
RTITLE "Proportion of Total Expenditures ($) Going into &n";
run;
    %mend run_ratio;
 	%run_ratio (n=totslf, d=totexp)
  	%run_ratio (n=totptr, d=totexp)
	%run_ratio (n=totmacr, d=totexp)
	%run_ratio (n=totva, d=totexp)
	%run_ratio (n=totmcd_oth, d=totexp)
