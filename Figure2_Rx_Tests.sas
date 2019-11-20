*Figure2_Rx_Tests.sas;
options nosource nodate nonumber nonotes nocenter;
LIBNAME new "U:\_Flu\SDS";
proc format;
 value y_age_fmt 
  . = 'All Ages'
  1 = '<=17'
  2 = '18+'  ;
run;
ods listing;
ods graphics off;
title 'Figure 2 - Statistical Tests for Rx';
ods exclude summary statistics;
proc surveymeans data=new.person16_17 nobs  mean stderr;
  stratum varstr;
  cluster varpsu;
  weight perwtf_16_17;
  var  max_rx;
domain flu('1')
       flu('1')*y_age_grp /Adjust=Bon;
format y_age_grp y_age_fmt.;
run;
