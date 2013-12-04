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


foo3 = function(p, ac) {
  lams = PatchAstoch2s(p, states, fx, n0, npatch, nstg, tf, P, pred, ac)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}



npatch = 2 # number of patches
n0 = c(1000,20,1000,20) # initial populations
fx = c(150,150) # fecundity vector
M = 50 # degree of density dependence
nstg=2 # of stages
tf=100000



# environmental transition matrix
g = .25 # probability of a good year
b= .25 # probability of a bad year
o=.25 # probability of a average year
c=.25 # probability of chytrid
P = matrix(c(g,b,o,c), 4, 4)
pred=.5
ac = seq(0,1, by=.1)
resultsSynch = ldply(ac, function(ac){
  # calculate stochastic growth rates
  r.0 = foreach(i=1:21, .combine=c) %dopar% foo3(p=p[i], ac=ac)
  return(r.0)
})

resultssynch1 = data.frame(t(rbind(p,  resultsSynch)))
write.csv(resultssynch1, file = "resultssynch1.csv")
names(resultssynch1) = c("p", ac)

resultssynch2 = melt(resultssynch1, id.vars= c("p"))
resultssynch2$rate = rep(NA, 231)
resultssynch2$rate = as.factor(rep(seq(0,1, by=.1), each=21))


# plot  growth rates
s = ggplot(data=resultssynch2[c(1:21, 43:63, 106:126, 169:189, 211:231),], 
           aes(x=p, y=value, color=rate))
s = s+
  geom_line() + labs(y="log lambda", x="proportion of juveniles \n dispersing to the high predation patch")+
  ggtitle("stochastic growth rates with \n spatial synchrony") +scale_color_discrete(name="degree of \n autocorrellation")

s 

svg(filename="autocorrellation.svg", width=6, height=4)
s
dev.off()
