#!/usr/bin/env/Rscript
#$ -S /usr/local/packages/R-3.2.1/bin/Rscript
#$ -l h_rt=04:00:00
#$ -t 1-384
#$ -cwd

# Code to run on Buster
# Ruth Harbord
# 04/02/2015 (date submitted to Buster)


#####################################################################################################
# A FUNCTION TO CALCULATE THE FILTERING DISTRIBUTION FOR A SPECIFIED SET OF PARENTS AND A FIXED DELTA
#####################################################################################################

# INPUTS:
# Yt = the time series of the node of interest (dim = Nt)
# Ft = the time series of the parents (number of parents = p), and 1 for the intercept (dim = p x Nt)
# delta = the discount factor (scalar)

# PRIORS
# m0 = the prior means at time t=0 with length p. The default is non-informative prior, with zero mean.
# CS0 = the squared matrix of prior variance. The default is non-informative prior, with prior variance equal to 3 times the observed variance.
# n0 and d0 = the prior hypermarameters of precision phi ~ G(n0/2; d0/2). The default is non-informative priors, with value of 0.001. n0 has to be higher than 0.

# Gt is assumed to be the indentity matrix, so is not coded in specifically here.

# OUTPUTS:
# mt = the filtered posterior mean, dim = p x T
# Ct = the filtered posterior variance, dim = p x p x T
# CSt
# Rt = the prior variance, dim = p X p X T
# RSt
# nt and dt = the prior hypermarameters of precision phi with length T
# ft = the one-step forecast mean with length T
# Qt = the one-step forecast variance with length T
# ets = the standardised residuals with length T
# lpl = Log Predictive Likelihood with length T

dlm.filt.rh <- function(Yt, Ft, delta, m0 = numeric(nrow(Ft)), CS0 = 3*diag(nrow(Ft)), n0 = 0.001, d0 = 0.001){
  
  Nt = length(Yt)+1 # the length of the time series + t0
  p = nrow(Ft)      # the number of parents and one for an intercept (i.e. the number of thetas)
  
  Y = numeric(Nt)
  Y[2:Nt] = Yt
  
  F1 = array(0, dim=c(p,Nt))
  F1[,2:Nt] = Ft
  
  # Set up allocation matrices, including the priors
  mt = array(0,dim=c(p,Nt))
  mt[,1]=m0
  
  Ct = array(0,dim=c(p,p,Nt))
  Ct[,,1] = CS0
  CSt = array(0,dim=c(p,p,Nt))
  
  Rt = array(0,dim=c(p,p,Nt))
  RSt = array(0,dim=c(p,p,Nt))
  
  nt = numeric(Nt) 
  nt[1]=n0
  
  dt = numeric(Nt)
  dt[1]=d0
  
  S = numeric(Nt)
  S[1]=dt[1]/nt[1]
  
  ft = numeric(Nt)
  Qt = numeric(Nt)
  ets = numeric(Nt)
  lpl = numeric(Nt)
  
  # Filtering
  
  for (t in 2:Nt){
    
    # Posterior at {t-1}: (theta_{t-1}|y_{t-1}) ~ T_{n_{t-1}}[m_{t-1}, C_{t-1} = C*_{t-1} x d_{t-1}/n_{t-1}]
    # Prior at {t}: (theta_{t}|y_{t-1}) ~ T_{n_{t-1}}[m_{t}, R_{t}]
    
    # RSt ~ C*_{t-1}/delta
    RSt[,,t] = Ct[,,(t-1)] / (S[(t-1)]*delta)
    Rt[,,t] = RSt[,,t] * (S[(t-1)]) 
    
    # One-step forecast: (Y_{t}|y_{t-1}) ~ T_{n_{t-1}}[f_{t}, Q_{t}]
    ft[t] = t(F1[,t]) %*% mt[,(t-1)] # simon
    #ft[t] = F1[,t] %*% mt[,(t-1)]
    QSt = as.vector(1 + t(F1[,t]) %*% RSt[,,t] %*% F1[,t])
    #QSt = as.vector(1 + F1[,t] %*% RSt[,,t] %*% F1[,t])
    Qt[t] = QSt * S[(t-1)]
    et = Y[t] - ft[t]
    ets[t] = et / sqrt(Qt[t])
    
    # Posterior at t: (theta_{t}|y_{t}) ~ T_{n_{t}}[m_{t}, C_{t}]
    At = (RSt[,,t] %*% F1[,t])/QSt
    mt[,t] = mt[,(t-1)] + (At*et)
    
    nt[t] = nt[(t-1)] + 1
    dt[t] = dt[(t-1)] + (et^2)/QSt
    S[t]=dt[t]/nt[t] 
    
    CSt[,,t] = RSt[,,t] - (At %*% t(At))*QSt
    Ct[,,t] = S[t]*CSt[,,t]
    
    # Log Predictive Likelihood (degrees of freedom = nt[(t-1)], not nt[t])
    lpl[t] = lgamma((nt[(t-1)]+1)/2)-lgamma(nt[(t-1)]/2)-0.5*log(pi*nt[(t-1)]*Qt[t])-((nt[(t-1)]+1)/2)*log(1+(1/nt[(t-1)])*et^2/Qt[t])} # Ruth
  #lpl[t] <- lgamma((nt[t]+1)/2)-lgamma(nt[t]/2)-0.5*log(pi*nt[t]*Qt[t])-((nt[t]+1)/2)*log(1+(1/nt[t])*et^2/Qt[t])} # Lilia
  
  mt = mt[,2:Nt]; Ct = Ct[,,2:Nt]; CSt = CSt[,,2:Nt]; Rt = Rt[,,2:Nt]; RSt = RSt[,,2:Nt]
  nt = nt[2:Nt]; dt = dt[2:Nt]; S = S[2:Nt]; ft = ft[2:Nt]; Qt = Qt[2:Nt]; ets = ets[2:Nt]; lpl = lpl[2:Nt]
  
  filt.output <- list(mt=mt,Ct=Ct,CSt=CSt,Rt=Rt,RSt=RSt,nt=nt,dt=dt,S=S,ft=ft,Qt=Qt,ets=ets,lpl=lpl)
  return(filt.output)}

