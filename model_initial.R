####################################################################
####################################################################
####################################################################
# 2018 NCAA College Basketball Tournament Model
# Created by NMiller 3/6/2018, finished on 3/15/2018
# Data compiled in a local PostgreSQL database, using data provided
#     by Kaggle combined with downloaded data from kenpom.com
#
# Two models being built: 
#     1. How far will the team make it in the tourney
#     2. Will team A beat team B in the tourney (primary focus)
#
# The first model helps determine what variables determine which teams make a deep run
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
library(sqldf)
library(xgboost)

# load training dataset to predict probability of making the final four, etc.
orig_ff <- read.csv('train_finalfour_wins.csv',header=TRUE)
ff_rm_var <- c('size','hgteff','exp','bench')
ff <- orig_ff[,!(colnames(orig_ff) %in% ff_rm_var)]
ff_var <- colnames(ff[,which(colnames(ff)=='tempo'):which(colnames(ff)=='conf_tourney_wins')])
ff_var[40] <- 'tourney_wins'

set.seed(1234)
sample_size <- floor(0.66*nrow(ff))
ff_samp <- sample(seq_len(nrow(ff)), size=sample_size)
train_ff <- as.data.frame(ff[ff_samp,])
test_ff <- as.data.frame(ff[-ff_samp,])

# load final testing dataset
submit_orig <- read.csv('test_headtohead.csv',header=TRUE)

# load training dataset to predict probability of team A beating team B
orig_head <- read.csv('train_headtohead.csv',header=TRUE)
head_rm_var <- c('team1_size','team1_hgteff','team1_exp','team1_bench','team2_size','team2_hgteff','team2_exp','team2_bench')
head <- orig_head[,!(colnames(orig_head) %in% head_rm_var)]
head_var <- colnames(head_new[,which(colnames(head_new)=='team1_seed'):which(colnames(head_new)=='team2_adj_wins')])
head_var[79] <- 'team1_win'

###############################
# step 2 - predict number of tourney wins
###############################
rf_wins <- randomForest(tourney_wins~.,data=train_ff[,ff_var],type='regression') 
# used variable imporance to selec the variables below
rf_wins <- randomForest(tourney_wins~adjem+seed+adj_wins+adjoe+adjde+or_pct_off+blockpct,data=train_ff[,ff_var],type='regression') 
rf_wins_pred <- predict(rf_wins,test_ff[,ff_var])
rmse(rf_wins_pred,test_ff$tourney_wins)

# stopping here. ran into challenges with implementing this model in the final head to head model

###############################
# step 3 - head to head model
###############################

train_head <- head[which(head$season < 2017),]
test_head <- head[which(head$season == 2017),]
#'team1_seed','team2_seed',
rf_var <- c('team1_adjem','team2_adjem','team1_adjoe','team2_adjoe','team1_adjde','team2_adjde',
            'team1_adj_wins','team2_adj_wins','team1_or_pct_off','team2_or_pct_off',
            'team1_blockpct','team2_blockpct','team1_win')
model_control <- trainControl(method='repeatedcv',number=5,repeats=3)
mtry <- sqrt(ncol(train_head[,rf_var]))
tunegrid <- expand.grid(.mtry=mtry)
rf_random <- train(team1_win~.,data=train_head[,rf_var],method='rf',metric='logloss',tuneLenth=15,
                   tunegrid=tunegrid, trControl=model_control,verbose=TRUE,modelType='classification')
rf_pred <- predict(rf_random,test_head[,rf_var])
rf_log <- logLoss(rf_pred,test_head$team1_win)

# set up the cross-validated hyper-parameter search
xgb.grid <- expand.grid(
  nrounds = c(50,100,500),
  eta = c(0.1,0.01,0.001),
  max_depth = c(2,4,6,8),
  gamma = c(0,1,3,5),
  min_child_weight = c(0,1,3,5),
  colsample_bytree = c(0.5,0.75,1),
  subsample = c(0.5,0.75,1)
  )

# pack the training control parameters
xgb.trcontrol <- trainControl(
  method = "cv",
  number = 3,
  search = 'grid',
  verboseIter = TRUE,
  returnData = FALSE,
  returnResamp = "all",                                                        # save losses across all models
  classProbs = TRUE,                                                           # set to TRUE for AUC to be computed
  summaryFunction = twoClassSummary,
  allowParallel = TRUE
)

xvar <- train_head[,rf_var]
xvar <- xvar[,which(colnames(xvar) != 'team1_win')]

# train the model for each parameter combination in the grid,
#   using CV to evaluate
xgb.train <- train(
  x = data.matrix(xvar),
  y = make.names(train_head$team1_win),
  trControl = xgb.trcontrol,
  tuneGrid = xgb.grid,
  method = "xgbTree",
  verbose = TRUE
  )

xgb_param <- list("objective" = "binary:logistic",
              "nrounds" = 100,
              "nthread" = 3,
              "eta" = 0.01, 
              "gamma" = 3,
              "min_child_weight" = 3,
              "subsample"=0.5,
              "max_depth"= 8,
              "colsample_bytree" = 1)

test_xvar <- test_head[,which(colnames(test_head) != 'team1_win')]

xgb <- xgboost(param=param, data=data.matrix(xvar), label=train_head$team1_win,nrounds=100,eval_metric="logloss")
xgbpreds <- predict(xgb, newdata=data.matrix(test_xvar))
xgb_log <- logLoss(xgbpreds,test_head$team1_win)

###############################
# step 4 - final predictions
###############################

train_sub <- head[which(head$season <= 2017),]
test_sub <- submit_orig

rf_submit <- train(team1_win~.,data=train_sub[,rf_var],method='rf',metric='logloss',tuneLenth=15,
                   tunegrid=tunegrid, trControl=model_control,verbose=TRUE,modelType='classification')
rf_pred_sub <- predict(rf_submit,test_sub[,rf_var[1:12]])

View(as.data.frame(rf_pred_sub))
write.csv(test_sub,'test_sub_v3.csv')

data.matrix(train_sub[1:92])
data.matrix(train_sub[,rf_var][,1:12])
     
xgb_sub <- xgboost(param=param, data=data.matrix(train_sub[,rf_var][,1:12]), label=train_sub$team1_win,nrounds=100,eval_metric="logloss")
xgb_pred_sub <- predict(xgb_sub, newdata=data.matrix(test_sub[,rf_var[1:12]]))

write.csv(as.data.frame(xgb_pred_sub),'xgb_pred.csv')
write.csv(as.data.frame(rf_pred_sub),'rf_pred_v3.csv')

# create final prediction file
final_pred <- cbind(test_sub$game_id_submit,as.data.frame(rf_pred_sub))
colnames(final_pred) <- c('ID','Pred')
write.csv(final_pred,'final_pred.csv',row.names=FALSE)

final_pred_xgb <- cbind(test_sub$game_id_submit,as.data.frame(xgb_pred_sub))
colnames(final_pred_xgb) <- c('ID','Pred')
write.csv(final_pred_xgb,'final_pred_xgb.csv',row.names=FALSE)
