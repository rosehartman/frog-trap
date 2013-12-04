# Apparently I should be doing the stochastic growth rate
# with 1 rep of 100,000 time steps instead of 100 reps of 1000 time steps

library(popbio)
library(plyr)
library(foreach)
library(doParallel)
registerDoParallel(cores=2)
# function to calculate extinction
Ex = function(p, pred2) {
  Runmat = PatchDDstoch(p, M, states, fx, n0, npatch, nstg, tf=500, P, pred=pred2)[1,]
  if (Runmat[500]==0) ex = 1 else ex = 0
  return(ex)
}



# function to calculate stochastic lambdas
foo2 = function(p, pred) {
  lams = PatchAstoch2(p, states, fx, n0, npatch, nstg, tf, P, pred)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}


npatch = 2 # number of patches
n0 = c(1000,20,1000,20) # initial populations
fx = c(150,150) # fecundity vector
M = 50 # degree of density dependence
nstg=2 # of stages
tf=100000


# juvenile, and adult survivorships in different types of years
# a good year
good = c(.02,.7) 
# a bad year
bad = c(.002,.2)
# an average year
ok = c(.009,.6)
# a year when chytrid fungus wipes out the juvenile age class
chytrid = c(0.0001,0.5)
# bind the possible states together into a matrix
states = rbind(good, bad, ok, chytrid)

# environmental transition matrix
g = .25 # probability of a good year
b= .25 # probability of a bad year
o=.25 # probability of a average year
c=.25 # probability of chytrid
P = matrix(c(g,b,o,c), 4, 4)
p =  seq(0,1,by=0.05)
pred = seq (0,1, by=.2)

# apply stochastic growth function over all predation levels
resultsStoch = ldply(pred, function(pred2){
# calculate stochastic growth rates
r.0 = foreach(i=1:21, .combine=c) %dopar% foo2(p=p[i], pred=pred2)
return(r.0)
})

# apply deterministic growth function over all predation levels
resultsdet = ldply(pred, function(pred){
# deterministic growth rate
r2.0 = sapply(p, Patchlam, s1=c(ok[2],ok[2]), J=c(ok[1],ok[1]), fx=fx,  pred=pred, simplify=T)
r2.0 = log(r2.0) # take the log to make it comparable to stochastic rates
return(r2.0) 
})

# probability of extinction in 500 years
tf=500
resultsEx = ldply(pred, function(pred2){
ex.0 = replicate(500, (foreach(i=1:21, .combine=c) %dopar% Ex(p[i], pred2)), simplify=T)
ex2.0 = rowSums(ex.0)/ncol(ex.0)
return(ex2.0)
})

resultsEx2 = ldply(pred, function(pred2){
  ex.0 = replicate(100, (foreach(i=1:21, .combine=c) %dopar% Ex(p[i], pred2)), simplify=T)
  ex2.0 = rowSums(ex.0)/ncol(ex.0)
  return(ex2.0)
})
                   
predSt = c("0s", ".2s", ".4s", ".6s", ".8s", "1s")
allresults = data.frame(t(rbind(resultsdet, resultsStoch, p)))
names(allresults) = c(pred,predSt,"p")
write.csv(allresults, file = "two stage results.csv")

# calculate maximum predation rate
maxpred = apply(allresults[,7:12], 2,  max)
# minimum predation rate
minpred = as.numeric(allresults[1,7:12])
maxp = c(1:6)
for (i in 7:12) maxp[i-6] = allresults[which(allresults[,i]==maxpred[(i-6)]),13]

summarypred = data.frame(levels = pred, maxpred = maxpred, maxp = maxp, diffpred=(maxpred-minpred))
plot(summarypred$levels, summarypred$maxpred, type="l")

# get the dataframe into a format ggplot will like
library(reshape2)
allresults2 = melt(allresults, id.vars="p", variable.name= "predation", value.name="lambda")
allresults2$stoch = rep(NA, 252)
allresults2$stoch[c(1:126)]="n"
allresults2$stoch[c(127:252)] = "y"
allresults2$rate = c(NA, 252)
allresults2$rate[c(1:21, 127:147)] = 6
allresults2$rate[c(22:42,  148:168)] = 5
allresults2$rate[c(43:63 , 169:189 )] = 4
allresults2$rate[c( 64:84 , 190:210)] = 3
allresults2$rate[c( 85:105 ,211:231 )] = 2
allresults2$rate[c( 106:126 ,232:252 )] = 1
allresults2$rate = ordered(allresults2$rate, levels=c(1:6) ,
                           labels = rev(c("100%", "80%", "60%", "40%", "20%", "0%")))

# plot stochastic  growth and deterministic
e2 = ggplot(data=allresults2, 
           aes(x=p, y=lambda, color=rate, linetype=stoch))
e2 = e2+geom_line() + labs(y="population growth rate log(lambda)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_linetype_manual(name = "model", values=c(2, 1), labels = c("deterministic", "stochastic")) +
  scale_y_continuous(limits=c(-.5, .5)) 
e2 

names(resultsEx) = p
resultsEx2 = cbind(pred, resultsEx)
resultsEx2 = melt(resultsEx2 ,id.vars="pred", variable_name="p")
# Plot extinction probabilities
explot.1 = ggplot(data=resultsEx2, 
                aes(x=as.numeric(p), y=value, color=as.factor(pred)))
explot.1 = explot.1+ 
  geom_line() + labs(y="probability", x="proportion of juveniles \n dispersing to the high predation patch")+
  ggtitle("probability of extinction in 500 years") + scale_color_discrete(name="predation", labels=rev(c("0%", "20%", "40%", "60%", "80%", "100%")))+
  scale_y_continuous(limits=c(0, 1))
explot.1