dlm.filt <- cmpfun(dlm.filt.rh)

###############################################################################################
# A function to generate all the possible models. 
###############################################################################################

# Inputs:
# nn = the number of nodes; the number of columns of the dataset can be used
# node = the node of interest (i.e. the node to find parents for)

# Outputs:
# output.model = a matrix with dimensions (nn-1) x number of models, where number of models = 2^(nn-1)

model.generator<-function(Nn,node){
  
  # Create the model 'no parents' (the first column of the matrix is all zeros)
  empt=rep(0,(Nn-1)) 
  
  for (k in 1:(Nn-1)) {
    
    # Calculate all combinations when number of parents = k
    #m=combn(c(1:Nn)[-node],k)
    if (Nn==2 & node==1) {
      model = matrix(c(0,2),1,2)
    } else { 
      m=combn(c(1:Nn)[-node],k) 
      
      # Expand the array so that unconnected edges are represented by zeros  
      empt.new=array(0,dim=c((Nn-1),ncol(m)))
      empt.new[1:k,]=m
      
      # Bind the matrices together; the next set of models are added to this matrix
      model=cbind(empt,empt.new)
      empt=model
    } 
  }
  
  colnames(model)=NULL
  output.model<-model
  
  return(output.model)
  
}


###############################################################################################
# A function for an exhaustive search, calculates the optimum value of the discount factor
###############################################################################################

# Inputs: 
# Data = Dataset with dimension number of time points Nt x Number of nodes Nn
# node = the node of interest
# nbf = the Log Predictive Likelihood will be calculated from this time point. 
#       It has to be a positive integer number. The default is 15.
# delta = a vector of potential values for the discount factor

# Outputs:
# model.store = a matrix with the model, LPL and chosen discount factor for all possible models

exhaustive.search <- function(Data,node,nbf=15,delta=seq(0.5,1,0.01)) {
  
  ptm=proc.time()  
  
  Nn=ncol(Data) # the number of nodes
  Nm=2^(Nn-1)   # the number of models per node
  
  M=model.generator(Nn,node) # Generate all the possible models
  #M=cbind(M,M[,1]) # Add in a model to represent the AR alternative
  models=rbind(1:Nm,M) # Label each model with a 'model number'
  
  
  # Find the Log Predicitive Likelihood and associated discount factor for the zero parent model
  Yt=Data[,node]    # the time series of the node we wish to find parents for
  Nt=length(Yt)     # the number of time points
  nd=length(delta)  # the number of deltas
  
  # Create empty arrays for the lpl scores and the optimum deltas
  lpldet=array(NA,c(Nm,length(delta)))
  lplmax=rep(NA,Nm)
  DF.hat=rep(NA,Nm)
  
  # Now create Ft. 
  for (z in 1:Nm) {
    par=models[(2:Nn),z] # par is distinguished from pars, which are the selected parents at each stage
    par=par[par!=0]
    Ft=array(1,dim=c(Nt,length(par)+1))
    if (ncol(Ft)>1) {
      Ft[,2:ncol(Ft)]=Data[,par]
    }  
    
    # Calculate the log predictive likelihood, for each value of delta, for the specified models
    for (j in 1:nd) {
      a=dlm.filt(Yt, t(Ft), delta=delta[j])
      lpldet[z,j]=sum(a$lpl[nbf:Nt]) 
    }
    
    lplmax[z]=max(lpldet[z,],na.rm=TRUE)
    DF.hat[z]=delta[lpldet[z,]==max(lpldet[z,],na.rm=TRUE)]
  }
  
  
  # Output model.store
  model.store=rbind(models,lplmax,DF.hat)
  rownames(model.store)=NULL
  
  runtime=(proc.time()-ptm)
  
  output<-list(model.store=model.store,runtime=runtime)    
  return(output)
}


#########################################################################################
# Run the code
# run=as.numeric(Sys.getenv('SGE_TASK_ID')) # Use the task ID to run the code in parallel
#   
# load("Data_NS.Rda") # A list object, as the number of time points differs between subjects
# Data=Data_NS
#   
# Ns=dim(Data)[1]
# Nn=dim(Data)[3]
#   
# subj=as.vector(t(matrix(rep(1:Ns,Nn),Ns,Nn)))
# nodes=rep(1:Nn,Ns)
#   
# model.set=exhaustive.search(Data=Data[subj[run],,],node=nodes[run],nbf=15,delta=seq(0.5,1,0.01))
# write.table(model.set$model.store,file=paste("NS_redone_subj",subj[run],"_n_",nodes[run],".txt",sep=""))
# write.table(model.set$runtime[3],file=paste("NS_redone_subj",subj[run],"_n_",nodes[run],"_run_time.txt",sep=""))
#  