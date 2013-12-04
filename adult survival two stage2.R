# Let's look at how changing adult survival affects extinction probabilities
# load popbio library for lambdas
library(popbio)
# load foreach and doparallel for parallel processing
library(foreach)
library(doParallel)
# register number of cores for my shitty computer
registerDoParallel(cores=2)
library(ggplot2)
library(plyr)

# function to calculate extinction
Ex1 = function(p, states1) {
  # set the seed so the curve is smoother (Sebastian told me to)
  Runmat = PatchDDstoch(p, M, states=states1, fx, n0, npatch, nstg, tf=500, P, pred)[1,]
  if (Runmat[500]==0) ex = 1 else ex = 0
  return(ex)
}

# function to calculate stochastic lambdas
foo21 = function(p, states1) {
  lams = PatchAstoch2(p, states1, fx, n0, npatch, nstg, tf=100000, P, pred)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}

# Calculate growth rate for particular changes in survivals
Survives1 = function(j, a) {
  states1 <- cbind(states[,1]*j, states[,2]*a)
  r =  ldply(p, foo21,states1=states1)
  return(r)
}
# Calculate extinction probs for particular changes in survivals
Expr = function(j, a) {
  states1 <- cbind(states[,1]*j, states[,2]*a)
  ex.0 = replicate(1000, sapply(p, Ex1, states1=states1), simplify=T)
  ex2.0 = rowSums(ex.0)/ncol(ex.0)
  return(ex2.0)
}

# compile functions to make them run faster (maybe)
library(compiler)
PatchAstoch2 = cmpfun(PatchAstoch21)
PatchDDstoch = cmpfun(PatchDDstoch1)
Ex = cmpfun(Ex1)
Survives = cmpfun(Survives1)
foo2 = cmpfun(foo21)
Expr = cmpfun(Expr)


# probability of different states
g = .25 # probability of a good year
b= .25 # probability of a bad year
o=.25 # probability of a average year
c=.25 # probability of chytrid
P = matrix(c(g,b,o,c), 4, 4)

# final time
tf=500

# we got some extinctions with a predation of 50%, so we'l use that for this analysis
pred= .5

# matrix of different survival scenarios
surv = matrix(c(seq(.2, 2, by=.2), rep(1, 20), seq(.2, 2, by=.2)), ncol=2)

# extinction probabilities for different predation scenarios with lower adult survival to show shape of curve better
exmatpred = ldply(pred, function(x) { 
  states1 = cbind(states[,1]*j, states[,2]*a)
  ex.0 = replicate(1000, sapply(p, Ex1, states1=cbind(states[,1]*j, states[,2]*a)), simplify=T)
  ex2.0 = rowSums(ex.0)/ncol(ex.0)
  return(ex2.0)}, .parallel=T)
exmatpred2 = as.data.frame(exmatpred)
exmatpred2[,1]=NULL
names(exmat2.1) = p
exmat2.1$stage = c(rep("j", 7), rep("a", 7))
exmat2.1$surv = rep(seq(.2,1.4, by=.2), 2)
write.csv(exmat2.1, file="exmatpreds.csv")


# calculate extinction probabilities for different survival scenarios
exmat = adply(surv, 1, function(x) {
  Expr(j=x[1], a=x[2])}, .parallel=T,.progress = "tk")
exmat2.1 = as.data.frame(exmat)
exmat2.1[,1]=NULL
names(exmat2.1) = p
exmat2.1$stage = c(rep("j", 7), rep("a", 7))
exmat2.1$surv = rep(seq(.2,1.4, by=.2), 2)
write.csv(exmat2.1, file="exmattwostage.csv")
# calculate lambdas

survmat = foreach (i=1:20, combine=cbind) %dopar% {
  Survives1(j=surv[i,1], a=surv[i,2])
}
 
survmat2 = as.data.frame(survmat)
names(survmat2) = c(paste("j", seq(.2,2, by=.2)), paste("a", seq(.2,2, by=.2)))
survmat2$p = p

write.csv(survmat2, file="survmat2.csv")

library(reshape2)
survmat3 = melt(survmat2, id.vars = "p", variable.name="surv")
survmat3$stage = c(rep("j", 210), rep("a", 210))
survmat3$surv = rep(seq(.2,2, by=.2), each=21)
s = ggplot(data=survmat3, aes(x=p, y=value, color=surv)) + geom_point()
s

exmat3 = melt(exmat2.1, id.vars = c("stage", "surv"), variable.name= "p", value.name="exprob")
exmat3$surv = as.factor(exmat3$surv)
exmat3$p = rep(p, each=14)
explotl = ggplot(data=exmat3[which(exmat3$stage=="l"),], aes(x=p12, y= exprob, color=surv)) + geom_line()
explotl
explotj = ggplot(data=exmat3[which(exmat3$stage=="j"),], aes(x=p12, y= exprob, color=surv)) + geom_line()
explotj
explota = ggplot(data=exmat3[which(exmat3$stage=="a"),], aes(x=p12, y= exprob, color=surv)) + geom_line()
explota
explot = ggplot(data=exmat3, aes(x=p, y= exprob, color=surv, lty=stage)) + geom_line() +
  labs(x="proportion of juveniles \n dispersing to the high predation patch", y= "probability of extinction in 500yrs", linetype="life stage") +
  guides(color=guide_legend(ncol=2, title="change in survival"))
explot
# find the proportion of juveniles moving that maximizes the growth rate with changes in larval survival
maxlam = apply(survmat2[,1:20], 2, max)
minlam = as.numeric(survmat2[1,1:20])
maxs = survmat2[1:20,]
for (i in 1:20) maxs[i,] = survmat2[which(survmat2[,i]==maxlam[i]),]

# data frame for summary statistics with chanes in survival of each life stage
summary = data.frame(levels = rep(seq(.2, 2, by=.2), 2), stage = c(rep("j", 10),rep("a", 10)), maxs=maxlam, p = maxs$p, ldiff=(maxlam-minlam))
write.csv(summary, file = "summary survivals2.csv")
# graph changes in location of peak of the lambda curve
lamlocal = qplot(levels, p, data= summary, geom="line", color=stage, xlab= "increase in survival", ylab="migration proportion at \n peak of migration/lambda curve", main = "Proporiton of juves \n migrating that maximizes growth")
lamlocal


# Graph changes in height of the peak of the lambda curve
lampeak = qplot(levels, maxs, data= summary, geom="line", color=stage, xlab= "increase in survival", ylab="lambda at \n peak of migration/lambda curve", main = "Maximum growth rate for each  life \n stage at each survival level")
lampeak
# graph changes in difference between max and min or lambda curve

lamdiff = qplot(levels, ldiff, data= summary, geom="line", color=stage, xlab= "increase in survival", ylab="difference in lambda", main = "Difference between lambda at peak of curve and 0 for each  life \n stage at each survival level")

lamdiff

