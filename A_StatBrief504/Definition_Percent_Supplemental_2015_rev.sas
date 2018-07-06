
**** Program: 		Definition_Percent_Supplemental_2015_rev.sas  	    ****;
**** Author: 		Pradip Muhuri, Steve Machlin     		    ****;
**** Purpose:  		Percent of payment from other miscellenous sources  ****;
**** 			in Definitions 2 of	                    	    ****;
****                    Stat Brief #504					    ****;
**** Data Files  	1. full year consolidated file, 2015                ****;
****                    2. medical provider visits file, 2015               ****;

proc datasets nolist kill; quit;

proc format ;
 value agefmt 1= '0-17'
              2 = '18-64'
		      3 = '65+';
value ins_cat_F  0='Total'
                 1= 'Medicaid'
                 2='Private'
                 3='Other';

data FYC15;
  set pufmeps.h181 (keep= dupersid agelast varstr varpsu perwt15f);
  if agelast <=17;
run;

proc sort data=FYC15; by dupersid; run;


data mpvisits15; 
    set pufmeps.h178g ;
         if seedoc=1 & seetlkpv=1 & perwt15f>0;
     array  ob[*]             OBSF15x  /*self/family*/
                           OBMR15x  /*Medicare */
						   OBOU15x  /* other public insurance */
                           OBMD15x  /*Medicaid*/
                           OBPV15x /*private insurance*/
						   OBTR15x  /*Tricare*/
			               OBVA15x  /*Veterans*/
                           OBWC15x  /* Workers Compensation*/
						   OBSL15x  /* state and local (non-federal) government sources */
			               OBOF15x /* other federal sources*/
                           OBOR15x  /* other private insurance */
                           OBOT15x  /*other insurance */
						   ;
    array  name[*]         OOP  
                           Medicare  
						   OthPub  
                           Medicaid 
                           Private 
						   Tricare  
			               Veteran  
                           Wcomp  
						   StateLocal  
			               OthFed 
                           OthPrivate  
                           Other  
						   ;
	do i = 1 to dim(ob);
    if ob[i] >0 then  name[i] = 1; else name[i] = 0;
	list= catx(',',
	     ifc(Private=1, 'Private', '  '),
         ifc(OthPrivate=1, 'OthPrivate', '  '),
         ifc(Medicaid=1, 'Medicaid', '  '),
         ifc(OOP=1, 'OOP', '  '),
         ifc(StateLocal=1, 'StateLocal', '  '),
         ifc(OthPub=1, 'OthPub', '  '),
         ifc(Medicare=1, 'Medicare', '  '),

		 ifc(Tricare=1, 'Tricare', '  '),
         ifc(Veteran=1, 'Veteran', '  '),
         ifc(Wcomp=1, 'Wcomp', '  '),
         ifc(OthFed=1, 'OthFed', '  '),
         ifc(Other=1, 'Other', '  '));

	end;

               *3-category insurance variable;
		       if OBMD15x >0 then Ins_cat=1;
	           else if OBPV15x >0 then Ins_cat=2;
               else  Ins_cat=3;    
	run;

data have;
  merge mpvisits15 (in=a) FYC15 (in=b keep=dupersid agelast); 
        by dupersid;
  if a=b;
run;

proc sort data=visits_indi ; by varpsu varstr; run;



proc freq data=have; 
tables  list /*OOP  Medicare  OthPub  Medicaid 
       Private Tricare  Veteran  
       Wcomp  StateLocal  OthFed 
       OthPrivate   Other*/  ;
	   weight perwt15f;
	   where ins_cat=1;
	   title 'Medicaid Insurance Subgroup';
	   run;

proc freq data=have; 
tables  list /*OOP  Medicare  OthPub  Medicaid 
       Private Tricare  Veteran  
       Wcomp  StateLocal  OthFed 
       OthPrivate   Other*/  ;
	   weight perwt15f;
	   where ins_cat=2;
	   title 'Private Insurance Subgroup';
	   run;
  
proc freq data=have; 
tables  list /*OOP  Medicare  OthPub  Medicaid 
       Private Tricare  Veteran  
       Wcomp  StateLocal  OthFed 
       OthPrivate   Other */ ;
	   weight perwt15f;
	   where ins_cat=3;
	   title 'Other Insurance Subgroup';
	   run;

	proc freq data=have order=internal;
	weight perwt15f;
	tables ins_cat / missing ;
	format ins_cat ins_cat_F.;
	run;

