/***********************************************************
Created 3/4/2018 by NMiller
Objective - to create model to predict whether team 1 should beat team 2
***********************************************************/

drop table if exists train_headtohead;

/* step 1 - translate wteam/lteam to randomized team1/team2 */ 
create table max_row as
(select count(*)/2 as max_row from ncaa_tourney_results);

/* step 2 - create a unique game_id for each game. use as base structure to append additional data */
create table game_id as
select season::int::text||wteamid::int::text||lteamid::int::text as game_id
	,season
	,wteamid
	,lteamid
	,random() as rand_id
from ncaa_tourney_results;

/* step 3 - change wteam/lteam to team1 and team2 */
create table tourney_results_step1 as
select distinct game_id
	,season
	,wteamid as team1
	,lteamid as team2
	,rand_id
	,1 as team1_win
from game_id
order by rand_id 
limit (select max(max_row) from max_row);

create table tourney_results_step2 as
select distinct gi.game_id
	,gi.season
	,gi.lteamid as team1
	,gi.wteamid as team2
	,gi.rand_id
	,0 as team1_win
from game_id gi
left join tourney_results_step1 trs1 on gi.game_id = trs1.game_id
where trs1.game_id is null;

create table tourney_results_combined_staging as
select distinct game_id, season, team1, team2, random() as rand_id, team1_win from tourney_results_step1
union all
select distinct game_id, season, team1, team2, random() as rand_id, team1_win from tourney_results_step2;

/* step 4 - randomize the combined dataset. for fun. then drop rand_id */
create table tourney_results_combined as
select *
from tourney_results_combined_staging
order by rand_id;

alter table tourney_results_combined
drop column rand_id;

/* step 5 - add team name data */
create table tourney_results_combined_teamname as
select distinct game_id
	,season
	,team1
	,season::int::text||team1::int::text as team1seasonid
	,t1.teamname as team1_name
	,team2
	,season::int::text||team2::int::text as team2seasonid
	,t2.teamname as team2_name
	,team1_win
from tourney_results_combined trc
left join teams t1 on trc.team1 = t1.teamid
left join teams t2 on trc.team2 = t2.teamid;

/* step 6 - add tournament seed data */
create table tourney_results_combined_tourney_seeds as
select trct.*
	,nts1.seed as team1_seed_detail
	,right(left(nts1.seed,3),2)::int as team1_seed
	,nts1.seed as team2_seed_detail
	,right(left(nts2.seed,3),2)::int as team2_seed
from tourney_results_combined_teamname trct
left join ncaa_tourney_seeds nts1 on nts1.season = trct.season and nts1.teamid = trct.team1
left join ncaa_tourney_seeds nts2 on nts2.season = trct.season and nts2.teamid = trct.team2;

/* step 7 - add the round of the tournament */ 
create table tourney_round as
select distinct season::varchar||wteamid::varchar as wteamseasonid
	,season::varchar||lteamid::varchar as lteamseasonid
	,season::varchar||wteamid::varchar||lteamid::varchar as game_id1
	,season::varchar||lteamid::varchar||wteamid::varchar as game_id2
	,season
	,wteamid
	,lteamid
	,daynum
	,row_number() over(partition by season::varchar||wteamid::varchar order by season::varchar||wteamid::varchar||daynum) as round
from ncaa_tourney_results
order by season::varchar||wteamid::varchar;

