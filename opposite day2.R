# Now lets have predation effect the juveniles but have the adults be
# the migratory life stage.
source('~/Desktop/frog-trap/R/opposite day2 functions.R')

# apply stochastic growth function over all predation levels
resultsStochopp = ldply(pred, function(pred2){
  # calculate stochastic growth rates
  r.0 = foreach(i=1:21, .combine=c) %dopar% fooopp(p=p[i], pred=pred2, states=states)
  return(r.0)
})

# apply deterministic growth function over all predation levels
resultsdetopp = ldply(pred, function(pred){
  # deterministic growth rate
  r2.0 = sapply(p, Patchopp, s1=c(ok[2],ok[2]), J=c(ok[1],ok[1]), fx=fx,  pred=pred, simplify=T)
  r2.0 = log(r2.0) # take the log to make it comparable to stochastic rates
  return(r2.0) 
})
allopp1 = data.frame(t(rbind(resultsdetopp, resultsStochopp, p)))
names(allopp1) = c(pred,predSt,"p")
write.csv(allopp1, file = "adult dispersal.csv")

library(reshape2)
allopp = melt(allopp1, id.vars="p", variable.name= "predation", value.name="lambda")
allopp$stoch = rep(NA, 252)
allopp$stoch[c(1:126)]="n"
allopp$stoch[c(127:252)] = "y"
allopp$rate = c(NA, 252)
allopp$rate[c(1:21, 127:147)] = 6
allopp$rate[c(22:42,  148:168)] = 5
allopp$rate[c(43:63 , 169:189 )] = 4
allopp$rate[c( 64:84 , 190:210)] = 3
allopp$rate[c( 85:105 ,211:231 )] = 2
allopp$rate[c( 106:126 ,232:252 )] = 1
allopp$rate = ordered(allopp$rate, levels=c(1:6) ,
                      labels = rev(c("100%", "80%", "60%", "40%", "20%", "0%")))
qplot(data=allopp[which(allopp$stoch=="n"),], x=p, y=lambda, color=rate, geom="line") 
# plot stochastic  growth and deterministic
opp = ggplot(data=allopp, 
            aes(x=p, y=lambda, color=rate, linetype=stoch))
opp = opp+geom_line() + labs(y="population growth rate log(lambda)", x="proportion of each year's total adults \n dispersing to the high predation patch")+
  scale_linetype_manual(name = "model", values=c(2, 1), labels = c("deterministic", "stochastic")) +
  scale_y_continuous(limits=c(-.25, .5)) 
opp 



# Make a function to calculate average sensitivites for a bunch to time runs
# over a bunch of attractiveness values
elsplotopp = function(pred) {
  i=1:21
  # Apparently this gets too big for R to handle if you run it for 100,000 time steps, but that doesn't make sense...
  run = laply(i, function(x){
    ru = replicate(100,bigrunopp(tf=1000, p1=p[x], pred1=pred))
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

predopp = elsplot2(pred=.5)


survopp = foreach (i=1:20, combine=cbind) %dopar% {
  states1 <- cbind(states[,1]*surv[i,1], states[,2]*surv[i,2])
  r =  ldply(p, fooopp, states1=states1, pred=.5)
  return(r)
}

fopp = foreach (i=1:10, combine=cbind) %dopar% {
  fx1 = c(150*f[i], 150*f[i])
  r =  ldply(p, fooopp, states1=states, fx=fx1, pred=.5)
  return(r)
}
fopp = as.data.frame(fopp)
fopp$p = p
maxf = apply(fopp[,1:10], 2, max)
minf = as.numeric(fopp[1,1:10])
maxsf = fopp[1:10,]
<<<<<<< HEAD
for (i in 1:20) maxsf[i,] = fopp[which(fopp[,i]==maxf[i]),]
=======
>>>>>>> 1de473851b14e62da699025efbf29c0f4ac155e6
summaryf = data.frame(levels = seq(.2, 2, by=.2), stage = rep("f", 10), maxsopp=maxf, p = maxsf$p[1:10], ldiff=(maxf-minf))

survopp2 = as.data.frame(survopp)
survopp2.2 = cbind(fopp, survopp2)
names(survopp2.2) = c(paste("f", seq(.2,2, by=.2)), paste("j", seq(.2,2, by=.2)), paste("a", seq(.2,2, by=.2)))
survopp2.2$p = p
survopp2.1 = melt(survopp2.2, id.vars = "p", variable.name="stage")
survopp2.1$levels = rep(seq(.2,2, by=.2), each=21)
survopp2.1$stage = c(rep("f", 210),rep("j", 210), rep("a", 210))
survoppplot = ggplot(survopp2.1, aes(x=p, y=value, color=as.factor(levels), lty=stage)) + geom_line()
survoppplot + geom_point(data=summaryopp2, aes(x=p, y=maxsopp))

maxlamopp = apply(survopp2[,1:20], 2, max)
minlamopp = as.numeric(survopp2[1,1:20])
maxsopp = survopp2[1:20,]
for (i in 1:20) maxsopp[i,] = survopp2[which(survopp2[,i]==maxlamopp[i]),]

summaryopp = data.frame(levels = rep(seq(.2, 2, by=.2), 2), stage = c(rep("j", 10),rep("a", 10)), maxsopp=maxlamopp, p = maxsopp$p, ldiff=(maxlamopp-minlamopp))
summaryopp2 = rbind(summaryf, summaryopp)
write.csv(summaryopp2, file = "summary survivalsopp2.csv")
lamlocalopp = qplot(levels, p, data= summaryopp2, geom="line", color=stage, xlab= "increase in survival", ylab="migration proportion at \n peak of migration/lambda curve", main = "Proporiton of juves \n migrating that maximizes growth")
lamlocalopp
summaryopp2$stage = factor(summaryopp2$stage, levels = c("f", "j", "a"))

# Graph changes in height of the peak of the lambda curve
lampeakopp = qplot(levels, maxsopp, data= summaryopp2, geom="line", color=stage, xlab= "increase in survival", ylab="lambda at \n peak of migration/lambda curve", main = "Predation on juveniles, adults migrate")
lampeakopp
# graph changes in difference between max and min or lambda curve

lamdiffopp = qplot(levels, ldiff, data= summaryopp2, geom="line", color=stage, xlab= "proportional change in survival", ylab="δlogλ_sMAX", main = "predation on juveniles, adults disperse")

lamdiffopp + scale_y_continuous(limits=c(0, .26)) +scale_color_manual(values=c("f"="red", "j"="blue", "a"="green"), labels=c(f="fecundity", a="adult survival",j="juvenile recruitment"))

svg(filename="lamdiff adult dispersal.svg", width=6, height=4)
lamdiffopp+ scale_y_continuous(limits=c(0, .26)) +scale_color_manual(values=c("f"="red", "j"="blue", "a"="green"), labels=c(f="fecundity", a="adult survival",j="juvenile recruitment"))
dev.off()