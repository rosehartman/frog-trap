# Re-run the model with varying degrees of spatial autocorrelation

source('R/foo.R')

npatch = 2 # number of patches
n0 = c(1000,20,1000,20) # initial populations
fx = c(150,150) # fecundity vector
M = 50 # degree of density dependence
nstg=2 # of stages
tf=100000


# environmental transition matrix
g = .25 # probability of a good year
b= .25 # probability of a bad year
o=.25 # probability of a average year
c=.25 # probability of chytrid
P = matrix(c(g,b,o,c), 4, 4)
pred=.5
ac = seq(0,1, by=.1) # vector of various degrees of autocorrelation

# Run the model for all dispersal rates whith different levels
# of autocorrellation when predation is at 50%
resultsSynch = ldply(ac, function(ac){
  # calculate stochastic growth rates
  r.0 = foreach(i=1:21, .combine=c) %dopar% foo3(p=p[i], ac=ac)
  return(r.0)
})

# organize the output
resultssynch1 = data.frame(t(rbind(p,  resultsSynch)))
write.csv(resultssynch1, file = "resultssynch1.csv")
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

svg(filename="autocorrellation.svg", width=6, height=4)
s
dev.off()
