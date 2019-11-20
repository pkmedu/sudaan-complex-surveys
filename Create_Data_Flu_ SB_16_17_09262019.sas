
proc datasets nolist kill; quit;
OPTIONS nocenter obs=max ps=58 ls=132 nodate nonumber varlenchk=nowarn
        FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
LIBNAME pufmeps  'S:\CFACT\Shared\PUF SAS files\SAS V8' access=readonly;
libname new 'U:\_Flu\SDS';

FILENAME MYLOG "U:\_Flu\output\Flu_16_17__log_09262019.TXT";
FILENAME MYPRINT "U:\_Flu\output\Flu_16_17_output_09262019.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;
ODS HTML CLOSE; 
ODS listing;
/**************************************************************************************
Written by Pradip Muhuri
This program creates analytic data files (event and person-level) for
Influenza stat brief
***************************************************************************************/
%macro mac1 (yr=, cond=, clnk=);
/* Create a data set by pulling out only records for FLU from the condition file*/
	   data cond_&yr;
	    retain flu 1;
  		set pufmeps.&cond (keep=dupersid condidx ICD10CDX
                           where=(ICD10CDX='J11')); 
        run; 
    proc sort data=cond_&yr; by condidx; run;
 
 /* Create a data set by identifying unique record IDs of events 
	     (linked to each of FLU condition-records)
	     from the CLNK file by match-merging with the data set created above*/

    proc sort data=pufmeps.&clnk (Keep=DUPERSID CLNKIDX CONDIDX EVNTIDX EVENTYPE)
         out=clnk_&yr;   by CONDIDX;
    run;
    data cond_clnk_&yr;
	    merge  cond_&yr (in=CN) clnk_&yr (in=CL); by CONDIDX;
		if CN=CL;
	run;
/* Delete the duplicate cases of linked events */
    proc sort data=cond_clnk_&yr nodupkey;  by EVNTIDX;  run;
 %mend mac1;



/*This macro sums up the purchse-level expense data to the event-level */
%macro mac2 (file, yr);
proc sort DATA=pufmeps.&file 
      OUT=PMED (KEEP=LINKIDX RXXP&yr.X  RXSF&yr.X--RXOU&yr.X 
             RENAME=(LINKIDX=EVNTIDX));
BY LINKIDX;
run;

PROC SUMMARY DATA=PMED NWAY;
CLASS EVNTIDX;
VAR RXXP&YR.X RXSF&YR.X--RXOU&YR.X;
OUTPUT OUT=XPMED SUM=;
RUN;

%mend mac2;


;
/*This macro creates recode for source payment for six events */
 %macro mac3 (lib, evnt, yr, file)/minoperator;
    %local vars_kept;
	%let vars_kept = evntidx self_family 
                     medicare medicaid private other totexp;
    
   data &evnt (keep = &vars_kept 
                  %if &evnt in (ob op) %then  %do;
                   seetlkpv
				   %end;

				   %else %if &evnt in (er) %then  %do;
                           ERHEVIDX
                    %end;
                  );
	   set &lib..&file (where=(&evnt.xp&yr.x>=0));
	    %if &evnt in (rx ob hh) %then  %do;
	   	   self_family = &evnt.sf&yr.x;  /* self or family     */
           medicare =   &evnt.mr&yr.x;   /* Medicare           */
           medicaid =   &evnt.md&yr.x;   /* Medicaid           */
           pv = &evnt.pv&yr.x ;          /* private insurance  */
           va = &evnt.va&yr.x ;          /* VA/CHAMPVA        */
           tr = &evnt.tr&yr.x ;          /* TRICARE           */
		   of =  &evnt.of&yr.x ;         /* oth federal gov   */ 
           sl =  &evnt.sl&yr.x ;         /* state/local gov   */
           wc =  &evnt.wc&yr.x ;         /* workers’ comp     */
           or =  &evnt.or&yr.x ;         /* other private     */
           ou =  &evnt.ou&yr.x ;         /* other public      */
           ot =  &evnt.ot&yr.x ;         /* other insurance   */
           totexp = &evnt.xp&yr.x;       /* total expeditures */
          %end;
