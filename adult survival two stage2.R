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
survJ = c(.8, .9, 1, 1.1, 1.2, 1.5, 1.8, 2, 2.2, 3, 5, 10)
surv = matrix(c( survJ, 1/survJ), ncol=2)


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
maxlam = apply(survmat2[,1:12], 2, max)
minlam = as.numeric(survmat2[1,1:12])
maxs = survmat2[1:12,]
for (i in 1:12) maxs[i,] = survmat2[which(survmat2[,i]==maxlam[i]),]


# calculate stochastic lambdas for all changes in survival rate
survmat = foreach (i=1:12, combine=cbind) %dopar% {
  states1 <- cbind(states[,1]*surv[i,1], states[,2]*surv[i,2])
  r =  ldply(p, foo21,states1=states1)
  return(r)
}


# organize the data and save it as an csv
survmat2 = as.data.frame(survmat)
names(survmat2) = surv[,1]
survmat2$p = p
write.csv(survmat2, file="survmat tradeoff2.csv")
#survmat2.1 = cbind(fmat[1:10], survmat2[2:22])

# Get it into a format ggplot will like
library(reshape2)


# data frame for summary statistics with chanes in survival of each life stage
summary = data.frame(levels = surv[,1]/(surv[,1]+surv[,2]), maxs=maxlam, p = maxs$p, ldiff=(maxlam-minlam))
write.csv(summary, file = "summary survivals tradeoff.csv")

# graph changes in location of peak of the lambda curve
lamlocal = qplot(levels, p, data= summary, geom="line", xlab= "increase in survival", ylab="migration proportion at \n peak of migration/lambda curve", main = "Proporiton of juves \n migrating that maximizes growth")
lamlocal


# Graph changes in height of the peak of the lambda curve
lampeak = qplot(levels, maxs, data= summary, geom="line", xlab= "increase in survival", ylab="lambda at \n peak of migration/lambda curve", main = "Maximum growth rate for each  life \n stage at each survival level")
lampeak
# graph changes in difference between max and min or lambda curve

lamdiff = qplot(levels, ldiff, data= summary[5:12,], geom="line", xlab= "investment in juveniles", ylab="δlogλ_sMAX", main = "Predation on juveniles, juvenile dispersal")

lamdiff + scale_y_continuous(limits = c(0,.2))

svg(filename="tradeoff juves.svg", width=6, height=4)
lamdiff+ scale_y_continuous(limits=c(0, .26)) +scale_color_manual(values=c("f"="red", "j"="blue", "a"="green"), labels=c(f="fecundity", a="adult survival",j="juvenile recruitment"))
dev.off()
