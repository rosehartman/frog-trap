# Compare the geometric mean of the stochastic growth rate to the arithmetic mean
# Andy seeemed to suggest this would get at the individual fitness
# and explain the bet hedging thing better.

foo3 = function(p, pred) {
  lams = PatchAstoch2(p, states, fx, n0, npatch, nstg, tf, P, pred)
  # calculate the arithmetic mean
  avelam = sum(lams[lams!=0])/length(lams[lams!=0])
  # take the log of it to make it comparable
  log(avelam)
  
}

# apply stochastic growth function over all predation levels
resultsArith = ldply(pred, function(pred2){
  # calculate stochastic growth rates
  r.0 = foreach(i=1:21, .combine=c) %dopar% foo3(p=p[i], pred=pred2)
  return(r.0)
})

predSt = c("0s", ".2s", ".4s", ".6s", ".8s", "1s")
predA = c("0a", ".2a", ".4a", ".6a", ".8a", "1a")
allresultsA = data.frame(t(rbind(resultsdet, log(resultsStoch), log(resultsArith), p)))
names(allresultsA) = c(pred,predSt,predA,"p")
write.csv(allresultsA, file = "resutls arith.csv")

library(reshape2)
allresultsA2 = melt(allresultsA, id.vars="p", variable.name= "predation", value.name="lambda")
allresultsA2$stoch = rep(NA, 378)
allresultsA2$stoch[c(1:126)]="n"
allresultsA2$stoch[c(127:252)] = "y"
allresultsA2$stoch[c(253:378)] = "a"
allresultsA2$rate = c(NA, 378)
allresultsA2$rate[c(1:21, 127:147, 253:273)] = "100%"
allresultsA2$rate[c(22:42,  148:168, 274:294)] = "80%"
allresultsA2$rate[c(43:63 , 169:189, 295:315)] = "60%"
allresultsA2$rate[c( 64:84 , 190:210, 316:336)] = "40%"
allresultsA2$rate[c( 85:105 ,211:231, 337:357 )] = "20%"
allresultsA2$rate[c( 106:126 ,232:252, 358:378 )] = "0%"

f2 = ggplot(data=allresultsA2, 
            aes(x=p, y=lambda, color=rate, linetype=stoch))
f2 = f2+geom_line() + labs(y="population growth rate log(lambda)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_linetype_manual(name = "model", values=c(2, 1, 3), labels = c("deterministic", "stochastic", "arithmetic")) +
  scale_y_continuous(limits=c(-.5, .5))
f2 