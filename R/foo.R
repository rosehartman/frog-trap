source('~/Desktop/frog-trap/R/PatchAstoch2.R')
source('~/Desktop/frog-trap/R/PatchAstoch2s.R')
# function to calculate stochastic lambdas with different survivals
foo21 = function(p, states1, fx=c(150,150)) {
  lams = PatchAstoch2(p, states1, fx, n0, npatch, nstg, tf=100000, P, pred=.5)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}

# function to calculate stochastic lambdas with different predation rates
foo2 = function(p, pred) {
  lams = PatchAstoch2(p, states, fx, n0, npatch, nstg, tf, P, pred)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
}

# Stochastic lambdas with some degree of autocorrelation
foo3 = function(p, ac) {
  lams = PatchAstoch2s(p, states, fx, n0, npatch, nstg, tf, P, pred, ac)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}
