# Sensitivity and elasitcity matricies of stochastic lambda
# adapted from Caswell 2001 chapter 14.4

StochSens <- function(As){
  
  # A translation of Caswell's (2001) Matlab code fragment
  tf <- dim(As)[3]
  k <- dim(As)[1]
  wvec <- rep(1/k,k)
  w <- matrix(NA, nrow=k, ncol=tf)
  
  # generate sequence of structure vectors
  
  r <- rep(0,tf)
  
  for(i in 1:tf){
    a <- As[,,i]
    wvec <- a%*%wvec
    r[i] <- sum(wvec)
    wvec <- wvec/r[i]
    w[,i] <- wvec
  }
  
  # specifiy initial reproductive value vector
  
  vvec <- rep(1/k,k)
  v <- matrix(NA, nrow=k, ncol=tf)
  
  for(i in rev(1:tf)){
    a <- As[,,i]
    vvec <- vvec%*%a
    v[,i]<- t(vvec)
  }
  
  sensmat <- matrix(0,nrow=k,ncol=k)
  elasmat <- matrix(0,nrow=k,ncol=k)
  
  for(i in 1:(tf-1)){
    # for some reason, need the as.numeric() to get the division by
    # scalar to work 
    sensmat <- sensmat+((v[,i+1]%*%t(w[,i])) /
                          as.numeric(r[i]*t(v[,i+1])%*%w[,i+1]))
    a <- As[,,i]
    elasmat <- elasmat+((v[,i+1]%*%t(w[,i])*a) /
                          as.numeric((r[i]*t(v[,i+1])%*%w[,i+1])))
  }
  
  # Devide by the number of time steps
  sensmat <- sensmat/tf
  elasmat <- elasmat/tf
  
  out <- list(sensitivities=sensmat, elasticities=elasmat)
  out
}

# Make a function out of the stochsens time period so I can replicate it
bigrun = function(tf, p1, pred1) {
  As <- replicate(tf, Getmat(p=p1, state, fx, n0, npatch, nstg, P, pred=pred1))
  StochSens(As)$elasticities
}
