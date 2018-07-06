**** Program: 		Intro_estimates_2015.sas        		    ****;
**** Author: 		Pradip Muhuri, Steve Machlin     		    ****;
**** Purpose:  		Generate the estimates reported 	    	    ****;
**** 				in the INTRO section of                     ****;
****                    Stat Brief #504					    ****;
**** Data Files 	1. medical provider visit file, 2015                ****;
****                    2. full year consolidated file, 2015)               ****;   

OPTIONS nocenter nodate nonumber ps=58 ls=132 ;
proc datasets nolist kill; quit;
proc format;
 value agefmt  1= '0-17'
               2 = '18-64'
		       3 = '65+';
value ins_cat_F  0='Total'
                 1= 'Medicaid'
                 2='Private'
                 3='Other'
                 . = ' ';
run;
*** Create medical provider visit  working file for 2015;
data mpvisits15; 
    set pufmeps.h178g (keep=DUPERSID SEETLKPV SEEDOC 
                         varstr varpsu perwt15f OBMD15x 
                         OBPV15x obxp15x);

               *3-category insurance variable;
		       if OBMD15x >0 then Ins_cat=1;
	           else if OBPV15x >0 then Ins_cat=2;
               else  Ins_cat=3;
run;
proc sort data=mpvisits15; by dupersid; run;

*** Create full year consolidated working file for 2015;
data FYC15;
  set pufmeps.h181 (keep= dupersid agelast varstr varpsu perwt15f);
  if agelast<=17 then age_grp=1;
					else if 18<=agelast<=64 then age_grp=2;
					else if agelast>=65 then age_grp =3;
run;

proc sort data=FYC15; by dupersid; run;
data visits_indi;
  merge mpvisits15 (in=a) FYC15 (in=b keep=dupersid agelast); 
        by dupersid;
run;

proc sort data=visits_indi ; by varpsu varstr; run;


*Estimating the number of Children in 2015;
 
proc CROSSTAB  data=FYC15 NOTSORTED FILETYPE=SAS DESIGN=WR;
     		nest varstr varpsu /missunit;
     		weight  perwt15f;
	 		subpopn perwt15f>0;
     		subgroup age_grp; 
     		LEVELS  3;
     		tables age_grp;
			rformat age_grp agefmt.;
     		setenv colwidth=12 decwidth=4;
     		PRINT NSUM wsum rowper  serow /style=nchs 
        	wsumfmt=F10.0 rowperfmt=F6.1 serowfmt=F7.3;
        	       
    	run;

*Estimating the number of Child Visits in 2015;
proc CROSSTAB  data=visits_indi NOTSORTED FILETYPE=SAS DESIGN=WR;
     		nest varstr varpsu /missunit;
     		weight  perwt15f;
	 		subpopn agelast <=17 & perwt15f>0;
     		subgroup ins_cat; 
     		LEVELS  3;
     		tables ins_cat;
			rformat ins_cat ins_cat_F.;
     		setenv colwidth=12 decwidth=4;
     		PRINT NSUM wsum rowper serow /style=nchs 
        	nsumfmt=F9.0 wsumfmt=F10.0 rowperfmt=F6.1 serowfmt=F7.3;
run;

*Estimating the number of Child Visits in 2015 (seedoc=1 & seetlkpv=1);
proc CROSSTAB  data=visits_indi NOTSORTED FILETYPE=SAS DESIGN=WR;
     		nest varstr varpsu /missunit;
     		weight  perwt15f;
	 		subpopn agelast <=17 & seedoc=1 & seetlkpv=1 & perwt15f>0;
     		subgroup ins_cat; 
     		LEVELS  3;
     		tables ins_cat;
			rformat ins_cat ins_cat_F.;
     		setenv colwidth=12 decwidth=4;
     		PRINT NSUM wsum rowper serow /style=nchs 
        	nsumfmt=F9.0 wsumfmt=F10.0 rowperfmt=F6.1 serowfmt=F7.3;
run;


