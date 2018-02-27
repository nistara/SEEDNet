trace(dnorm, quote(ctr$inc("dnorm")))
trace(rnorm, quote(ctr$inc("rnorm")))

ctr = countMCalls(rnorm)
replicate(10, rnorm(0))
ctr$value()

ctr = countMCalls(dnorm, rnorm)
replicate(10, dnorm(0))
replicate(7, rnorm(1))
dnorm(1)
ctr$value()

ctr = countMCalls(funs = c("dnorm", "rnorm"))
replicate(10, dnorm(0))
replicate(7, rnorm(1))
dnorm(1)
ctr$value()

source("~/projects/CallCounter/eg.R")
st = genStackCollector(num = 500)
trace(f, st$update, print = FALSE)
invisible (  k()  )
z = st$value()
z[[1]]

st = genStackCollector(callNames, num = 500)
trace(f, st$update, print = FALSE)
invisible (  k()  )
z = st$value()
z[[1]]
length(z)
