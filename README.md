# march_madness

Summary

  Building a model to predict 2018 NCAA Tournament results for the 2018 Kaggle March Madness competition (https://www.kaggle.com/c/mens-machine-learning-competition-2018) and potentially other competitions.

Data

  NCAA regular season, conference play, and tournament results data provided by the Kaggle website. Supplemental data was purchased from kenpom.com via a subscription. Data is not posted to GitHub and instead resides on a private hard drive. Each Kenpom dataset was downloaded from 2003-2017, combined into a single csv per dataset, and each loaded into a private PostgreSQL database. Each dataset is described below.

  There are two model training datasets created. They have most all possible data in the underlying raw tables included. Those datasets were created, cleaned, and combined in PostgreSQL. The code is included in my Github repo.

  Kaggle data

    conference_tourney_games - a summary of historical conference tournament game results
    ncaa_tourney_results - results of historical NCAA tournament conference_tourney_games
    ncaa_tourney_seeds - by season, seeds by teamid
    ncaa_tourney_slots - by season, the strong seed vs. weak seed
    regular_season_compact_results - the results of each regular season conference_tourney_games
    teams - an ID and team name for each team

  Kenpom Data, each by team+season

    kenpom_master - blended all the below kenpom datasets into one master table by team and regular_season_compact_results
    kenpom_fourfactor_off - the kenpom four factor offensive statistics
    kenpom_fourfactor_def - the kenpom four factor defensive statistics
    kenpom_heightexp - only starting in 2008, the height by team and position along with relative experience
    kenpom_misc - some additional misc statistics
    kenpom_pointdist - offensive and defensive 1, 2, and 3 point totals

  Created Data

    teams_final - updated teams table to
    final_four - just looked up on Wikipedia the Final Four teams from each year
    train_finalfour_wins - training dataset compiled from mostly kenpom data to predict whether a team will make the final four,   how many wins in the tournament they will have, and whether they will survive round X in the Tournament.
    train_headtohead - training dataset to predict whether one team will beat another in the NCAA tournament. Takes historical NCAA tournament results with kenpom regular season data for each team.

Code

  kenpom_master - combine all the kenpom datasets into a master dataset by team+season combo
  update_tables - reformatting kenpom dataset column names to be lowercased so Postgres code isn't quite as annoying
  train_headtohead - building the model training set above
  train_wins_ff - building the model training set above
