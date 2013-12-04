# It's opposite day! Therefore, I am going to see what happens when 
# predation only effects the adults instead of teh juveniles.

Patchads <- function(p, s1=s1, J=J, fx=fx,  pred=pred) {
  ## p is the proportion of juveniles migrating to the high predation patch.
  
  A <- matrix(c(0, fx[1], 0, 0, 
                J[1]*p,s1[1]*pred,J[2]*p,0, 
                0, 0, 0,fx[2],  
                J[1]*(1-p),0, J[2]*(1-p),s1[2]), nrow=4, ncol=4, byrow=TRUE)
  
  return(lambda(A))    
  
}

PatchAstochAds = function(p, states, fx, n0, npatch, nstg, tf, P, pred) {
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
                  J[1]*p,s1[1]*pred,J[2]*p,0, 
                  0, 0, 0,fx[2],  
                  J[1]*(1-p),0, J[2]*(1-p),s1[2]), nrow=4, ncol=4, byrow=TRUE) 
    
    L[i] = (lambda(A))
    
    Nt= A %*% Nt
    # run model through time 
    # if (sum(Nt)<0.001) Nt = rep(0, (nstg*npatch))
  }
  #  NAds = Nt[3,]+ Nt[6,]
  # pop = cbind(NAds, Nt[3,], Nt[6,], L)
  return(L)
  
  
}
fooAds = function(p, pred, states1) {
  lams = PatchAstochAds(p, states=states1, fx, n0, npatch, nstg, tf, P, pred)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}

# apply stochastic growth function over all predation levels
resultsStochAds = ldply(pred, function(pred2){
  # calculate stochastic growth rates
  r.0 = foreach(i=1:21, .combine=c) %dopar% fooAds(p=p[i], pred=pred2)
  return(r.0)
})

# apply deterministic growth function over all predation levels
resultsdetAds = ldply(pred, function(pred){
  # deterministic growth rate
  r2.0 = sapply(p, Patchads, s1=c(ok[2],ok[2]), J=c(ok[1],ok[1]), fx=fx,  pred=pred, simplify=T)
  r2.0 = log(r2.0) # take the log to make it comparable to stochastic rates
  return(r2.0) 
})
allads1 = data.frame(t(rbind(resultsdetAds, resultsStochAds, p)))
names(allads1) = c(pred,predSt,"p")
write.csv(allads1, file = "adult predation.csv")

library(reshape2)
allads = melt(allads1, id.vars="p", variable.name= "predation", value.name="lambda")
allads$stoch = rep(NA, 252)
allads$stoch[c(1:126)]="n"
allads$stoch[c(127:252)] = "y"
allads$rate = c(NA, 252)
allads$rate[c(1:21, 127:147)] = 6
allads$rate[c(22:42,  148:168)] = 5
allads$rate[c(43:63 , 169:189 )] = 4
allads$rate[c( 64:84 , 190:210)] = 3
allads$rate[c( 85:105 ,211:231 )] = 2
allads$rate[c( 106:126 ,232:252 )] = 1
allads$rate = ordered(allads$rate, levels=c(1:6) ,
                           labels = rev(c("100%", "80%", "60%", "40%", "20%", "0%")))

# plot stochastic  growth and deterministic
ad = ggplot(data=allads, 
            aes(x=p, y=lambda, color=rate, linetype=stoch))
ad = ad+geom_line() + labs(y="population growth rate log(lambda)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_linetype_manual(name = "model", values=c(2, 1), labels = c("deterministic", "stochastic")) +
  scale_y_continuous(limits=c(-.5, .5)) 
ad 


Getmat2 <- function( p, state, fx, n0, npatch, nstg, P, pred) {
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
                J[1]*p,s1[1]*pred,J[2]*p,0, 
                0, 0, 0,fx[2],  
                J[1]*(1-p),0, J[2]*(1-p),s1[2]), nrow=4, ncol=4, byrow=TRUE) 
  return(A)
}
bigrun2 = function(tf, p1, pred1) {
  As <- replicate(tf, Getmat2(p=p1, state, fx, n0, npatch, nstg, P, pred=pred1))
  StochSens(As)$elasticities
}

