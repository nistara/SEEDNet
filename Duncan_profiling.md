
With commit   1bb5bdabe9074f3a36ef607fa59167da935ed91a
total time: 12.78 seconds

Not certain if we are doing the correct computations.
But we are matching the $name in each data.frame in both vert_list[[3]] and j_out
in disnet_sim_lapply()

This also defines cat() as 
cat = function(...){}
as that takes time.

                self.time self.pct total.time total.pct
"comp2_i_fxn"        2.46    21.06       5.66     48.46
"[[.data.frame"      1.30    11.13       3.76     32.19
"l_ji_fxn"           1.24    10.62       3.92     33.56
"[["                 1.14     9.76       4.90     41.95
"%in%"               0.74     6.34       1.62     13.87
"<Anonymous>"        0.72     6.16       0.88      7.53
"length"             0.54     4.62       0.54      4.62
"sys.call"           0.50     4.28       0.50      4.28
"lapply"             0.44     3.77      10.16     86.99
"$"                  0.36     3.08       1.96     16.78

                self.time self.pct total.time total.pct
"comp2_i_fxn"        2.38    18.62       5.70     44.60
"l_ji_fxn"           1.54    12.05       4.26     33.33
"[[.data.frame"      1.42    11.11       4.14     32.39
"[["                 1.28    10.02       5.42     42.41
"<Anonymous>"        0.98     7.67       1.42     11.11
"%in%"               0.90     7.04       1.60     12.52
"lapply"             0.70     5.48      10.72     83.88
"sys.call"           0.50     3.91       0.50      3.91
"$"                  0.40     3.13       1.88     14.71
".subset2"           0.28     2.19       0.28      2.19


The number of calls are
[[.data.frame    disnet_foi   comp2_i_fxn      l_ji_fxn 
      1194665          1765        289460        289460 
