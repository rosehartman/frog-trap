# We will now take out stochasticity in adult survival to
# make things analytically easier.

# This is the same script as the "for noams server.R" file,
# but with all the adult survivals set at 0.5 for all environmental states


# load required packages:
library(popbio)
library(reshape2)
library(ggplot2)
library(plyr)
library(foreach)
library(doParallel)
# Noam, I don't know if your server has more cores, so register
# however many it has here.
registerDoParallel(cores=2)

#load the functions I have defined to run this puppy

source('R/foo.R')
source('R/lambda two stage.R')
source('R/Ex1.R')

geometricmean = function(x) { prod(x)^(1/length(x))}

# define all the variables
npatch = 2 # number of patches
n0 = c(1000,20,1000,20) # initial populations
fx = c(150,150) # fecundity vector
nstg=2 # of stages
tf=1000000

# juvenile, and adult survivorships in different types of years
# a good year
good = c(.02,.5) 
# a bad year
bad = c(.002,.5)
# an average year
ok = c(.009,.5)
# a year when chytrid fungus wipes out the juvenile age class
chytrid = c(0.0001,0.5)
# bind the possible states together into a matrix
states = rbind(good, bad, ok, chytrid)
# probability of each state
P = matrix(c(.25,.25,.25,.25), 4, 4)
# dispersal values
p =  seq(0,1,by=0.05)
# predation values
pred = seq (0,1, by=.2)

# apply deterministic growth function over all predation levels

resultsdet = ldply(pred, function(pred){
  # deterministic growth rate
  r2.0 = sapply(p, Patchlam, s1=c(.5,.5), J=c(.009,.009), fx=fx,  pred=pred, simplify=T)
r2.0 = log(r2.0) # take the log to make it comparable to stochastic rates
return(r2.0) 
})

det = data.frame(t(rbind(resultsdet, p)))
names(det) = c(pred,"p")
det2 =  melt(det, id.vars="p", variable.name= "predation", value.name="lambda")
det2$rate = c(NA, 252)
det2$rate = rep(6:1, each=21)
det2$rate = ordered(det2$rate, levels=c(1:6) ,
                            labels = rev(c("100%", "80%", "60%", "40%", "20%", "0%")))


# Just deterministic
e3 = ggplot(data=det2, 
            aes(x=p, y=lambda))
