
options nodate nonumber nocenter;
options formchar="|----|+|---+=|-/\<>*";
LIBNAME pufmeps  'S:\CFACT\Shared\PUF SAS files\SAS V8' access=readonly;
libname new 'U:\_Flu\SDS';
proc format;
 value tlk_fmt 1 = 'Yes'
               0,2 = 'No';
run;
data person_flu_17;
  set NEW.SUMMARY_PERSON_17 (keep= dupersid perwtf  varstr varpsu flu);
  if perwtf = 0 then non_p_weight=1; else non_p_weight=0;
run;
proc freq data=person_flu_17;
tables flu non_p_weight flu*non_p_weight/list missing ;
run;
data ob_17;
 merge person_flu_17 (in=p)
       pufmeps.h197g (in=ob keep=dupersid evntidx seetlkpv VSTCTGRY); 
       by dupersid;
	   if seetlkpv in (., -9, -8,-7,-1) then x_seetlkpv=.;
	   else x_seetlkpv=seetlkpv;

	   if VSTCTGRY in  (., -9, -8,-7,-1) then Imm_shot=.;
	   else if VSTCTGRY=6 then Imm_shot=1;
	   else Imm_shot=0;
 if ob;
title "MEPS 2017 ";
run;
proc freq data=ob_17;
tables flu seetlkpv x_seetlkpv Imm_shot
       flu*non_p_weight*seetlkpv 
       non_p_weight*seetlkpv    /list missing ;
run;
******;

data person_flu_16;
  set NEW.SUMMARY_PERSON_16 (keep= dupersid perwtf varstr varpsu flu);
  if perwtf = 0 then non_p_weight=1; else non_p_weight=0;
run;
proc freq data=person_flu_16;
tables flu non_p_weight flu*non_p_weight/list missing ;
run;
data ob_16;
  merge person_flu_16 (in=p)
        pufmeps.h188g (in=ob keep=dupersid evntidx seetlkpv VSTCTGRY); 
       by dupersid;
	  
	   if seetlkpv in (., -9, -8,-7,-1) then x_seetlkpv=.;
	   else x_seetlkpv=seetlkpv;

	   if VSTCTGRY in  (., -9, -8,-7,-1) then Imm_shot=.;
	   else if VSTCTGRY=6 then Imm_shot=1;
	   else Imm_shot=0;
 if ob;
title "MEPS 2016";
run;
proc freq data=ob_16;
tables flu seetlkpv x_seetlkpv Imm_shot
      flu*non_p_weight*seetlkpv 
       non_p_weight*seetlkpv /  list missing ;
run;
run;
title 'Combined Data 2016-17';
data new.ob_16_17;
  set ob_16 ob_17 indsname=source;
  Year=scan(source, -1, '_');
  perwtf_16_17 = perwtf/2;
run;
options nolabel;
proc means data=new.ob_16_17; run;
proc freq data=new.ob_16_17;
tables non_p_weight*x_seetlkpv
       non_p_weight*imm_shot /list missing ;
run;
title ' Combined Data 2016-17 - who received treatment for flu';
proc freq data=new.ob_16_17;
tables non_p_weight*x_seetlkpv
       non_p_weight*imm_shot /list missing ;
	   where flu=1;
run;

ODS HTML CLOSE;
ods listing;
ods graphics off;
title 'For the Definition part of the Stat Brief - % of office-based visits - called by phone, combined data from 2016-2017';
proc surveymeans data=new.ob_16_17 nobs  mean stderr sum ;
  stratum varstr;
  cluster varpsu;
  weight perwtf_16_17;
  var  x_seetlkpv;
  class x_seetlkpv;
  format x_seetlkpv tlk_fmt.;
  domain  flu('1');
run;

title 'For the Definition part of the Stat Brief - % of office-based visits - received immunization /shots, combined data from 2016-2017';
proc surveymeans data=new.ob_16_17 nobs  mean stderr sum ;
  stratum varstr;
  cluster varpsu;
  weight perwtf_16_17;
  var  imm_shot;
  class imm_shot;
  format imm_shot tlk_fmt.;
  domain  flu('1');
run;;


