

#  growth rate for two patches, two stages
library(popbio)
library(plyr)
Patchlam <- function(p, s1=s1, J=J, fx=fx,  pred=pred) {
  ## p is the proportion of juveniles migrating to the high predation patch.
  
    A <- matrix(c(0, fx[1], 0, 0, 
                  J[1]*p*pred,s1[1],J[2]*p,0, 
                  0, 0, 0,fx[2],  
                  J[1]*(1-p)*pred,0, J[2]*(1-p),s1[2]), nrow=4, ncol=4, byrow=TRUE)
    
return(lambda(A))    

}

npatch = 2 # number of patches
n0 = c(1000,20,1000,20) # initial populations
fx = c(150,150) # fecundity vector
J = c(.008,.008) # juvenile survival
s1 = c(.5,.5) # adult survival
nstg=2 # of stages

# p is proportion of juves moving to high predation patch
p =  seq(0,1,by=0.05)
# pred = proportion of juveniles surviving predation
pred= .1
tf=1000 # number of time steps (should be >100,000 for stochatic model)
test = Patchlam(p=.1, s1=s1, J=J, fx=fx,pred=pred)
test2= sapply(p, Patchlam, s1=s1, J=J, fx=fx, pred=pred, simplify=T)
