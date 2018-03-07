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
library('stats')
library('randomForest')
