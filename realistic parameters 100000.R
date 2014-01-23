# Apparently I should be doing the stochastic growth rate
# with 1 rep of 100,000 time steps instead of 100 reps of 1000 time steps

library(popbio)
library(plyr)
library(foreach)
library(doParallel)
registerDoParallel(cores=2)
#load the functions I have defined to run this puppy
source('~/Desktop/frog-trap/R/foo.R')
source('~/Desktop/frog-trap/R/lambda two stage.R')
source('~/Desktop/frog-trap/R/Ex1.R')

# define all the variables
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
resultsStoch1 = ldply(pred, function(pred2){
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

# Organize the output and save it                   
predSt = c("0s", ".2s", ".4s", ".6s", ".8s", "1s")
allresults = data.frame(t(rbind(resultsdet, resultsStoch1, p)))
names(allresults) = c(pred,predSt,"p")
write.csv(allresults, file = "two stage results.csv")

allpred = data.frame(t(rbind(resultsStoch1, p)))
names(allpred) = c(pred,"p")
write.csv(allpred, file = "allpred.csv")


# calculate maximum predation rate
maxpred1 = apply(allpred[,1:21], 2,  max)
# minimum predation rate
minpred1 = as.numeric(allpred[1,1:21])
maxp1 = c(1:21)
for (i in 1:21) maxp1[i] = allpred[which(allpred[,i]==maxpred1[i]),22]

# organize it and plot it
summarypred = data.frame(levels = (1-pred), maxpred = maxpred1, maxp = maxp1, diffpred=(maxpred1-minpred1))
plot(summarypred$levels, summarypred$maxpred, type="l")
peak = ggplot(summarypred, aes(x=levels, y=maxp)) +geom_line()
peak + labs(x="predation rate", y="proportion of juveniles dispersing \n that maximizes log(lambdas)")

# get the dataframe into a format ggplot will like
library(reshape2)
allpred2 = melt(allpred, id.vars="p", variable.name= "predation", value.name="lambda")
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

# calculate maximum growth rate
max1 = apply(allresults[,7:12], 2,  max)
# minimum growth rate
min1 = as.numeric(allresults[1,7:12])
mxp1 = c(7:12)
for (i in 1:6) mxp1[i] = allresults[which(allresults[,(i+6)]==max1[i]),13]
summary1 = data.frame(mxp=mxp1, max=max1, rate=c("100%", "80%", "60%", "40%", "20%", "0%"))

# plot stochastic  growth and deterministic
e2 = ggplot(data=allresults2, 
           aes(x=p, y=lambda))
e2 = e2+geom_line(aes(color=rate, lty=stoch)) + labs(y="population growth rate log(lambda)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_linetype_manual(name = "model", values=c(2, 1), labels = c("deterministic", "stochastic")) +
  scale_y_continuous(limits=c(-.5, .5)) 
e2 + geom_point(data=summary1, aes(x=mxp, y=max1, color=as.factor(rate)))

# Just deterministic
e3 = ggplot(data=allresults2[which(allresults2$stoch=="n"),], 
            aes(x=p, y=lambda))
e3 = e3+geom_line(aes(color=rate)) + labs(y="population growth rate (logλ)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_y_continuous(limits=c(-.5, .5)) 
e3 
 # Just stochastic
e4 = ggplot(data=allresults2[which(allresults2$stoch=="y"),], 
            aes(x=p, y=lambda))
e4 = e4+geom_line(aes(color=rate)) + labs(y="population growth rate (logλs)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_y_continuous(limits=c(-.5, .25)) + geom_point(data=summary1, aes(x=mxp, y=max1, color=rate))
e4 = e4+ annotate("segment", x = mxp1[6], xend = mxp1[6], y = min1[1], yend = max1[6],
              colour = "black", lty=3) +
  annotate("segment", x = 0, xend = 1, y = min1[1], yend = min1[1],
           colour = "black", lty=3)

svg(filename="deterministic.svg", width=6, height=4)
e3
dev.off()
svg(filename="stochastic.svg", width=6, height=4)
e4
dev.off()

# calculate probability of extinction in 500 years for the different predation rates
tf=500
resultsEx = ldply(pred, function(pred2){
  ex.0 = replicate(500, (foreach(i=1:21, .combine=c) %dopar% Ex(p[i], pred2)), simplify=T)
  ex2.0 = rowSums(ex.0)/ncol(ex.0)
  return(ex2.0)
})


# reshape the extinction probabilities data frame
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