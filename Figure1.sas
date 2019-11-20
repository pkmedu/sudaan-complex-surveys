*Figure1.sas;
options nosource nodate nonumber nonotes nocenter;
LIBNAME new "U:\_Flu\SDS";
proc format;
 value y_age_fmt 
  . = 'All Ages'
  1 = '<=17'
  2 = '18+' ;
run;
ods graphics off;
ods exclude summary;
ods listing;
title 'Figure 1';
proc surveymeans data=new.person16_17 nobs  sumwgt mean stderr sum ;
  stratum varstr;
  cluster varpsu;
  weight perwtf_16_17;
  var  flu;
domain y_age_grp;
format y_age_grp y_age_fmt.;
run;
