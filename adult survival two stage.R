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
  Runmat = PatchDDstoch(App, M, states1, fx, n0, npatch, nstg, tf, P, pred)[1,]
  if (Runmat[500]==0) ex = 1 else ex = 0
  return(ex)
}

# function to calculate stochastic lambdas
foo21 = function(App, states1) {
  lams = PatchAstoch2(App, states1, fx, n0, npatch, nstg, tf, P, pred)
  avelam = sum(log(lams[lams!=0]))/length(lams[lams!=0])
  
}

# Calculate growth rate for particular changes in survivals
Survives1 = function(l, j, a) {
  states1 <- cbind(states[,1]*l, states[,2]*j, states[,3]*a)
  r = replicate(100, apply(App, 1, foo2, states1=states1), simplify=T)
  r = rowSums(r)/ncol(r)
  r = exp(r)
  return(r)
}

Expr = function(l, j, a) {
  states1 <- cbind(states[,1]*l, states[,2]*j, states[,3]*a)
  ex.0 = replicate(1000, apply(App, 1, Ex, states1=states1), simplify=T)
  ex2.0 = rowSums(ex.0)/ncol(ex.0)
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
# appearence of the two patches
App = cbind(c(0:9, seq(10, 100, by=5),seq(110, 190, by=10), seq(200, 1000, by=50)), rep(100,55))

# we got some extinctions with a predation of 50%, so we'l use that for this analysis
pred= c(.5,1)


# matrix of different survival scenarios
surv = matrix(c(seq(.1, 2, by=.2), rep(1, 20), rep(1,10), seq(.1, 2, by=.2),rep(1,30),seq(.1, 2, by=.2)), nrow=30, ncol=3)

# calculate extinction probabilities
exmat = adply(surv, 1, function(x) {
  Expr(l=x[1], j=x[2], a=x[3])}, .parallel=T,.progress = "tk")
exmat2.1 = as.data.frame(exmat)
exmat2.1[,1]=NULL
names(exmat2.1) = App[,1]
exmat2.1$stage = c(rep("l", 10), rep("j", 10), rep("a", 10))
exmat2.1$surv = rep(seq(.1,2, by=.2), 3)
write.csv(exmat2, file="exmat1.csv")
# calculate lambdas

survmat = foreach (i=1:30, combine=cbind) %dopar% {
  Survives1(l=surv[i,1], j=surv[i,2], a=surv[i,3])
}
 
survmat2 = as.data.frame(survmat)
names(survmat2) = c(paste("l", seq(.1,2, by=.2)), paste("j", seq(.1,2, by=.2)), paste("a", seq(.1,2, by=.2)))
survmat2$App = App[,1]
survmat2$p12 = App[,1]/(App[,1]+100)
write.csv(survmat2, file="survmat2.csv")

library(reshape2)
survmat3 = melt(survmat2, id.vars = c("App", "p12"), variable.name=)
qplot(data=survmat2, )

exmat3 = melt(exmat2.1, id.vars = c("stage", "surv"), variable.name= "App", value.name="exprob")
exmat3$App2 = rep(App[,1], each=30)
exmat3$p12 = exmat3$App2/(exmat3$App2+100)
exmat3$surv = as.factor(exmat3$surv)
explotl = ggplot(data=exmat3[which(exmat3$stage=="l"),], aes(x=p12, y= exprob, color=surv)) + geom_line()
explotl
explotj = ggplot(data=exmat3[which(exmat3$stage=="j"),], aes(x=p12, y= exprob, color=surv)) + geom_line()
explotj
explota = ggplot(data=exmat3[which(exmat3$stage=="a"),], aes(x=p12, y= exprob, color=surv)) + geom_line()
explota
explot = ggplot(data=exmat3, aes(x=p12, y= exprob, color=surv, linetype=stage)) + geom_line() +
  labs(x="proportion of juveniles \n dispersing to the high predation patch", y= "probability of extinction in 500yrs", linetype="life stage") +
  guides(color=guide_legend(ncol=2, title="change in survival"))
explot
# find the proportion of juveniles moving that maximizes the growth rate with changes in larval survival
maxlam = apply(survmat2, 2, max)
minlam = as.numeric(survmat2[1,])
survmat2$p12 = exprob$p12
maxs = survmat2[1:30,]
for (i in 1:30) maxs[i,] = survmat2[which(survmat2[,i]==maxlam[i]),]

# data frame for summary statistics with chanes in survival of each life stage
summary = data.frame(levels = rep(seq(.1, 2, by=.2), 3), stage = c(rep("l", 10),rep("j", 10),rep("a", 10)), maxs=maxlam, p12 = maxs$p12, ldiff=(maxlam-minlam))
write.csv(summary, file = "summary survivals2.csv")
# graph changes in location of peak of the lambda curve
lamlocal = qplot(levels, p12, data= summary, geom="line", color=stage, xlab= "increase in survival", ylab="migration proportion at \n peak of migration/lambda curve", main = "Proporiton of juves \n migrating that maximizes growth")
lamlocal


# Graph changes in height of the peak of the lambda curve
lampeak = qplot(levels, maxs, data= summary, geom="line", color=stage, xlab= "increase in survival", ylab="lambda at \n peak of migration/lambda curve", main = "Maximum growth rate for each  life \n stage at each survival level")
lampeak
# graph changes in difference between max and min or lambda curve

lamdiff = qplot(levels, ldiff, data= summary, geom="line", color=stage, xlab= "increase in survival", ylab="difference in lambda", main = "Difference between lambda at peak of curve and 0 for each  life \n stage at each survival level")

lamdiff

