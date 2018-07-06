**** Program: 		Figure_Three_2014_2015.sas       		    ****;
**** Author: 		Pradip Muhuri, Steve Machlin     		    ****;
**** Purpose:  		Generate the estimates reported	    	            ****;
**** 			in Figure 3 of	                                    ****;
****                    Stat Brief #504    				    ****;
**** Data Files 	1. full year consolidated files, 2014-2015          ****;
****                    2. medical provider visit files, 2014-2015          ****;

proc datasets nolist kill; quit;
proc format ;
 value agefmt 1= '0-17'
              2 = '18-64'
		      3 = '65+';
value ins_cat_F  0='Total'
                 1= 'Medicaid'
                 2='Private'
                 3='Other';
value regionfmt 0= 'Total'
                 1= 'NORTHEAST' 
                 2='MIDWEST' 
                 3='SOUTH' 
                 4 ='WEST'; 
value YY_speclty_F  0 = 'Total'
                 .N = ' '
                 .M = ' '
                 1 ='PRIMARY CARE'
                 2='PEDIATRICS'
                 3='PSYCHIATRY'
                 4='OPHALMOLOGY'
                 5='ORTHOPEDICS'
                 6 = 'Other';
				 value Rcvvac_F 0 = 'Total'
                  1 =  'Yes'
                  2 =  'No'
                  3 =  'No Service Received'
                  . = ' ';
run;
* 2014-2015 MEPS FY Consolidated Files ;	
%macro loop(dslist);
%local yr i ;
%let yr=14;
          %DO i = 1 %to %sysfunc(countw(&dslist, | ));
		               data fy_20&yr.rev; 
				       set %scan(&dslist, &i, |) 
                           (keep= dupersid agelast 
				            varstr varpsu perwt&yr.f
  				            region31 region42 region53 region&yr);

                    /* Create the age group variable */ 
                    if agelast<=17 then age_grp=1;
					else if 18<=agelast<=64 then age_grp=2;
					else if agelast>=65 then age_grp =3;

					/*create the region variable */
                    if region&yr>0  then region=region&yr;
					else if region&yr<0 and region42>0  then region=region42;
					else region=region31;	
	       FORMAT age_grp agefmt. region regionfmt.;
		   run;
		   proc sort data= fy_20&yr.rev; by dupersid; run; 
	  %let yr= %eval(1+&yr);
	  %end;
%mend loop;
%loop(%str(pufmeps.h171|pufmeps.h181))

*** Read visit-level files;

%macro loop (dslist);
 %local yr i ;
  %let yr=14;
          %DO i = 1 %to %sysfunc(countw(&dslist, | ));
		     data ob_20&yr.rev;  
             set %scan(&dslist, &i, | ) 
			    (keep= DUPERSID SEETLKPV SEEDOC varstr varpsu 
                           perwt&yr.f 
						   OBTC&yr.x  /* total charge */
						   OBXP&yr.x  /* the sum of the 12 sources of payment for the office-based expenditures */
						   OBSF&yr.x  /*self/family*/
                           OBMR&yr.x  /*Medicare */
						   OBOU&yr.x  /* other public insurance */
                           OBMD&yr.x  /*Medicaid*/
                           OBPV&yr.x /*private insurance*/
						   OBTR&yr.x  /*Tricare*/
			               OBVA&yr.x  /*Veterans*/
                           OBWC&yr.x  /* Workers Compensation*/
						   OBSL&yr.x  /* state and local (non-federal) government sources */
			               OBOF&yr.x /* other federal sources*/
                           OBOR&yr.x  /* other private insurance */
                           OBOT&yr.x  /*other insurance */
                           		               
                           ANESTH eeg ekg labtest mammog MEDPRESC mri 
                           RCVVAC SONOGRAM THRTSWAB XRAYS
                           SURGPROC drsplty   VSTCTGRY);

			          *3-category insurance variable;
				     if OBMD&yr.x >0 then Ins_cat=1;
	                 else if OBPV&yr.x >0 then Ins_cat=2;
                     else  Ins_cat=3;
					  				
					 * Year variable;
    				 xyear=cats(20,&yr);
                   run;
				   proc sort data=fy_20&yr.rev; by dupersid; run; 
 	            %let yr = %eval(&yr + 1);
               %end;
%mend loop;
%loop(%str(pufmeps.h168g|pufmeps.h178g))


run;
*** Merge the individual-level and visit-level files;
%macro run_by_year(start=, stop=);
   %do yr= &start %to &stop;
	    * merge obv EVENT and PERSON files to add the AGELAST variable from the PERSON file;
     	data obv20&yr.M_rev ;
	   		merge ob_20&yr.rev(in=a)
                  fy_20&yr.REV (in=b drop=perwt&yr.f varpsu varstr); by dupersid;       
			if a=b;
        run;  
		proc sort data=obv20&yr.M_rev; by varpsu varstr; run;
		run;
	 %end;
%mend run_by_year;
%run_by_year(start=14, stop=15);

