# Sensitivity and elasitcity matricies of stochastic lambda
# adapted from Caswell 2001 chapter 14.4

StochSens <- function(As){
  
  # A translation of Caswell's (2001) Matlab code fragment
  tf <- dim(As)[3]
  k <- dim(As)[1]
  wvec <- rep(1/k,k)
  w <- matrix(NA, nrow=k, ncol=tf)
  
  # generate sequence of structure vectors
  
  r <- rep(0,tf)
  
  for(i in 1:tf){
    a <- As[,,i]
    wvec <- a%*%wvec
    r[i] <- sum(wvec)
    wvec <- wvec/r[i]
    w[,i] <- wvec
  }
  
  # specifiy initial reproductive value vector
  
  vvec <- rep(1/k,k)
  v <- matrix(NA, nrow=k, ncol=tf)
  
  for(i in rev(1:tf)){
    a <- As[,,i]
    vvec <- vvec%*%a
    v[,i]<- t(vvec)
  }
  
  sensmat <- matrix(0,nrow=k,ncol=k)
  elasmat <- matrix(0,nrow=k,ncol=k)
  
  for(i in 1:(tf-1)){
    # for some reason, need the as.numeric() to get the division by
    # scalar to work 
    sensmat <- sensmat+((v[,i+1]%*%t(w[,i])) /
                          as.numeric(r[i]*t(v[,i+1])%*%w[,i+1]))
    a <- As[,,i]
    elasmat <- elasmat+((v[,i+1]%*%t(w[,i])*a) /
                          as.numeric((r[i]*t(v[,i+1])%*%w[,i+1])))
  }
  
  # Devide by the number of time steps
  sensmat <- sensmat/tf
  elasmat <- elasmat/tf
  
  out <- list(sensitivities=sensmat, elasticities=elasmat)
  out
}


# create an array of projection matricies for each time step
As <- replicate(tf, Getmat(App, state, fx, n0, npatch, nstg, P, pred))
# calculate the stochastic sensitivity matrix for that time period
As <- replicate(tf, Getmat(App=c(100,100), state, fx, n0, npatch, nstg, P, pred))
StochSens(As)

# Make a function out of the stochsens time period so I can replicate it
bigrun = function(tf, App1, pred) {
  As <- replicate(tf, Getmat(App1, state, fx, n0, npatch, nstg, P, pred))
  StochSens(As)$elasticities
}

# Make a function to calculate average sensitivites for a bunch to time runs
# over a bunch of attractiveness values
elsplot = function(pred) {
i=1:55
run = aaply(i, 1, function(x){
  ru = replicate(100, bigrun(500, App1=App[x,], pred=pred))
  aaply(ru, 1:2, function(thingy) {sum(thingy)/100})
},
            .parallel=T)

# Data frame with the elasticity of each non-zero matrix entry
elsdf = data.frame(App=App[,1], p12=App[,1]/(App[,1]+App[,2]), f1=run[, 1,3], l1=run[, 2,1], j21=run[, 3,5], j11=run[, 3,2], a1=run[, 3,3], 
f2=run[, 4,6], l2=run[, 5,4], j12=run[, 6,2], j22=run[, 6,5], a2=run[, 6,6])
library(reshape2)
elsedf2 = melt(elsdf, id.vars=c("App", "p12"), variable.name="stage",value.name="elas")
elsedf2$patch = rep(NA, 550)
elsedf2$stage = rep(NA, 550)
elsedf2$patch[1:275] = "1"
elsedf2$patch[276:550] = "2"
elsedf2$stage[1:55]="f"
elsedf2$stage[56:110]="l"
elsedf2$stage[111:165]="j2"
elsedf2$stage[166:220]="j1"
elsedf2$stage[221:275]="a"
elsedf2$stage[276:330]="f"
elsedf2$stage[331:385]="l"
elsedf2$stage[386:440]="j1"
elsedf2$stage[441:495]="j2"
elsedf2$stage[496:550]="a"
# plot the change in elasticities with different ammounts of migration
el = qplot(data=elsedf2, x=p12, y=elas, geom="line", color=stage, linetype = patch,
           xlab="proportion of juveniles moving to \nhigh predation patch (patch1)", ylab="elasticity of Ms to changes in life stage",
           main=paste("predation = ", pred))
el
}

# Plot the elasticities for each matrix entry over many 
# attractivenesses and predation rates
pred.5 = elsplot(pred=c(.5,1))
pred.5
pred.1 = elsplot(pred=c(.1,1))
pred.2 = elsplot(pred=c(.2,1))
pred.3 = elsplot(pred=c(.3,1))
pred.4 = elsplot(pred=c(.4,1))
pred.6 = elsplot(pred=c(.6,1))
pred.7 = elsplot(pred=c(.7,1))
pred.8 = elsplot(pred=c(.8,1))
pred.9 = elsplot(pred=c(.9,1))
pred1 = elsplot(pred=c(1,1))
pred1
# try keeping attractiveness equal and varying predation
elsplot2 = function(App) {
  i=seq(0,1, by=.1)
  run = aaply(i, 1, function(x){
    ru = replicate(100, bigrun(500, App1=App, pred=c(x, 1)))
    aaply(ru, 1:2, function(thingy) {sum(thingy)/100})
  },
              .parallel=T)
  
  # Data frame with the elasticity of each non-zero matrix entry
  elsdf = data.frame(pred=i,  f1=run[, 1,3], l1=run[, 2,1], j21=run[, 3,5], j11=run[, 3,2], a1=run[, 3,3], 
                     f2=run[, 4,6], l2=run[, 5,4], j12=run[, 6,2], j22=run[, 6,5], a2=run[, 6,6])
  library(reshape2)
  elsedf2 = melt(elsdf, id.vars=c("pred"), variable.name="stage",value.name="elas")
  elsedf2$patch = rep(NA, 110)
  elsedf2$stage = rep(NA, 110)
  elsedf2$patch[1:55] = "1"
  elsedf2$patch[56:110] = "2"
  elsedf2$stage[1:11]="f"
  elsedf2$stage[12:22]="l"
  elsedf2$stage[23:33]="j2"
  elsedf2$stage[34:44]="j1"
  elsedf2$stage[45:55]="a"
  elsedf2$stage[56:66]="f"
  elsedf2$stage[67:77]="l"
  elsedf2$stage[78:88]="j1"
  elsedf2$stage[89:99]="j2"
  elsedf2$stage[100:110]="a"
  # plot the change in elasticities with different ammounts of migration
  el = qplot(data=elsedf2, x=(1-pred)*100, y=elas, geom="line", color=stage, linetype = patch,
             xlab="predation rate", ylab="elasticity of Ms to changes in life stage",
             main=paste("appearence = ", App))
  el
}

app.equal = elsplot2(c(100, 100))
app.equal
app.10 =elsplot2(c(10, 100))

svg(file = "elasticitypred5.svg", width=5, height=3)
pred.5
dev.off()
