**** Program: 		Figures_OneTwo_2010_2015.sas       		    ****;
**** Author: 		Pradip Muhuri, Steve Machlin     		    ****;
**** Purpose:  		Generate the estimates reported	         	    ****;
**** 				in Figures 1 and 2 of	                    ****;
****                    Stat Brief #504    				    ****;
**** Data Files 	1. full year consolidated files, 2010-2015          ****;
****                    2. medical provider visit files, 2010-2015          ****;
 

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
run;
* 2010-2015 MEPS FY Consolidated Files ;	
%macro loop(dslist);
%local yr i ;
%let yr=10;
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
	       FORMAT age_grp agefmt. region&yr region31 region42 region regionfmt.;
		   run;
		   proc sort data= fy_20&yr.rev; by dupersid; run; 
	  %let yr= %eval(1+&yr);
	  %end;
%mend loop;
%loop(%str(pufmeps.h138|pufmeps.h147|pufmeps.h155|pufmeps.h163|pufmeps.h171|pufmeps.h181))

*** Read visit-level files;

%macro loop (dslist);
 %local yr i ;
  %let yr=10;
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
%loop(%str(pufmeps.h135g|pufmeps.h144g|pufmeps.h152g|pufmeps.h160g|pufmeps.h168g|pufmeps.h178g))

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
		proc freq data=obv20&yr.M_rev; 
		tables age_grp;
		where agelast<=17 & ins_cat in (1,2) & seedoc=1 & seetlkpv=1 & perwt&yr.f>0; 
	  run;
	 %end;
%mend run_by_year;
%run_by_year(start=10, stop=15);

*** Tabulations for Figure 1 ;
%macro by_year;
    %DO yr = 10 %to 15;
            proc descript data=obv20&yr.M_rev filetype=sas DESIGN=WR;
            nest varpsu varstr  / missunit;
            subpopn agelast<=17 & seedoc=1 & seetlkpv=1 & perwt&yr.f>0
                    & ins_cat >=1 and ins_cat <=2;
            weight perwt&yr.f;
            var OBXP&yr.x;
            subgroup ins_cat ;
            levels    2;
			rformat ins_cat ins_cat_F.;
            setenv colwidth=18 decwidth=0;
            print nsum wsum total setotal MEAN SEMEAN
                  /nsumfmt=F12.0 wsumfmt=F15.0 totalfmt=F15.0 setotalfmt=F12.0
                   meanfmt=f7.1 semeanfmt=F7.2 STYLE=NCHS;
                  
       run;
  %end;
  %mend by_year;
  %by_year

  *** Tabulations for Figure 2 ;

  %macro by_year;
    %DO yr = 10 %to 15;
          proc descript data=obv20&yr.M_rev filetype=sas DESIGN=WR;
       		nest varpsu varstr  / missunit;
       		subpopn agelast<=17 & seedoc=1 & seetlkpv=1 & perwt&yr.f>0 
                    & ins_cat >=1 and ins_cat <=2;  ;
       		weight perwt&yr.f;
       		var OBXP&yr.x;
			PERCENTILES 50 75 90 95 /noise ;
       		subgroup ins_cat;
       		levels     2 ;
    		tables ins_cat;
		    rformat ins_cat ins_cat_F.;
      		setenv colwidth=18 decwidth=0;
        print  nsum="Sample Size"  wsum = "Population Size" 
        qtile  SEqtile lowqtile upqtile/
        style=nchs wsumfmt=f11.0 
        nsumfmt=f8.0 qtilefmt=F6.1
        SEqtilefmt=F8.4 ;
        run;
  %end;
  %mend by_year;
 %by_year
