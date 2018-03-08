####################################################################
####################################################################
####################################################################
# 2018 NCAA College Basketball Tournament Model
# Created by NMiller 3/6/2018
# Data compiled in a local PostgreSQL database, using data provided
#     by Kaggle combined with downloaded data from kenpom.com
#
# Two models being built: 
#     1. How far will the team make it in the tourney
#     2. Will team A beat team B in the tourney
#
# The final model will be an ensemble of this output
####################################################################
####################################################################
####################################################################

###############################
# step 1 - load libraries and data
###############################
rm(list=ls())
setwd('/Users/ntmill/Library/Mobile Documents/com~apple~CloudDocs/Projects/March Madness/2018/data/')
library(stats)
library(randomForest)
library(caret)
library(ModelMetrics)

# load training dataset to predict probability of making the final four, etc.
orig_ff <- read.csv('train_finalfour_wins.csv',header=TRUE)
ff_rm_var <- c('size','hgteff','exp','bench')
ff <- orig_ff[,!(colnames(orig_ff) %in% ff_rm_var)]
ff_xvar <- colnames(ff[,which(colnames(ff)=='tempo'):which(colnames(ff)=='conf_tourney_wins')])
ff <- cbind(ff$season,ff[,ff_xvar],ff$tourney_wins)
colnames(ff)[1] <- 'season'
colnames(ff)[ncol(ff)] <- 'tourney_wins'

summary(ff)

train_ff <- ff[which(ff$season < 2017),]
train_ff <- train_ff[,-which(names(train_ff) == 'season')]
test_ff <- ff[which(ff$season == 2017),]
test_ff <- test_ff[,-which(names(test_ff) == 'season')]

# load training dataset to predict probability of team A beating team B
orig_head <- read.csv('train_headtohead.csv',header=TRUE)
head_rm_var <- c('team1_size','team1_hgteff','team1_exp','team1_bench','team2_size','team2_hgteff','team2_exp','team2_bench')
head_new <- orig_head[,!(colnames(orig_head) %in% head_rm_var)]
head_xvar <- colnames(head_new[,which(colnames(head_new)=='team1_seed'):which(colnames(head_new)=='team2_def_3')])
head <- cbind(head_new$season,head_new[,head_xvar],head_new$team1_win)
colnames(head)[1] <- 'season'
colnames(head)[ncol(head)] <- 'team1_win'

#sample_size <- floor(0.75*nrow(head))
#set.seed(1234)
#head_samp <- sample(seq_len(nrow(head)), size=sample_size)
#train_head <- cbind(head[,head_xvar],head$team1_win)
#colnames(train_head)[ncol(train_head)] <- 'team1_win'
#train_head <- as.data.frame(train_head[head_samp,])
#test_head <- as.data.frame(train_head[-head_samp,])

train_head_setup <- head[which(head$season < 2017),]
train_head <- train_head_setup[,-which(names(train_head_setup) == 'season')]
test_head_setup <- head[which(head$season == 2017),]
test_head <- test_head_setup[,-which(names(test_head_setup) == 'season')]

###############################
# step 2 - head to head model
###############################

rf_var <- c('team1_adjem','team2_adjem','team1_adjoe','team2_adjoe','team1_adjde','team2_adjde',
            'team1_seed','team2_seed','team1_win')
rf <- randomForest(team1_win~.,train_head[,rf_var],type='classification',ntree=1000)
rf_pred <- predict(rf,newdata=test_head)

###############################
# step 3 - final four model
###############################

rf_wins <- randomForest(tourney_wins~.,data=train_ff,ntree=500,type='regression')

