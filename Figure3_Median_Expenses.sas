*Figure3_Median_Expenses.sas;
options nosource nodate nonumber nonotes nocenter;
LIBNAME new "U:\_Flu\SDS";
ods listing;
ods graphics off;
ods select domain domainquantiles;
title 'Figure 3A - Median expenses per person for all care services combined';
proc surveymeans data=new.person16_17 Nobs median;
stratum varstr;
cluster varpsu;
weight perwtf_16_17;
var  g_AL_totexp;
domain flu('1');
run;

options nosource nodate nonumber nonotes nocenter;
LIBNAME new "U:\_Flu\SDS";

ods graphics off;
ods select domain domainquantiles;
title 'Figure 3B (Median expenses per person for ambulatory Care with an amulatory care visit)';
proc surveymeans data=new.person16_17 Nobs median;
stratum varstr;
cluster varpsu;
weight perwtf_16_17;
var  g_AM_totexp;
domain flu('1')*max_ob_op('1');
run;

options nosource nodate nonumber nonotes nocenter;
LIBNAME new "U:\_Flu\SDS";
ods listing;
ods graphics off;
ods select domain domainquantiles;
title 'Figure 3C (Median expenses person for Prescribed Medicines with a prescription fill)';
proc surveymeans data=new.person16_17 Nobs median;
stratum varstr;
cluster varpsu;
weight perwtf_16_17;
var  g_RX_totexp;
domain flu('1')*max_rx('1') ;
run;

options nosource nodate nonumber nonotes nocenter;
LIBNAME new "U:\_Flu\SDS";

ods listing;
ods graphics off;
ods select domain domainquantiles;
title 'Figure 3D (Median Expenses per person for ER Visits with an ER visit)';
proc surveymeans data=new.person16_17 Nobs median;
stratum varstr;
cluster varpsu;
weight perwtf_16_17;
var  g_ER_totexp;
domain flu('1')*max_ER('1');
run;
