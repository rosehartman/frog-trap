# functions for the "opposite day2" scenario where adults disperse instead
# of juveniles

# calculate deterministic growth rate
Patchopp <- function(p, s1=s1, J=J, fx=fx,  pred=pred) {
  ## p is the proportion of adults migrating to the high predation patch.
  
  A <- matrix(c(0, fx[1], 0, 0, 
                J[1]*pred,s1[1]*p,0,s1[2]*p, 
                0, 0, 0,fx[2],  
                0,s1[1]*(1-p), J[2],s1[2]*(1-p)), nrow=4, ncol=4, byrow=TRUE)
  
  return(lambda(A))    
  
}
# calculate stochastic growth rate
PatchAstochopp = function(p, states, fx, n0, npatch, nstg, tf, P, pred) {
  # start all patches off with a good year
  L= numeric(tf)
  state = c(1,1)
  # k= number of possible states
  k=dim(P)[1]
  
  Nt = n0 # starting population 
  
  for(i in 1:(tf-1)) {
    # determine the environmental state for each patch
    state[1] = sample(1:k,size=1, prob = P[,state[1]])
    state[2] = sample(1:k,size=1, prob = P[,state[2]])
    
    # pull out the parameters so you can put them in a matrix
    st = c(states[state[1],], states[state[2],])
    J = st[c(1, 3)]
    s1= st[c(2, 4)]
    
    A <- matrix(c(0, fx[1], 0, 0, 
                  J[1]*pred,s1[1]*p,0,s1[2]*p, 
                  0, 0, 0,fx[2],  
                  0,s1[1]*(1-p), J[2],s1[2]*(1-p)), nrow=4, ncol=4, byrow=TRUE)
    
    L[i] = (lambda(A))
    
    Nt= A %*% Nt
    # run model through time 
    # if (sum(Nt)<0.001) Nt = rep(0, (nstg*npatch))
  }
  #  NAds = Nt[3,]+ Nt[6,]
  # pop = cbind(NAds, Nt[3,], Nt[6,], L)
  return(L)
  
  
}
fooopp = function(p, pred, states1, fx=c(150,150)) {
  lams = PatchAstochopp(p, states=states1, fx, n0, npatch, nstg, tf, P, pred)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}
# Return the metapopulation projection matrix instead of lambda
Getmatopp <- function( p, state, fx, n0, npatch, nstg, P, pred) {
  # determine the environmental state for each patch
  k=dim(P)[1]
  Lsd = c(0,0)
  
  state[1] = sample(1:k,size=1, prob = P[,state[1]])
  state[2] = sample(1:k,size=1, prob = P[,state[2]])
  
  # pull out the parameters so you can put them in a matrix
  st = c(states[state[1],], states[state[2],])
  J= st[c(1, 3)]
  s1= st[c(2, 4)]
  
  A <- matrix(c(0, fx[1], 0, 0, 
                J[1]*pred,s1[1]*p,0,s1[2]*p, 
                0, 0, 0,fx[2],  
                0,s1[1]*(1-p), J[2],s1[2]*(1-p)), nrow=4, ncol=4, byrow=TRUE)
  return(A)
}
bigrunopp = function(tf, p1, pred1) {
  As <- replicate(tf, Getmatopp(p=p1, state, fx, n0, npatch, nstg, P, pred=pred1))
  StochSens(As)$elasticities
}
