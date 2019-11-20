*Figure3_related_text.sas;
options nosource nodate nonumber notes nocenter;
LIBNAME new "U:\_Flu\SDS";
ods listing;
ods graphics off;
ods exclude summary statistics;
title 'Text related to Figure 3 (Mean expenses for individuals with no inpatient stays)';
proc surveymeans data=new.person16_17 nobs  sumwgt mean stderr sum ;
  stratum varstr;
  cluster varpsu;
  weight perwtf_16_17;
  var  g_AL_totexp;
domain flu('1')*no_ip('1');
run;

options nosource nodate nonumber notes nocenter;
LIBNAME new "U:\_Flu\SDS";
ods listing;
ods graphics off;
ods select domain domainquantiles;
title 'Text related to Figure 3 (Median expenses for individuals with no inpatient stays)';
proc surveymeans data=new.person16_17 Nobs median;
stratum varstr;
cluster varpsu;
weight perwtf_16_17;
var  g_AL_totexp;
domain flu('1')*no_ip('1');
run;

