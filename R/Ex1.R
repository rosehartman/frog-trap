# function to calculate extinction when predation changes
source('~/Desktop/frog-trap/R/PatchDDstoch.R')
Ex = function(p, pred2) {
  Runmat = PatchDDstoch(p, M, states, fx, n0, npatch, nstg, tf=500, P, pred=pred2)[1,]
  if (Runmat[500]==0) ex = 1 else ex = 0
  return(ex)
}


# function to calculate extinction when environmental states change
Ex1 = function(p, states1) {
  # set the seed so the curve is smoother (Sebastian told me to)
  Runmat = PatchDDstoch(p, M, states=states1, fx, n0, npatch, nstg, tf=500, P, pred)[1,]
  if (Runmat[500]==0) ex = 1 else ex = 0
  return(ex)
}