/* Note the additional dimension for expenses [facility vs. doctor] for IP, ER, and OP*/
       	%else %if &evnt in (ip er op) %then  %do;
		  self_family = sum(&evnt.dsf&yr.x, &evnt.fsf&yr.x); /* self or family   */
          medicare = sum(&evnt.dmr&yr.x, &evnt.fmr&yr.x);    /* Medicare         */
          medicaid = sum(&evnt.dmd&yr.x, &evnt.fmd&yr.x);    /* Medicaid         */
          pv = sum(&evnt.dpv&yr.x, &evnt.fpv&yr.x);          /* private insu     */
          va = sum(&evnt.dva&yr.x, &evnt.fva&yr.x);          /* VACHAMPVA        */
          tr = sum(&evnt.dtr&yr.x, &evnt.ftr&yr.x);          /* TRICARE          */
		  of=sum(&evnt.dof&yr.x, &evnt.fof&yr.x);            /* oth federal gov  */ 
          sl=sum(&evnt.dsl&yr.x, &evnt.fsl&yr.x);            /* state/local gov  */
          wc=sum(&evnt.dwc&yr.x, &evnt.fwc&yr.x);            /* workers’ comp    */
          or = sum(&evnt.dor&yr.x, &evnt.for&yr.x);          /* other private    */
          ou = sum(&evnt.dou&yr.x, &evnt.fou&yr.x);          /* other public     */
          ot=sum(&evnt.dot&yr.x, &evnt.fot&yr.x);            /* other insurance  */
          totexp=&evnt.xp&yr.x;                              /* total expeditures  */
        %end;
         /* new recode variables */ 
         evnt_typ="&evnt";
		 Private = sum(PV, TR);
		 Other = sum(OF, SL, OT, OR, OU, WC, VA);

     run;
	
     
	 /* Match-mege the events with condition-CLNK just for influenza cases */
	 data &evnt._;
		   merge cond_clnk_&yr(in=a) &evnt (in=b);
           by evntidx;
      if a=b;
     run;
	 proc sort data=&evnt._; by dupersid; run;
   
	* Delete temporary (selected) SAS data sets;
   proc datasets lib=work nolist ; delete &evnt; quit;
	%mend mac3;
	
	/* This macro concatenates six events for influenza cases */
%macro mac4 (yr);    
***     Combine all six event files into a single file for each year;
%let exp_vars= dupersid self_family  medicare medicaid private other totexp;
DATA all_events_F_&yr;
   LENGTH EVNTYP $3 x_evntyp $5;
   SET OB_ (KEEP=EVNTIDX &exp_vars seetlkpv)
       ER_ (KEEP=EVNTIDX &exp_vars ERHEVIDX)
       IP_ (KEEP=EVNTIDX &exp_vars)
       HH_ (KEEP=EVNTIDX &exp_vars)
       OP_ (KEEP=EVNTIDX &exp_vars seetlkpv)
       rx_ (KEEP=EVNTIDX &exp_vars) indsname=source;

   EVNTYP=scan(source,-1, '.');

   /* Create a new variable X_EVNTYP, by lumping the two categories [OB_ and OP_] */

     x_evntyp=evntyp;
	 if evntyp in ('OB_', 'OP_') then x_evntyp='OB_OP';

     /* Create 1/0 indicator variables for each category of the x_evntyp variable*/

     if x_evntyp='OB_OP' then OB_OP=1; else OB_OP=0;
     if x_evntyp='RX_' then RX=1; else RX=0;
     if x_evntyp='ER_' then ER=1; else ER=0;
     if x_evntyp='IP_' then IP=1; else IP=0;
     if x_evntyp='HH_' then HH=1; else HH=0;

   flu=1; /*by default*/
  RUN;
  proc sort data=all_events_F_&yr out=new.x_all_events_F_&yr nodupkey;  
  by  evntidx; run;

  *For data checks;
  Title1 "MEPS 20&yr - MACRO 4 (Event-level counts - all flu-care-events concatenated)";
  proc freq data=new.x_all_events_F_&yr;  
   tables flu EVNTYP*x_EVNTYP/list missing; 
   tables x_evntyp*OB_OP*RX*ER*IP*HH /list nopercent;
  run; 

   * Delete temporary (selected) SAS data sets;
 proc datasets lib=work nolist; delete all_events_F_&yr; quit;