/* step 8 - compile training dataset */
create table train_headtohead as
select trc.game_id
	,trc.season
	,trc.team1
	,trc.team1seasonid
	,trc.team1_name
	,trc.team1_seed_detail
	,trc.team2
	,trc.team2seasonid
	,trc.team2_name
	,trc.team2_seed_detail
	,trc.team1_seed
	,km1.tempo as team1_tempo
	,km1.adjtempo as team1_adjtempo
	,km1.oe as team1_oe
	,km1.adjoe as team1_adjoe
	,km1.de as team1_de
	,km1.adjde as team1_adjde
	,km1.adjem as team1_adjem
	,km1.efg_pct_off as team1_efg_pct_off
	,km1.to_pct_off as team1_to_pct_off
	,km1.or_pct_off as team1_or_pct_off
	,km1.ft_rate_off as team1_ft_rate_off
	,km1.efg_pct_def as team1_efg_pct_def
	,km1.to_pct_def as team1_to_pct_def
	,km1.or_pct_def as team1_or_pct_def
	,km1.ft_rate_def as team1_ft_rate_def
	,km1.size as team1_size
	,km1.hgteff as team1_hgteff
	,km1.exp as team1_exp
	,km1.bench as team1_bench
	,km1.fg2pct as team1_fg2pct
	,km1.fg3pct as team1_fg3pct
	,km1.ftpct as team1_ftpct
	,km1.blockpct as team1_blockpct
	,km1.f3grate as team1_f3grate
	,km1.arate as team1_arate
	,km1.stlrate as team1_stlrate
	,km1.oppfg2pct as team1_oppfg2pct
	,km1.oppfg3pct as team1_oppfg3pct
	,km1.oppftpct as team1_oppftpct
	,km1.oppblockpct as team1_oppblockpct
	,km1.oppf3grate as team1_oppf3grate
	,km1.opparate as team1_opparate
	,km1.oppstlrate as team1_oppstlrate
	,km1.defensivefingerprint team1_defensivefingerprint
	,km1.off_1 as team1_off_1
	,km1.off_2 as team1_off_2
	,km1.off_3 as team1_off_3
	,km1.def_1 as team1_def_1
	,km1.def_2 as team1_def_2
	,km1.def_3 as team1_def_3
	,trc.team2_seed
	,km2.tempo as team2_tempo
	,km2.adjtempo as team2_adjtempo
	,km2.oe as team2_oe
	,km2.adjoe as team2_adjoe
	,km2.de as team2_de
	,km2.adjde as team2_adjde
	,km2.adjem as team2_adjem
	,km2.efg_pct_off as team2_efg_pct_off
	,km2.to_pct_off as team2_to_pct_off
	,km2.or_pct_off as team2_or_pct_off
	,km2.ft_rate_off as team2_ft_rate_off
	,km2.efg_pct_def as team2_efg_pct_def
	,km2.to_pct_def as team2_to_pct_def
	,km2.or_pct_def as team2_or_pct_def
	,km2.ft_rate_def as team2_ft_rate_def
	,km2.size as team2_size
	,km2.hgteff as team2_hgteff
	,km2.exp as team2_exp
	,km2.bench as team2_bench
	,km2.fg2pct as team2_fg2pct
	,km2.fg3pct as team2_fg3pct
	,km2.ftpct as team2_ftpct
	,km2.blockpct as team2_blockpct
	,km2.f3grate as team2_f3grate
	,km2.arate as team2_arate
	,km2.stlrate as team2_stlrate
	,km2.oppfg2pct as team2_oppfg2pct
	,km2.oppfg3pct as team2_oppfg3pct
	,km2.oppftpct as team2_oppftpct
	,km2.oppblockpct as team2_oppblockpct
	,km2.oppf3grate as team2_oppf3grate
	,km2.opparate as team2_opparate
	,km2.oppstlrate as team2_oppstlrate
	,km2.defensivefingerprint team2_defensivefingerprint
	,km2.off_1 as team2_off_1
	,km2.off_2 as team2_off_2
	,km2.off_3 as team2_off_3
	,km2.def_1 as team2_def_1
	,km2.def_2 as team2_def_2
	,km2.def_3 as team2_def_3
	,case when tr1.round = 1 then 1 when tr2.round = 1 then 1 else 0 end as is_round1
	,case when tr1.round = 2 then 1 when tr2.round = 2 then 1 else 0 end as is_round2
	,case when tr1.round = 3 then 1 when tr2.round = 3 then 1 else 0 end as is_round3
	,case when tr1.round = 4 then 1 when tr2.round = 4 then 1 else 0 end as is_round4
	,case when tr1.round = 5 then 1 when tr2.round = 5 then 1 else 0 end as is_round5
	,case when tr1.round = 6 then 1 when tr2.round = 6 then 1 else 0 end as is_round6
	,trc.team1_win
from tourney_results_combined_tourney_seeds trc
left join kenpom_master km1 on trc.team1seasonid = km1.teamseasonid
left join kenpom_master km2 on trc.team2seasonid = km2.teamseasonid
left join tourney_round tr1 on trc.game_id = tr1.game_id1
left join tourney_round tr2 on trc.game_id = tr2.game_id2;

drop table max_row;
drop table game_id;
drop table tourney_results_step1;
drop table tourney_results_step2;
drop table tourney_results_combined_staging;
drop table tourney_results_combined;
drop table tourney_round;
drop table tourney_results_combined_teamname;
drop table tourney_results_combined_tourney_seeds;

/* LIU Brooklyn games not populating with kenpom data so deleting */
delete from train_headtohead where team1_efg_pct_off is null;
delete from train_headtohead where team2_efg_pct_off is null;

/* export file */
copy train_headtohead to '/Users/ntmill/Library/Mobile Documents/com~apple~CloudDocs/Projects/March Madness/2018/data/train_headtohead.csv' delimiter ',' csv header;

