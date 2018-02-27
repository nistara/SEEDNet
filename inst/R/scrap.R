funAgg = function(x) {
# initialize res 
 res = NULL
 n = nrow(x)

 for (i in 1:n) {
    if (!any(is.na(x[i,]))) res = rbind(res, x[i,])
 }
 res
}

funLoop = function(x) {
# Initialize res with x
 res = x
 n = nrow(x)
 k = 1

 for (i in 1:n) {
    if (!any(is.na(x[i,]))) {
       res[k, ] = x[i,]
       k = k + 1
    }
 }
 res[1:(k-1), ]
}

funApply = function(x) {
 drop = apply(is.na(x), 1, any)
 x[!drop, ]
}

funOmit = function(x) {
# The or operation is very fast, it is replacing the any function
# Also note that it doesn't require having another data frame as big as x

 drop = F
 n = ncol(x)
 for (i in 1:n)
   drop = drop | is.na(x[, i])
 x[!drop, ]
}

#Make up large test case
 xx = matrix(rnorm(2000000),100000,20)
 xx[xx>2] = NA
 x = as.data.frame(xx)

# Call the R code profiler and give it an output file to hold results

  Rprof(tmp <- tempfile())
  y = funLoop(xx)
  Rprof(NULL)

  Rprof("exampleApply.out")
  y = funApply(xx)
  Rprof(NULL)

  Rprof("exampleOmit.out")
  y = funOmit(xx)
  Rprof(NULL)
