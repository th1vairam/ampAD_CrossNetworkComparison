#!usr/bin/env Rscript

# Submission Script in R
# Clear R console screen output
cat("\014")

# Clear R workspace
setwd('/home/ec2-user/Work/Github/ampAD_CrossNetworkComparison/code/R')

# Load libraries
library(synapseClient)
library(dplyr)
library(data.table)

# login to synapse
synapseLogin()

# Get all files and folder
Module.Files = synQuery('select * from file where projectId=="syn4907617" and methodName == "MEGENA" and dataType == "Modules"') %>%
	dplyr::mutate(uniqueName = paste(file.brainRegion, file.disease, sep='.'))
Enrich.Files = synQuery('select * from file where projectId=="syn4907617" and methodName == "MEGENA" and dataType == "Enrichment"')  %>%
	dplyr::mutate(uniqueName = paste(file.brainRegion, file.disease, sep='.'))

Module.Files = Module.Files %>% dplyr::filter( Module.Files$uniqueName %in% setdiff(Module.Files$uniqueName, Enrich.Files$uniqueName))

# Make directory and write shell scripts for running these files
system('mkdir sgeEnrichSub')
fp_all = file(paste('./sgeEnrichSub/allSubmissions.sh'),'w+')    
cat('#!/bin/bash',file=fp_all,sep='\n')
close(fp_all)
for (id in Module.Files$file.id){
  fp = file (paste('/home/ec2-user/Work/Github/ampAD_CrossNetworkComparison/code/R/sgeEnrichSub/SUB',id,sep='.'), "w+")
  cat('#!/bin/bash', 
      'sleep 30', 
      paste('Rscript /home/ec2-user/Work/Github/ampAD_CrossNetworkComparison/code/R/enrichMEGENAModules.R',id), 
      file = fp,
      sep = '\n')
  close(fp)
  
  fp_all = file(paste('./sgeEnrichSub/allSubmissions.sh'),'a+')    
  cat(paste('qsub','-cwd','-V',paste('/home/ec2-user/Work/Github/ampAD_CrossNetworkComparison/code/R/sgeEnrichSub/SUB',id,sep='.'),
            '-o',paste('/home/ec2-user/Work/Github/metanetwork/R/sgeEnrichSub/SUB',id,'o',sep='.'),
            '-e',paste('/home/ec2-user/Work/Github/metanetwork/R/sgeEnrichSub/SUB',id,'e',sep='.'),
            '-l mem=7GB'),
      file=fp_all,
      sep='\n')
  close(fp_all)
}
