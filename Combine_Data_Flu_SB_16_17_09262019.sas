
OPTIONS nocenter obs=max ps=58 ls=132 nodate nonumber varlenchk=nowarn
        FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
LIBNAME new "U:\_Flu\SDS";
FILENAME MYLOG "U:\_Flu\Output\Combine_data_16_17_log_09262019.TXT";
FILENAME MYPRINT "U:\_Flu\Output\Combine_data_16_17_output_09262019.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

proc format;
 value age_fmt 
  . = 'Overall'
  1 = '<=17'
  2 = '18-64'
  3 = '65 and above';

   value cond_fmt 
  . = ' All'
  1 = '1+'
  2 = 'None';
 run;
 /* Concatenate 2 years of person-level data */
data new.person16_17;
 set NEW.summary_person_16 
     NEW.summary_person_17 indsname=source;

  Year=input(cats(20,scan(source, -1, '_')), best.);;

  AM_ER_RX_exp = sum(AM_totexp, ER_totexp, RX_totexp);
 
  if year in (2016, 2017) then  perwtf_16_17=perwtf/2;

*Subpopulation: Persons with flu DID NOT have an IP event;

IF max_ip=0 then no_ip=1; else no_ip=0;


/*Subpopulation: 
  Persons with flu DID NOT have an IP event but had an OB, OP, ER, RX or HH event
*/
IF max_ip=0 & sum(max_ob_op, max_er, max_rx, max_hh) ge 1
  then no_ip_yes_Am_ER_RX_HH=1;
else no_ip_yes_Am_ER_RX_HH=0;

/*Subpopulation: 
Persons with flu DID NOT have an HH event but had an OB, OP, ER, RX or IP event
*/
IF max_HH=0 & sum(max_ob_op, max_er, max_rx, max_ip) ge 1 
  then no_hh_yes_Am_ER_RX_ip=1;
else no_hh_yes_Am_ER_RX_ip=0;


/*Subpopulation:
Persons with flu DID NOT have an IP/HH event but had an OB, OP, ER or RX event
*/
IF (max_ip =0 | max_HH=0) & sum(max_ob_op, max_er, max_rx) ge 1  then no_ip_hh_yes_Am_ER_RX=1;
else no_ip_hh_yes_Am_ER_RX=0;


array vars [*]  AL_totexp AL_Private AL_Other AL_self_family AL_medicare AL_medicaid
                AM_totexp AM_Private AM_Other AM_self_family AM_medicare AM_medicaid
				RX_totexp RX_Private RX_Other RX_self_family RX_medicare RX_medicaid
				ER_totexp ER_Private ER_Other ER_self_family ER_medicare ER_medicaid
                IP_totexp IP_Private IP_Other IP_self_family IP_medicare IP_medicaid
				HH_totexp AM_ER_RX_exp ;

array x_vars [*]  g_AL_totexp g_AL_Private g_AL_Other g_AL_self_family g_AL_medicare g_AL_medicaid
                  g_AM_totexp g_AM_Private g_AM_Other g_AM_self_family g_AM_medicare g_AM_medicaid
				  g_RX_totexp g_RX_Private g_RX_Other g_RX_self_family g_RX_medicare g_RX_medicaid
				  g_ER_totexp g_ER_Private g_ER_Other g_ER_self_family g_ER_medicare g_ER_medicaid
                  g_IP_totexp g_IP_Private g_IP_Other g_IP_self_family g_IP_medicare g_IP_medicaid
				  g_HH_totexp g_AM_ER_RX_exp ;

	         do i = 1 to dim(vars);
			    if year=2017 then x_vars[i]=vars[i];
				else if year=2016 then   x_vars[i]=vars[i]*(106.2/104.9);
              end;

proc means data=new.person16_17 N NMISS min max mean; run;

proc printto;
run;