data OBV2014_15_ana_rev;
   set OBV2014M_rev (in=File14)
       OBV2015M_rev (in=File15);

      if agelast<=17 & seedoc=1 & seetlkpv=1
      & (perwt14f>0 | perwt15f>0)
      & ins_cat >=1 and ins_cat <=2 then subpop_obv=1;
      else subpop_obv= 2;

     if file14=1 then do;
        perwt14_15f=perwt14f/2;
        obxp14_15x=obxp14x;
     end;
     if file15=1 then do;
       perwt14_15f=perwt15f/2;
       obxp14_15x=obxp15x;
     end;

* 6 category Specialty;
if drsplty = -1 then YY_specialty=.N;
else if drsplty in (-7, -8, -9) then YY_specialty=.M;
else if drsplty in (6, 8, 14) then YY_specialty=1;
else if drsplty = 24  then YY_specialty=2;
else if drsplty = 28 then YY_specialty=3;
else if drsplty = 19  then YY_specialty=4;
else if drsplty = 20 then YY_specialty=5;
else YY_specialty=6;

*RCVVAC ;
if  rcvvac LE 0 then x_rcvvac=.;
else if rcvvac =1 then x_rcvvac=1;
else if rcvvac =2 then x_rcvvac=2;
else if rcvvac =95 then x_rcvvac=3;

* specialty dummies ;

if YY_specialty=1 then pry_care_doc=1;
else if YY_specialty in (2,3,4,5,6) then pry_care_doc=0;

if YY_specialty=2 then pedi=1;
else if YY_specialty in (1,3,4,5,6) then pedi=0;

if YY_specialty in (1,2) then pry_care_pedi=1;
else if YY_specialty in (3,4,5,6) then pry_care_pedi=0;

if YY_specialty=3 then psy=1;
else if YY_specialty in (1,2,4,5,6) then psy=0;

if YY_specialty=4 then opthal=1;
else if YY_specialty in (1,2,3,5,6) then opthal=0;

if YY_specialty=5 then ortho=1;
else if YY_specialty in (1,2,3,4,6) then ortho=0;

if YY_specialty=6 then other_doc=1;
else if YY_specialty in (1,2,3,4,5) then other_doc=0;

if x_rcvvac=1 then vaccine=1;
else if x_rcvvac in (2,3) then vaccine=0;


*4 region dummy variables;

if region=1 then x_region1=1; else x_region1=0;
if region=2 then x_region2=1; else x_region2=0;
if region=3 then x_region3=1; else x_region3=0;
if region=4 then x_region4=1; else x_region4=0;


Format ins_cat ins_cat_F. YY_specialty YY_speclty_F.
       x_rcvvac rcvvac_F.;
run;
%macro loop(list);
   %let k=1;
   %let xvar=%scan(&list, &k);
   %do %while(&xvar NE);
      proc sort data=OBV2014_15_ana_rev; by varpsu varstr; run; 
        proc crosstab data=obv2014_15_ana_rev filetype=sas DESIGN=WR;
            nest varpsu varstr  / missunit;
       		subpopn agelast<=17 & seedoc=1 & seetlkpv=1 & perwt14_15f>0 
                    & ins_cat >=1 and ins_cat <=2 ;
       		weight perwt14_15f;
       		subgroup ins_cat region YY_specialty x_rcvvac;
       		levels    2 4  6  3;
    		tables ins_cat*&xvar;
            setenv colwidth=18 decwidth=0;
      PRINT NSUM="Sample Size" WSUM = "Weighted Size" rowper= "Row %"  serow /style=nchs
	  nsumfmt=F10.0 wsumfmt=F10.0  rowperfmt=F5.1 serowfmt=F5.2;
	  output  nsum wsum rowper="Pct" serow="SE_PCT" 
        /filename=INS_14_15_&xvar replace;   
       run;
        %let k = %eval(&k+1);
       %let xvar=%scan(&list, &k);  
  %end;
  %mend loop;
  %loop(region YY_specialty x_rcvvac);
%let dropped_vars = PROCNUM TABLENO  _ONE_ VARIABLE CONTRAST _C2;

PROC DESCRIPT DATA=OBV2014_15_ana_rev DESIGN=WR FILETYPE=SAS;
 nest varpsu varstr  / missunit;
 subpopn agelast<=17 & seedoc=1 & seetlkpv=1 & perwt14_15f>0 
                    & ins_cat >=1 and ins_cat <=2 ;
weight perwt14_15f;
VAR x_region1 x_region2 x_region3 x_region4
    pry_care_doc pedi  psy  opthal ortho other_doc;
subgroup ins_cat;
levels 2;
pairwise ins_cat / name="Medicaild vs. Private";
SETENV DECWIDTH=6 COLWIDTH=18;
PRINT mean semean t_mean p_mean  / REPLACE
STYLE=NCHS
meanfmt=F8.4 semeanfmt=F8.5;
output mean semean t_mean p_mean / replace filename=t_sb;
run;
proc print data=t_sb (drop= &dropped_vars) noobs; 
format  mean percent9.2 semean percent9.2 t_mean p_mean;
run;
