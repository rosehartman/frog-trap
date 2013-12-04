# Stochastic growth rate for two patches
# assuming spatial synchrony of the patches
PatchAstoch2s <- function(p, states, fx, n0, npatch, nstg, tf, P, pred, ac) {
  # start all patches off with a good year
  L= numeric(tf)
  state = c(1,1)
  # k= number of possible states
  k=dim(P)[1]
  
  
  Nt = n0 # starting population 
  Lsd = c(0,0)
  for(i in 1:(tf-1)) {
    # determine the environmental state for each patch
    state[1] = sample(1:k,size=1, prob = P[,state[1]])
    P2= c(ac, rep((1-ac)/(k-1), (k-1)))
    st = sample(1:k,size=1, prob = P2)
    if (st==1) state[2]=state[1] else state[2]=sample(1:k,size=1, prob = P[,state[2]])
    
    # pull out the parameters so you can put them in a matrix
    st = c(states[state[1],], states[state[2],])
    J = st[c(1, 3)]
    s1= st[c(2, 4)]
    
    A <- matrix(c(0, fx[1], 0, 0, 
                  J[1]*p*pred,s1[1],J[2]*p,0, 
                  0, 0, 0,fx[2],  
                  J[1]*(1-p)*pred,0, J[2]*(1-p),s1[2]), nrow=4, ncol=4, byrow=TRUE) 
    
    L[i] = (lambda(A))
    
    Nt= A %*% Nt
    # run model through time 
    # if (sum(Nt)<0.001) Nt = rep(0, (nstg*npatch))
  }
  #  NAds = Nt[3,]+ Nt[6,]
  # pop = cbind(NAds, Nt[3,], Nt[6,], L)
  return(L)
  
  
}