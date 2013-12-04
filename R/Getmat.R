# function to caluculate A for each time step

Getmat <- function( p, state, fx, n0, npatch, nstg, P, pred) {
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
                J[1]*p*pred,s1[1],J[2]*p,0, 
                0, 0, 0,fx[2],  
                J[1]*(1-p)*pred,0, J[2]*(1-p),s1[2]), nrow=4, ncol=4, byrow=TRUE) 
  return(A)
}

