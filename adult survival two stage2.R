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
states=cbind(states[,1], states[,2]*.6)
exmatpred = ldply(pred, function(x) { 
  pred=x
  ex.0 = replicate(1000, sapply(p, Ex, pred=x), simplify=T)
  ex2.0 = rowSums(ex.0)/ncol(ex.0)
  return(ex2.0)}, .parallel=T)
exmatpred2 = as.data.frame(exmatpred)
names(exmatpred2) = p
exmatpred2$pred = pred
write.csv(exmatpred2, file="exmatpreds.csv")
exmatpred3 = melt(exmatpred2, id.vars="pred", variable.name="p")
exmatpred3$p = rep(p, each=6)
exmatpred3$pred = ordered(exmatpred3$pred, labels = c("100%", "80%", "60%", "40%", "20%", "0%"))
expred = ggplot(data=exmatpred3, aes(x=p, y=value, color=pred)) + geom_line()
expred + labs(x="proportion of juveniles \n dispersing to the high predation patch", y= "probability of extinction in 500yrs", color="predation \n level")

# calculate extinction probabilities for different survival scenarios
exmat = adply(surv, 1, function(x) {
  states1 <- cbind(states[,1]*x[1], states[,2]*x[2])
  ex.0 = replicate(1000, sapply(p, Ex1, states1=states1), simplify=T)
  ex2.0 = rowSums(ex.0)/ncol(ex.0)
  return(ex2.0) }, .parallel=T,.progress = "tk")
exmat2.1 = as.data.frame(exmat)
exmat2.1[,1]=NULL
names(exmat2.1) = p
exmat2.1$stage = c(rep("j", 7), rep("a", 7))
exmat2.1$surv = rep(seq(.2,1.4, by=.2), 2)
write.csv(exmat2.1, file="exmattwostage.csv")

# calculate stochastic lambdas for all changes in survival rate
survmat = foreach (i=1:20, combine=cbind) %dopar% {
  states1 <- cbind(states[,1]*surv[i,1], states[,2]*surv[i,2])
  r =  ldply(p, foo21,states1=states1)
  return(r)
}

# this time let's change the fecundidties
f = seq(.2,2, by=.2)
fmat = foreach (i=1:10, combine=cbind) %dopar% {
  fx1 <- c(150*f[i], 150*f[i])
  r =  ldply(p, foo21,states1=states, fx=fx1)
  return(r)
}
fmat = as.data.frame(fmat)
names(fmat) = f
fmat$p = p
fmat2 = melt(fmat, id.vars = "p", variable.name="surv")
fmat2$stage = rep("f", 210)
fmat2$surv = rep(seq(.2,2, by=.2), each=21)
 
# organize the data and save it as an csv
survmat2 = as.data.frame(survmat)
names(survmat2) = c(paste("j", seq(.2,2, by=.2)), paste("a", seq(.2,2, by=.2)))
survmat2$p = p
write.csv(survmat2, file="survmat2.csv")
survmat2.1 = cbind(fmat[1:10], survmat2[2:22])

# Get it into a format ggplot will like
library(reshape2)
survmat3 = melt(survmat2.1, id.vars = "p", variable.name="surv")
survmat3$stage = c(rep("f", 210), rep("j", 210), rep("a", 210))
survmat3$surv = rep(seq(.2,2, by=.2), each=21)

# see what it looks like
s = ggplot(data=survmat3, aes(x=p, y=value, color=as.factor(surv))) + geom_line()
s

exmat3 = melt(exmat2.1, id.vars = c("stage", "surv"), variable.name= "p", value.name="exprob")
exmat3$surv = as.factor(exmat3$surv)
exmat3$p = rep(p, each=14)
explotj = ggplot(data=exmat3[which(exmat3$stage=="j"),], aes(x=p12, y= exprob, color=surv)) + geom_line()
explotj
explota = ggplot(data=exmat3[which(exmat3$stage=="a"),], aes(x=p12, y= exprob, color=surv)) + geom_line()
explota
explot = ggplot(data=exmat3, aes(x=p, y= exprob, color=surv, lty=stage)) + geom_line() +
  labs(x="proportion of juveniles \n dispersing to the high predation patch", y= "probability of extinction in 500yrs", linetype="life stage") +
  guides(color=guide_legend(ncol=2, title="change in survival"))
explot
# find the proportion of juveniles moving that maximizes the growth rate with changes in larval survival
maxlam = apply(survmat2.1[,1:30], 2, max)
minlam = as.numeric(survmat2.1[1,1:30])
maxs = survmat2.1[1:30,]
for (i in 1:30) maxs[i,] = survmat2.1[which(survmat2.1[,i]==maxlam[i]),]

# data frame for summary statistics with chanes in survival of each life stage
summary = data.frame(levels = rep(seq(.2, 2, by=.2), 3), stage = c(rep("f", 10),rep("j", 10),rep("a", 10)), maxs=maxlam, p = maxs$p, ldiff=(maxlam-minlam))
write.csv(summary, file = "summary survivals2.csv")
# graph changes in location of peak of the lambda curve
lamlocal = qplot(levels, p, data= summary, geom="line", color=stage, xlab= "increase in survival", ylab="migration proportion at \n peak of migration/lambda curve", main = "Proporiton of juves \n migrating that maximizes growth")
lamlocal


# Graph changes in height of the peak of the lambda curve
lampeak = qplot(levels, maxs, data= summary, geom="line", color=stage, xlab= "increase in survival", ylab="lambda at \n peak of migration/lambda curve", main = "Maximum growth rate for each  life \n stage at each survival level")
lampeak
# graph changes in difference between max and min or lambda curve

lamdiff = qplot(levels, ldiff, data= summary, geom="line", color=stage, xlab= "change in survival", ylab="difference in logλs", main = "Predation on juveniles, juvenile migration")

lamdiff + scale_y_continuous(limits = c(0,.26)) +scale_color_manual(values=c(f="red", j="blue", a="green"), labels=c(f="fecundity", a="adult survival",j="juvenile recruitment"))

