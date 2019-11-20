*Figure4_Mean_OOP_Expenses.sas;
options nosource nodate nonumber nocenter;
LIBNAME new "U:\_Flu\SDS";
ods listing;
ods graphics off;
ods exclude summary statistics;
title 'Figure 4A (Mean out-of-pocket total expenses)';
proc surveymeans data=new.person16_17 nobs  mean stderr sum ;
  stratum varstr;
  cluster varpsu;
  weight perwtf_16_17;
  var  g_AL_self_family ;
domain flu('1');
run;

options nosource nodate nonumber nocenter;
LIBNAME new "U:\_Flu\SDS";
ods listing;
ods graphics off;
ods exclude summary statistics;
title 'Figure 4B (Mean out-of-pocket expenses for ambulatory care with an ambulatory visit)';
proc surveymeans data=new.person16_17 nobs  mean stderr sum ;
  stratum varstr;
  cluster varpsu;
  weight perwtf_16_17;
  var  g_AM_self_family;
domain flu('1')*max_OB_OP('1');
run;

options nosource nodate nonumber nocenter;
LIBNAME new "U:\_Flu\SDS";
proc format;
 value y_age_fmt 
  . = 'All Ages'
  1 = '<=17'
  2 = '18+'  ;
run;
ods listing;
ods graphics off;
ods exclude summary statistics;
title 'Figure 4C (Mean out-of-pocket expenses for prescribed medicines with an prescription fill)';
proc surveymeans data=new.person15_16 nobs  mean stderr sum ;
  stratum varstr;
  cluster varpsu;
  weight perwtf;
  var  g_RX_self_family;
domain flu('1')*max_RX('1');
format y_age_grp y_age_fmt.;
run;

options nosource nodate nonumber nocenter;
LIBNAME new "U:\_Flu\SDS";
ods listing;
ods graphics off;
ods exclude summary statistics;
title 'Figure 4D (Mean out-of-pocket expenses for emergency care with an ER visit)';
proc surveymeans data=new.person15_16 nobs  sumwgt mean stderr sum ;
  stratum varstr;
  cluster varpsu;
  weight perwtf;
  var  g_ER_self_family;
domain flu('1')*max_ER('1');
run;