# Make a function to calculate average sensitivites for a bunch to time runs
# over a bunch of attractiveness values
elsplot2 = function(pred) {
  i=1:21
  # Apparently this gets too big for R to handle if you run it for 100,000 time steps, but that doesn't make sense...
  run = laply(i, function(x){
    ru = replicate(100,bigrun2(tf=1000, p1=p[x], pred1=pred))
    aaply(ru, 1:2, function(thingy) {sum(thingy)/100})
  },
              .parallel=T)
  
  # Data frame with the elasticity of each non-zero matrix entry
  elsdf = data.frame(p=p, f1=run[, 1,2], j11=run[, 2,1], j21=run[, 2,3], a1=run[, 2,2], 
                     f2=run[, 3,4],  j12=run[, 4,1], j22=run[, 4,3], a2=run[, 4,4])
  library(reshape2)
  elsedf2 = melt(elsdf, id.vars="p", variable.name="stage",value.name="elas")
  elsedf2$patch = rep(NA, 168)
  elsedf2$stage = rep(NA, 168)
  elsedf2$patch[1:84] = "1"
  elsedf2$patch[85:168] = "2"
  elsedf2$stage[1:21]="f"
  elsedf2$stage[22:42]="j1"
  elsedf2$stage[43:63]="j2"
  elsedf2$stage[64:84]="a"
  elsedf2$stage[85:105]="f"
  elsedf2$stage[106:126]="j1"
  elsedf2$stage[127:147]="j2"
  elsedf2$stage[148:168]="a"
  
  # plot the change in elasticities with different ammounts of migration
  el = qplot(data=elsedf2, x=p, y=elas, geom="line", color=stage, linetype = patch,
             xlab="proportion of juveniles moving to \nhigh predation patch (patch1)", ylab="elasticity of log lambdas \n to changes in life stage",
             main=paste("predation = ", pred))
  el
}

predAds = elsplot2(pred=.5)

Survives2 = function(j, a) {
  states1 <- cbind(states[,1]*j, states[,2]*a)
  r =  ldply(p, fooAds, states1=states1, pred=.5)
  return(r)
}

survAds = foreach (i=1:20, combine=cbind) %dopar% {
  Survives2(j=surv[i,1], a=surv[i,2])
}

survads2 = as.data.frame(survAds)
names(survads2) = c(paste("j", seq(.2,2, by=.2)), paste("a", seq(.2,2, by=.2)))
survmat2$p = p

maxlamads = apply(survads2[,1:20], 2, max)
minlamads = as.numeric(survads2[1,1:20])
maxsads = survads2[1:20,]
for (i in 1:20) maxsads[i,] = survads2[which(survads2[,i]==maxlamads[i]),]

summaryads = data.frame(levels = rep(seq(.2, 2, by=.2), 2), stage = c(rep("j", 10),rep("a", 10)), maxsads=maxlamads, p = maxs$p, ldiff=(maxlamads-minlamads))
write.csv(summaryads, file = "summary survivalsads.csv")
lamlocalads = qplot(levels, p, data= summaryads, geom="line", color=stage, xlab= "increase in survival", ylab="migration proportion at \n peak of migration/lambda curve", main = "Proporiton of juves \n migrating that maximizes growth")
lamlocalads


# Graph changes in height of the peak of the lambda curve
lampeakads = qplot(levels, maxsads, data= summaryads, geom="line", color=stage, xlab= "increase in survival", ylab="lambda at \n peak of migration/lambda curve", main = "Maximum growth rate for each  life \n stage at each survival level")
lampeakads
# graph changes in difference between max and min or lambda curve

lamdiffads = qplot(levels, ldiff, data= summaryads, geom="line", color=stage, xlab= "increase in survival", ylab="difference in lambda", main = "Difference between lambda at peak of curve and 0 for each  life \n stage at each survival level")

lamdiffads
