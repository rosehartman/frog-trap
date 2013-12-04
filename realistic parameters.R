# an attempt at more relistic parameters

library(popbio)
library(foreach)
library(doParallel)
registerDoParallel(cores=2)
# function to calculate extinction
Ex = function(App) {
  Runmat = PatchDDstoch(App, M, states, fx, n0, npatch, nstg, tf, P, pred)[1,]
  if (Runmat[500]==0) ex = 1 else ex = 0
  return(ex)
}


# function to calculate stochastic lambdas
foo2 = function(App) {
  lams = PatchAstoch2(App, states, fx, n0, npatch, nstg, tf, P, pred)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}


npatch = 2 # number of patches
n0 = c(1000,20,20,1000,20,20) # initial populations
fx = c(150,150) # fecundity vector
M = 50 # degree of density dependence
nstg=3 # of stages
tf=500


# larval, juvenile, and adult survivorships in different types of years
# a good year
good = c(.05,.4,.7) 
# a bad year
bad = c(.01,.1,.2)
# an average year
ok = c(.04,.3,.6)
# a year when chytrid fungus wipes out the juvenile age class
chytrid = c(.04,0,0.5)
# bind the possible states together into a matrix
states = rbind(good, bad, ok, chytrid)

# environmental transition matrix
g = .25 # probability of a good year
b= .25 # probability of a bad year
o=.25 # probability of a average year
c=.25 # probability of chytrid
P = matrix(c(g,b,o,c), 4, 4)

foo = function(App, states=states){
  # we need to find the mean of growth rates from the stochastic model and use it for the deterministic one

  Ls = rep(sum(states[,1]*P[,1]), 2)
  J = rep(sum(states[,2]*P[,2]), 2)
  s1 = rep(sum(states[,3]*P[,3]), 2)
  gr = Patchlam(App, Ls, J, s1, fx, n0, npatch, nstg, tf, pred)
  return(gr)
}

App = cbind(c(0:9, seq(10, 100, by=5),seq(110, 190, by=10), seq(200, 1000, by=50)), rep(100,55))

pred= c(1,1)
r.0 = replicate(50, foreach(i=1:55, .combine=c) %dopar% foo2(App[i,]), simplify=T)
r.0 = rowSums(r.0)/ncol(r.0)
r.0 = exp(r.0)
r2.0 = apply(App,1, foo)
ex.0 = replicate(500, (foreach(i=1:55, .combine=c) %dopar% Ex(App[i,])), simplify=T)
ex2.0 = rowSums(ex.0)/ncol(ex.0)
mean1 = MTE(App, nrep=100, tf=1000)


pred= c(.8,1)
r.8 = replicate(50, foreach(i=1:55, .combine=c) %dopar% foo2(App[i,]), simplify=T)
r.8 = rowSums(r.8)/ncol(r.8)
r.8 = exp(r.8)
r2.8 = apply(App,1, foo)
ex.8 = replicate(500, (foreach(i=1:55, .combine=c) %dopar% Ex(App[i,])), simplify=T)
ex2.8 = rowSums(ex.8)/ncol(ex.8)
mean.8 = MTE(App, nrep=100, tf=1000)


pred= c(.5,1)
r.5 = replicate(50, foreach(i=1:55, .combine=c) %dopar% foo2(App[i,]), simplify=T)
r.5 = rowSums(r.5)/ncol(r.5)
r.5 = exp(r.5)
r2.5 = apply(App,1, foo)
ex.5 = replicate(100, (foreach(i=1:55, .combine=c) %dopar% Ex(App[i,])), simplify=T)
ex2.5 = rowSums(ex.5)/ncol(ex.5)
mean.5 = MTE(App, nrep=100, tf=1000)

pred= c(.1,1)
r.1 = replicate(50, foreach(i=1:55, .combine=c) %dopar% foo2(App[i,]), simplify=T)
r.1 = rowSums(r.1)/ncol(r.1)
r.1 = exp(r.1)
r2.1 = apply(App,1, foo)
ex.1 = replicate(100, (foreach(i=1:55, .combine=c) %dopar% Ex(App[i,])), simplify=T)
ex2.1 = rowSums(ex.1)/ncol(ex.1)
mean.1 = MTE(App, nrep=100, tf=1000)


exprobpred = data.frame(App = App[,1], p12 = App[,1]/(App[,1]+App[,2]), r.0 = r.0,  r.8=r.8,  r.5=r.5,  r.1=r.1,  r2.0=r2.0, r2.8=r2.8,r2.5=r2.5, r2.1=r2.1,ex.0=ex2.0, ex.1=ex2.1, ex.5=ex2.5, ex.8=ex2.8)
write.csv(exprobpred, file = "exprob real with lams.csv")