%mend mac4;


* Merge the the concatenated event-level file with the full-year file;
%macro mac5 (fyc, yr);
 proc sort data=pufmeps.&fyc(keep=DUPERSID agelast
			                    varstr varpsu 
                                perwt&yr.f totexp&yr
                                diabdx asthdx hibpdx strkdx chddx midx ohrtdx
                                rename=(perwt&yr.f=perwtf totexp&yr=FYC_totexp))
                                out=Full_year&yr; by dupersid; 

   data new.m_events_&yr (drop= count i);
          merge new.x_all_events_F_&yr (in=a)
            Full_year&yr (in=b); by dupersid ;

        ** New variable for age goup;
          if agelast lt 18 then AGE_GRP= 1;
		  else if 18<=AGELAST<=64 then AGE_GRP=2;
		  else if AGELAST>=65 then AGE_GRP=3;

		            
		   ** YET Another construct for age goup;
           if agelast lt 18 then Y_AGE_GRP= 1;
           ELSE Y_AGE_GRP= 2;

		   *** New variable - non-positive survey weight (1,0);
			 if perwtf = 0 then non_p_weight=1 ;
             else non_p_weight=0; 

        array changelist{*} flu totexp Private Other self_family medicare medicaid ;
             do Count = 1 to dim(changelist);
                if changelist{Count} = . then changelist{Count} = 0;
             end;
      if a=b then flu=1 ; /*Flu cases */ 
      else if a ne b then flu=0; /*Non-flu cases */
  RUN;

%let kept_vars=dupersid perwtf varstr varpsu flu xch_conds age_grp age_grp Y_AGE_GRP;
proc sort data= new.m_events_&yr 
  nodupkey out=ana_fyc_&yr (keep=&kept_vars);
 by dupersid;
run;
%mend mac5;

%macro mac6 (yr);
/*Roll-up the event-level counts associated with flu care to the person-level */
	    
      * Expenses (overall, and  by source of payment) and the number of any events associated with flu care;
      proc summary data=new.m_events_&yr  nway;
       class dupersid;
       var totexp Private Other self_family medicare medicaid ;
       output out=all_p_&yr (drop=_type_ _freq_)
	   sum= AL_totexp AL_Private AL_Other AL_self_family AL_medicare AL_medicaid;
      run;

	    * Ambulatory visits expenses (overall, and  by source of payment) and the number of events associated with flu care;
	    proc summary data=new.m_events_&yr 
            (where=(x_evntyp='OB_OP')) nway;
       class dupersid;
       var totexp Private Other self_family medicare medicaid ob_op;
       output out=AM_p_&yr (drop=_type_ _freq_) 
           sum= AM_totexp AM_Private AM_Other AM_self_family AM_medicare AM_medicaid AM_events_sum;
      run;

	   * Expenses for prescribed medicines (overall, and  by source of payment) and the number of events associated with flu care;
	    proc summary data=new.m_events_&yr 
            (where=(x_evntyp='RX_')) nway;
       class dupersid;
       var totexp Private Other self_family medicare medicaid RX;
       output out=RX_p_&yr (drop=_type_ _freq_) 
	     sum= RX_totexp RX_Private RX_Other RX_self_family RX_medicare RX_medicaid RX_events_sum;
      run;

	  * Expenses for emergency room visits (overall, and  by source of payment) and the number of events associated with flu care;
	  proc summary data=new.m_events_&yr 
            (where=(x_evntyp='ER_')) nway;
       class dupersid;
       var totexp Private Other self_family medicare medicaid ER;
       output out=ER_p_&yr (drop=_type_ _freq_)
	     sum= ER_totexp ER_Private ER_Other ER_self_family ER_medicare ER_medicaid ER_events_sum;
      run;

	  * Expenses for IP (overall, and  by source of payment) and the number of events associated with flu care;
	  proc summary data=new.m_events_&yr 
            (where=(x_evntyp='IP_')) nway;
       class dupersid;
       var totexp Private Other self_family medicare medicaid ip;
       output out=IP_p_&yr (drop=_type_ _freq_)
	     sum= IP_totexp IP_Private IP_Other IP_self_family IP_medicare IP_medicaid IP_events_sum;
      run;


	    * Expenses for HH (overall, and  by source of payment) and the number of events associated with flu care;
	  proc summary data=new.m_events_&yr 
            (where=(x_evntyp='HH_')) nway;
       class dupersid;
       var totexp Private Other self_family medicare medicaid HH;
       output out=HH_p_&yr (drop=_type_ _freq_)
	     sum= HH_totexp HH_Private HH_Other HH_self_family HH_medicare HH_medicaid HH_events_sum;
      run;


	  proc summary data=new.m_events_&yr nway;
      class dupersid;
      output out=p_service_category_&yr (drop=_:)
      max(OB_OP)=max_ob_op
      max(RX)=max_rx
	  max(ER)=max_er
	  max(IP)=max_IP
	  max(HH)=max_hh;
      run;

	    * Merge the above 5 person-level files with the full-year consolidated file;
        data new.summary_person_&yr;
          merge all_p_&yr (in=al)  
                AM_p_&yr (in=am)
		        RX_p_&yr (in=rx)
		        ER_p_&yr (in=er)
                IP_p_&yr (in=ip)
		        HH_p_&yr (in=hh)
				p_service_category_&yr (in=sr)
				ana_fyc_&yr (in=fy);
           by dupersid;

           /* replace . (missing) with a zero for the following variables */
		   array exp AL: AM: RX: ER: IP: HH: max_:;
		    do over exp;
		      if exp= . then exp=0;
			end;

			length serv_combo $21 sc $50;
           
			/* Create a "service combo" variable */
              serv_combo = CatX(', ', 
               IfC( max_ob_op = 1, 'ob_op' , ' ' ),
               IfC( max_rx = 1, 'rx' , ' ' ),
               IfC( max_er = 1, 'er' , ' ' ),
               IfC( max_ip = 1, 'ip' , ' '),
	           IfC( max_hh = 1, 'hh' , ' ' ));
              if serv_combo = ' ' then serv_combo= 'None';

