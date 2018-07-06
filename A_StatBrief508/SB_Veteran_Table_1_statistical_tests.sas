
/******************************************************************************** 
    SB508 Characteristics and Health Care Expenditures of VA Health System Users 
          versus Other Veterans, 2014-15 (average annual) 
    Program Wriiten By: Pradip K. Muhuri
    This program produces results from statistical tests for Table 1 
    of the Stat Brief.
**********************************************************************************/


OPTIONS nocenter obs=max ps=58 ls=132 nodate nonumber;
libname pufmeps  'S:\CFACT\Shared\PUF SAS files\SAS V8' access=readonly;
proc datasets nolist kill; quit;
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

   *Create dummy variables;
    	    if 18<=agelast<=64 then age18_64=1; else age18_64=0;
			if agelast>=65 then age65p=1; else age65p=0;

			if sex=1 then male=1; else male=0;
			if sex=2 then female=1; else female=0;

            if RTHLTH ne 0 then do;
              if RTHLTH in (1,2,3) then Health_g_vg_ex=1; 
                else Health_g_vg_ex=0;

              if RTHLTH in (4,5) then Health_fp=1; 
                else Health_fp=0;
            end;

			if racethx ne . then do;
              if racethx=1 then Hisp=1; else hisp=0;
              if racethx=2 then NHW=1; else NHW=0;
			  if racethx=3 then NHB=1; else NHB=0;
			  if racethx=4 then NHA=1; else NHA=0;
			  if racethx=5 then NHO=1; else NHO=0;
			end;
            
			 if x_povcat&yr=1 then poor_np=1; else poor_np=0;
			 if x_povcat&yr=2 then low_income=1; else low_income=0;
             if x_povcat&yr=3 then mid_income=1; else mid_income=0;
			 if x_povcat&yr=4 then hi_income=1; else hi_income=0;

  
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

%let dropped_vars = PROCNUM TABLENO  _ONE_ VARIABLE CONTRAST _C2;
proc sort data=FYC14_15_ana; by varpsu varstr ;
PROC DESCRIPT DATA=FYC14_15_ana DESIGN=WR FILETYPE=SAS;
 nest varpsu varstr  / missunit;
 subpopn veteran=1 & totexp>0 & perwt14_15f>0;
weight perwt14_15f;
VAR totexp age18_64 age65p  
           male female 
           Health_g_vg_ex health_fp
           hisp nhw nhb nha nho 
          poor_np low_income mid_income hi_income;
subgroup va_paid;
levels 2;
pairwise va_paid / name="VA Users vs. Non-VA Users";
SETENV DECWIDTH=6 COLWIDTH=18;
PRINT mean semean t_mean p_mean  / REPLACE
STYLE=NCHS
meanfmt=F12.4 semeanfmt=F8.3;
output mean semean t_mean p_mean / replace filename=t_sb;
run;
proc print data=t_sb (drop= &dropped_vars) noobs; 
format  mean semean t_mean p_mean;
run;

 