e3 = e3+geom_line(aes(linetype=rate)) + labs(y="population growth rate (logλ)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_y_continuous(limits=c(-.5, .5)) 
e3 

# apply stochastic growth function over all predation levels
resultsStoch = ldply(pred, function(pred2){
  # calculate stochastic growth rates
  r.0 = foreach(i=1:21, .combine=c) %dopar% foo2(p=p[i], pred=pred2)
  return(r.0)
})


# Organize the output and save it                   
allresults = data.frame(t(rbind(resultsStoch, p)))
names(allresults) = c(pred,"p")
write.csv(allresults, file = "twostage_million1.csv")

# get the dataframe into a format ggplot will like
allresults2a = melt(allresults, id.vars="p", variable.name= "predation", value.name="lambda")
allresults2a$rate = c(NA, 252)
allresults2a$rate = rep(6:1, each=21)
allresults2a$rate = ordered(allresults2a$rate, levels=c(1:6) ,
                           labels = rev(c("100%", "80%", "60%", "40%", "20%", "0%")))

# calculate maximum growth rate
max1 = apply(allresults[1:6], 2,  max)
# minimum growth rate
min1 = as.numeric(allresults[1,1:6])
mxp1 = c(1:6)
for (i in 1:6) mxp1[i] = allresults[which(allresults[,(i)]==max1[i]),7]

summary1a = data.frame(mxp=mxp1, max=max1, rate=c("100%", "80%", "60%", "40%", "20%", "0%"))
write.csv(summary1a, file="summary_million1.csv")

# plot stochastic simulations
e4a = ggplot(data=allresults2a, 
            aes(x=p, y=lambda))
e4a = e4a+geom_line(aes(color=rate)) + labs(y="population growth rate (logλs)", x="proportion of each year's total juveniles \n dispersing to the high predation patch")+
  scale_y_continuous(limits=c(-.5, .25)) + geom_point(data=summary1a, aes(x=mxp, y=max1, color=rate))
e4a = e4a+ annotate("segment", x = mxp1[6], xend = mxp1[6], y = min1[1], yend = max1[6],
                  colour = "black", lty=3) +
  annotate("segment", x = 0, xend = 1, y = min1[1], yend = min1[1],
           colour = "black", lty=3)

svg(filename="stochastic1.svg", width=6, height=4)

e4a

dev.off()


# Now we will run the simulations for spatial synchrony
# Re-run the model with varying degrees of spatial autocorrelation
# and 1 million time steps


source('R/foo.R')

ac = seq(0,1, by=.1) # vector of various degrees of autocorrelation
pred = 0.5 # set predation to 0.5 for all future simulations

# Run the model for all dispersal rates whith different levels
# of autocorrellation when predation is at 50%
resultsSynch = ldply(ac, function(ac){
  # calculate stochastic growth rates
  r.0 = foreach(i=1:21, .combine=c) %dopar% foo3(p=p[i], ac=ac)
  return(r.0)
})

# organize the output
resultssynch1 = data.frame(t(rbind(p,  resultsSynch)))
write.csv(resultssynch1, file = "resultssynch11.csv")
names(resultssynch1) = c("p", ac)

resultssynch2 = melt(resultssynch1, id.vars= c("p"))
resultssynch2$rate = rep(NA, 231)
resultssynch2$rate = as.factor(rep(seq(0,1, by=.1), each=21))


# plot  growth rates
s = ggplot(data=resultssynch2[c(1:21, 43:63, 106:126, 169:189, 211:231),], 
           aes(x=p, y=value, color=rate))
s = s+
  geom_line() + labs(y="log lambda", x="proportion of juveniles \n dispersing to the high predation patch")+
  ggtitle("stochastic growth rates with \n spatial synchrony") +scale_color_discrete(name="degree of \n autocorrellation")

s 

svg(filename="autocorrellation1.svg", width=6, height=4)
s
dev.off()

# Now the results going into figure 3 with the different survival rates

# matrix of different survival scenarios
# The (geometric) mean juvenile recruitment is 0.002449
# so the average life span (J/(1-s)) is 0.00489
# We will hold life span constant and trade off between juv and adult survival
survJ = seq(.1,1.9, by=.1) #(rate to increase or decrease J, not J itself!)

# calculate stochastic lambdas for all changes in survival rate
survmat = foreach (i=1:19, combine=cbind) %dopar% {
  J = states[,1]*survJ[i] # increase or decrease J by a set amount
  a = rep((-geometricmean(J)/0.00489 +1), length(J)) # change adult survival so life span remains constant
  states1 <- cbind(J, a)
  r =  ldply(p, foo21,states1=states1)
  return(r)
}


# organize the data and save it as an csv
survmat2 = as.data.frame(survmat)
names(survmat2) = survJ
survmat2$p = p
write.csv(survmat2, file="survmat million1.csv")

# find the proportion of juveniles moving that maximizes the growth rate with changes in larval survival
maxlam = apply(survmat2[,1:19], 2, max)
minlam = as.numeric(survmat2[1,1:19])
maxs = survmat2[1:19,]
for (i in 1:19) maxs[i,] = survmat2[which(survmat2[,i]==maxlam[i]),]

# data frame for summary statistics with changes in survival of each life stage
summary = data.frame(levels = survJ, maxs=maxlam, p = maxs$p, ldiff=(maxlam-minlam))
write.csv(summary, file = "summary survivals million1.csv")


# predation only effects the adults instead of teh juveniles.

source('R/opposite day functions.R')
# Calculate growth-dispersal curves for various changes in adult/juv survival tradeoff
survAds = foreach (i=1:19, combine=cbind) %dopar% {
  J = states[,1]*survJ[i] # increase or decrease J by a set amount
  a = rep((-geometricmean(J)/0.00489 +1), length(J))  # change adult survival so life span remains constant
  states1 <- cbind(J, a)
  r =  ldply(p, fooAds, states1=states1, pred=.5)
  return(r)
}

# organize it
survads2 = as.data.frame(survAds)
names(survads2) = survJ
survads2$p = p

# calculate maximum lambdas and value of hedging
maxlamads = apply(survads2[,1:19], 2, max)
minlamads = as.numeric(survads2[1,1:19])
maxsads = (survads2[1:19,])
for (i in 1:19) maxsads[i,] = survads2[which(survads2[,i]==maxlamads[i]),]

summaryads = data.frame(levels = survJ, maxs=maxlamads, p = maxs$p, ldiff=(maxlamads-minlamads))

write.csv(summaryads, file = "summary survivalsads million1.csv")

# Now lets have predation effect the juveniles but have the adults be
# the migratory life stage.

source('R/opposite day2 functions.R')

# growth curves with different changes in survival
survopp = foreach (i=1:19, combine=cbind) %dopar% {
  J = states[,1]*survJ[i] # increase or decrease J by a set amount
  a = rep((-geometricmean(J)/0.00489 +1), length(J))  # change adult survival so life span remains constant
  states1 <- cbind(J, a) 
  r =  ldply(p, fooopp, states1=states1, pred=.5)
  return(r)
}

# Organize everything
survopp2 = as.data.frame(survopp)
names(survopp2) = survJ
survopp2$p = p
survopp2.1 = melt(survopp2, id.vars = "p")
survopp2.1$levels = rep(survJ, each=21)

# calculate maxes and mins
maxlamopp = apply(survopp2[,1:19], 2, max)
minlamopp = as.numeric(survopp2[1,1:19])
maxsopp = survopp2[1:19,]
for (i in 1:19) maxsopp[i,] = survopp2[which(survopp2[,i]==maxlamopp[i]),]

summaryopp = data.frame(levels = survJ, maxs=maxlamopp, p = maxsopp$p, ldiff=(maxlamopp-minlamopp))
write.csv(summaryopp, file = "summary survivalsopp million1.csv")

# Now lets have predation effect the adults AND have the adults be
# the migratory life stage.

source('R/opposite day3 functions.R')

survO = foreach (i=1:19, combine=cbind) %dopar% {
  J = states[,1]*survJ[i] # increase or decrease J by a set amount
  a = rep((-geometricmean(J)/0.00489 +1), length(J))  # change adult survival so life span remains constant
  states1 <- cbind(J, a) 
  r =  ldply(p, fooopp3, states1=states1, pred=.5)
  return(r)
}

survO2 = as.data.frame(survO)
names(survO2) = survJ
survO2$p = p

maxlamO = apply(survO2[,1:19], 2, max)
minlamO = as.numeric(survO2[1,1:19])
maxsO = survO2[1:19,]
for (i in 1:19) maxsO[i,] = survO2[which(survO2[,i]==maxlamO[i]),]

summaryO = data.frame(levels = survJ, maxs=maxlamO, p = maxsO$p, ldiff=(maxlamO-minlamO))
write.csv(summaryO, file = "summary survivalsO million1.csv")


# Add the data from the different scenarios together and plot them
summary$scenario = rep("1", nrow(summary))
summaryads$scenario = rep("2",nrow(summaryads))
summaryopp$scenario = rep("3", nrow(summaryopp))
summaryO$scenario = rep("4", nrow(summaryO))
summarytotal = rbind(summary, summaryads, summaryopp, summaryO)
summarytotal$scenario = as.factor(summarytotal$scenario)

lamdifftot = qplot(levels, ldiff, data = summarytotal, geom="line", color=scenario, xlab="proportional investment in juveniles", ylab= "δlogλ_sMAX")
lamdifftot + scale_color_manual( values=c("red","blue","green","black"), labels = c("juvenile dispersal, \n predation on juveniles", "juvenile dispersal, \n predation on adults", "adult dispersal, \n predation on juveniles", "adult dispersal, \n predtion on adults"))

# save the resulting plot
svg(filename="lamdiff_total1.svg", width=8, height=4)
lamdiffO+ scale_y_continuous(limits=c(0, .35)) 
dev.off()