layout(matrix(c(1,1)))
plot(exprobpred$p12, exprobpred$r2.0, type="l", col= "black", lty=1, xlab= "proportion juveniles \n migrating to high predation patch", ylab= "growth rate", main= "growth rate with varying \n levels of predation")
plot(exprobpred$p12, exprobpred$r.0, type="l", col= "black", lty=1, xlab= "proportion juveniles \n migrating to high predation patch", ylab= "growth rate", xlim = c(0, 1.3), ylim= c(0.7, 1.2), main= "stochastic growth rate with varying \n levels of predation")
lines(exprobpred$p12, exprobpred$r2.0, col="black")
lines(exprobpred$p12, exprobpred$r.8, col="red")
lines(exprobpred$p12, exprobpred$r2.8, col="red", lty = 2)
lines(exprobpred$p12, exprobpred$r.5, col="green")
lines(exprobpred$p12, exprobpred$r2.5, col="green", lty = 2)
lines(exprobpred$p12, exprobpred$r.1, col="blue")
lines(exprobpred$p12, exprobpred$r2.1, col="blue", lty = 2)
lines(rep(.5, 16), seq(0, 1.5, by=.1), lty=3, col="grey")
legend("bottomright", c("0%", "20%", "50%", "90%", "deterministic"), lty= c(1,1,1,1, 2), col=c("black", "red",  "green", "blue","black"), title="predation level",  cex = .7)


layout(matrix(c(1,1)))
plot(exprobpred$p12, exprobpred$ex.5, type="l", col= "green", xlab= "proportion of juveniles \n immigrating to high-predation patch", ylab= "pobability of extinction in 500 years", ylim=c(0,1), xlim=c(0, 1.3), main= "probability of extinction with varying \n levels of predation")
lines(exprobpred$p12, exprobpred$ex.1, col="blue")
lines(exprobpred$p12, exprobpred$ex.8, col="red")
lines(exprobpred$p12, exprobpred$ex.0, col="black")
lines(rep(.5, 11), seq(0, 1, by=.1), lty=3, col="grey")
legend('bottomright', c("0%", "20%", "50%", "90%"), lty= c(1,1,1,1), col=c("black", "red",  "green", "blue"), title="predation level", cex=0.7)

maxpred = apply(exprobpred[,3:6], 2,  max)
minpred = as.numeric(exprobpred[1,3:6])
maxspred = exprobpred[1:4,]
for (i in 3:6) maxspred[(i-2),] = exprobpred[which(exprobpred[,i]==maxpred[(i-2)]),]

summarypred = data.frame(levels = c(0, .2, .5, .9), maxpred = maxpred, ppred = maxspred$p12, diffpred=(maxpred-minpred))
plot(summarypred$p12, summarypred$maxpred, type="l")

# get the dataframe into a format ggplot will like
library(reshape2)
exprobpred2 = melt(exprobpred, id.vars=c("App", "p12"), variable.name= "predation", value.name="value")
exprobpred2$metric = rep(NA, 660)
exprobpred2$metric[1:440] = "lambda"
exprobpred2$metric[441:660] = "exprob"
exprobpred2$stoch = rep(NA, 660)
exprobpred2$stoch[c(1:55, 111:165, 221:275, 331:385, 441:660)]="y"
exprobpred2$stoch[c(56:110, 166:220, 276:330, 386:440)] = "n"
exprobpred2$rate = c(NA, 660)
exprobpred2$rate[c(1:110, 441:495)] = "0%"
exprobpred2$rate[c(111:220,606:660 )] = "20%"
exprobpred2$rate[c(221:330, 551:605)] = "50%"
exprobpred2$rate[c(331:440,496:550 )] = "90%"

# plot deterministic growth
e = ggplot(data=exprobpred2[which(exprobpred2$stoch=="n"),], 
          aes(x=p12, y=value, color=predation))
e = e+scale_color_manual(name = "predation", values=c("black", "red", "green", "blue"), labels = c("r2.0" = "0%", "r2.8" = "20%", "r2.5" = "50%", "r2.1" = "90%")) + 
  geom_line(linetype = 2) + labs(y="lambda", x="proportion of juveniles \n dispersing to the high predation patch")+
  ggtitle("Deterministic growth rate") +
  scale_y_continuous(limits=c(.7, 1.4))
e 

# plot stochastic  growth and deterministic
e = ggplot(data=exprobpred2[which(exprobpred2$metric=="lambda"),], 
           aes(x=p12, y=value, color=rate, linetype=stoch))
e = e+scale_color_manual(name = "predation", values=c("black", "red", "green", "blue"), labels = c("0%", "20%", "50%", "90%")) + 
  geom_line() + labs(y="population growth rate (lambda)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_linetype_manual(name = "model", values=c(2, 1), labels = c("deterministic", "stochastic")) +
  scale_y_continuous(limits=c(.7, 1.4))
e 

# Plot extinction probabilities
explot.1 = ggplot(data=exprobpred2[which(exprobpred2$metric=="exprob"),], 
                aes(x=p12, y=value, color=rate))
explot.1 = explot.1+scale_color_manual(name = "predation", values=c("black", "red", "green", "blue"), labels = c("0%", "20%", "50%", "90%")) + 
  geom_line() + labs(y="probability", x="proportion of juveniles \n dispersing to the high predation patch")+
  ggtitle("probability of extinction in 500 years") +
  scale_y_continuous(limits=c(0, 1))
explot.1