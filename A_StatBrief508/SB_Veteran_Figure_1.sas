/******************************************************************************** 
    SB508 Characteristics and Health Care Expenditures of VA Health System Users 
          versus Other Veterans, 2014-15 (average annual) 
    Program Wriiten By: Pradip K. Muhuri
    This program generates estimates that are used for Figure 1 of the Stat Brief.
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
                 povcat: race: RTHLTH: totexp: totva:;
* Create data for 2014-2015;
%macro loop(dslist);
%local i yr;
  %let yr=14;
  %DO i = 1 %to %sysfunc(countw(&dslist, %str(|)));
   data FY_20&yr (drop = _:);
     set %scan(&dslist, &i, |)  (keep=&vars_kept);
	       year=20&yr.;

	       
/****************HONRDC31,  HONRDC42,  HONRDC53 ******* 
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
*Create a variable called VETERAN that deternined the Vetaran status;
          Array Honvars[3] HONRDC31  HONRDC42  HONRDC53;
		  do _i = 1 to 3;
		   if Honvars[_i] <0 or Honvars[_i]=3 then veteran=.;
		   else if Honvars[_i] = 1 then veteran=1;
		   else if Honvars[_i] in (2,4) then veteran=2;
		  end;    

 /*Create a variable called (VA_paid) that determines 
  whether veterans used the VA facility */
   if veteran=1 then VA_paid = IFN(totva&yr >0, 1,2);
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
		  end;

		 else if year=2015 then do;
		     perwt14_15f=perwt15f/2;
		     totexp=totexp15; 
		end;
run;
proc sort data=	FYC14_15_ana; by varpsu varstr; run;

***Calculate MEAN medical expenditures (VA Users vs. Non-VA Users);
 %macro run_tab (dep_var=);
PROC DESCRIPT DATA=FYC14_15_ana DESIGN=WR FILETYPE=SAS;
 nest varpsu varstr  / missunit;
 subpopn veteran=1 & agelast >=18 & totexp>0 & perwt14_15f>0;
weight perwt14_15f;
VAR &dep_var;
subgroup va_paid;
levels   2;
tables va_paid;
SETENV DECWIDTH=6 COLWIDTH=18;
print nsum total setotal MEAN SEMEAN DEFFMEAN/
             nsumfmt=F10.0 totalfmt=F15.0 setotalfmt=F12.0 
              meanfmt=f7.0 deffmeanfmt=f5.2 semeanfmt=f7.2 STYLE=NCHS;
run;
%mend run_tab;
%run_tab (dep_var=totexp);

*** Do statistical tests on MEAN medical expenditures (VA Users vs. Non-VA Users);
%let dropped_vars = PROCNUM TABLENO  _ONE_ VARIABLE CONTRAST _C2;
PROC DESCRIPT DATA=FYC14_15_ana DESIGN=WR FILETYPE=SAS;
 nest varpsu varstr  / missunit;
 subpopn veteran=1 & agelast >=18 & totexp>0 & perwt14_15f>0;
weight perwt14_15f;
VAR totexp;
subgroup va_paid;
levels 2;
pairwise va_paid / name="VA Users vs. Non-VA Users";
SETENV DECWIDTH=6 COLWIDTH=18;
PRINT mean semean t_mean p_mean  / REPLACE
STYLE=NCHS
meanfmt=F12.0 semeanfmt=F8.3;
output mean semean t_mean p_mean / replace filename=t_sb;
run;
proc print data=t_sb (drop= &dropped_vars) noobs; 
format  mean semean t_mean p_mean;
run;

***Calculate MEDIAN medical expenditures (VA Users vs. Non-VA Users);
%macro run_tab (dep_var=);
PROC DESCRIPT DATA=FYC14_15_ana DESIGN=WR FILETYPE=SAS;
 nest varpsu varstr  / missunit;
 subpopn veteran=1 & agelast >=18 & totexp>0 & perwt14_15f>0;
weight perwt14_15f;
VAR &dep_var;
PERCENTILES 50 /noise ;
subgroup va_paid;
levels     2;
tables va_paid;
SETENV DECWIDTH=6 COLWIDTH=18;
print  nsum="Sample Size"  wsum = "Population Size" 
        qtile  SEqtile lowqtile upqtile/
        style=nchs wsumfmt=f11.0 
        nsumfmt=f8.0 qtilefmt=F10.0
        SEqtilefmt=F10.3 ;
        run;
run;
%mend run_tab;
%run_tab (dep_var=totexp);


