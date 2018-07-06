******************************************************************************** 
    SB508 Characteristics and Health Care Expenditures of VA Health System Users 
          versus Other Veterans, 2014-15 (average annual) 
    Program Wriiten By: Pradip K. Muhuri
    This program generates estimates that are used for Figure 3b of the Stat Brief.
**********************************************************************************/

OPTIONS nocenter obs=max ps=58 ls=132 nodate nonumber;
libname pufmeps  'S:\CFACT\Shared\PUF SAS files\SAS V8' access=readonly;
proc datasets nolist kill; quit;
proc format;
value insfmt    1  ='65+ Medicare Only' 
				2 ='65+ Medicare/Private' 
				3 ='65+ Medicare/Other Public Only';
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


  *Create a new INSURC (r_insurc) variable for ages 65+;
          if insurc&yr in (1,2,3,7,8) then r_insurc&yr=.;  
          else r_insurc&yr=insurc&yr - 3 ;             
    format   VA_paid VAusefmt. insurc&yr insfmt. ;
    run;
    %let yr = %eval(&yr + 1);
   %end;
%mend loop;
%loop(%str(pufmeps.h171 | pufmeps.h181))


data FYC14_15_ana;
   set FY_2014 FY_2015;
         if year=2014 then do;
		    perwt14_15f=perwt14f/2;
		    totexp=totexp14;
			r_insurc=r_insurc14;
		  end;

		 else if year=2015 then do;
		     perwt14_15f=perwt15f/2;
		     totexp=totexp15; 
			 r_insurc=r_insurc15;
		end;
proc sort data=	FYC14_15_ana; by varpsu varstr; run;
proc crosstab data=FYC14_15_ana filetype=sas DESIGN=WR;
            nest varpsu varstr / missunit;
       		subpopn veteran=1 & agelast >=65 & totexp>0 
               & (r_insurc>=1 & r_insurc<=3) 
               & perwt14_15f>0;
            weight perwt14_15f;
			rformat r_insurc insfmt.;
			subgroup va_paid r_insurc;
       		levels   2         3 ;
			tables va_paid*r_insurc;
    		setenv colwidth=18 decwidth=0;
            PRINT NSUM="Sample Size" WSUM = "Weighted Size" rowper= "Row %"  serow /style=nchs
	        nsumfmt=F10.0 wsumfmt=F10.0  rowperfmt=F5.1 serowfmt=F5.2;
	       run;
 
	 
