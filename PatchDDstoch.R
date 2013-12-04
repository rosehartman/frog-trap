PatchDDstoch = function(p, M, states, fx, n0, npatch, nstg, tf, P, pred) {
  # start all patches off with a good year
  state = c(1,1)
  # k= number of possible states
  k=dim(P)[1]
  Nt = matrix(NA, nrow=nstg*npatch, ncol=tf) # initialize our matrix for following each stage through time
  Nt[,1] = n0 # starting population 
  for(i in 1:(tf-1)) {
    # determine the environmental state for each patch
    state[1] = sample(1:k,size=1, prob = P[,state[1]])
    state[2] = sample(1:k,size=1, prob = P[,state[2]])
    
    # pull out the parameters so you can put them in a matrix
    st = c(states[state[1],], states[state[2],])
    J= st[c(1, 3)]
    s1= st[c(2, 4)]
    
    # penalize the juvenile survival based on number of juveniles
    # Note! This way DD occurs before predation, I may want to change this
      J[1] = J[1] /(1+Nt[1,i]/M)
    J[2] = J[2]/(1+Nt[4,i]/M)
    
    
    A <- matrix(c(0, fx[1], 0, 0, 
                  J[1]*p*pred,s1[1],J[2]*p,0, 
                  0, 0, 0,fx[2],  
                  J[1]*(1-p)*pred,0, J[2]*(1-p),s1[2]), nrow=4, ncol=4, byrow=TRUE)
    
    Nt[,i+1]= A %*% Nt[,i]
    # run model through time 
    if (sum(Nt[,i])<0.001) Nt[,(i+1)] = rep(0, (nstg*npatch))
  }

  return(Nt)
  
  
}