if index(serv_combo, "None") = 1 then sc="None";
else if index(serv_combo, "er") GE 1 then sc="ER visits w/without oth categ";
else if serv_combo= "ob_op" then sc="Ambulatory visits only";
else if serv_combo= "ob_op, rx" then sc="Ambulatory visits and Prescribed Medicines";
else if serv_combo= "rx" then sc="Prescribed Medicines only";
else sc="Residual categories";

AM_ER_sum_events = sum(AM_events_sum, ER_events_sum);

run;

* For data checks; 
Title1 "MEPS 20&yr - MACRO 6 (Person-level counts)";
proc freq data=new.summary_person_&yr; 
tables flu  AGE_GRP AGE_GRP Y_AGE_GRP max_: serv_combo sc
       AM_events_sum ER_events_sum RX_events_sum IP_events_sum HH_events_sum
       AM_ER_sum_events; 
run;
proc means data=new.summary_person_&yr; run;
%mend mac6;

%macro dm16;
  %mac1 (yr=16, cond=h190, clnk=h188IF1) 
  %mac2 (h188A, 16)  
  %mac3(work,   rx, 16, xpmed) 
  %mac3(pufmeps,ip, 16, h188d)  
  %mac3(pufmeps,er, 16, h188e) 
  %mac3(pufmeps,op, 16, h188f)  
  %mac3(pufmeps,ob, 16, h188g)  
  %mac3(pufmeps,hh, 16, h188h)  
  %mac4 (16);
  %mac5 (h192, 16)
  %mac6 (16);
  %mend dm16;
%dm16


%macro dm17;
  %mac1 (yr=17, cond=h199, clnk=h197IF1) 
  %mac2 (h197A, 17)  
  %mac3(work,   rx, 17, xpmed) 
  %mac3(pufmeps,ip, 17, h197d)  
  %mac3(pufmeps,er, 17, h197e) 
  %mac3(pufmeps,op, 17, h197f)  
  %mac3(pufmeps,ob, 17, h197g)  
  %mac3(pufmeps,hh, 17, h197h)  
  %mac4 (17);
  %mac5 (h201, 17)
  %mac6 (17);
  %mend dm17;
%dm17



PROC PRINTTO;
run;
