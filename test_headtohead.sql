/***********************************************************
Created 3/12/2018 by NMiller
Objective - to create the final predictions for 2018 march madness
***********************************************************/

drop table if exists test_headtohead;

-- select all teams from 2018
create table tourney_teams1 as
select distinct nts.season
	,nts.teamid
	,t.teamname
from ncaa_tourney_seeds nts
left join teams t on nts.teamid = t.teamid
where season = 2018;

create table tourney_teams2 as
select distinct nts.season
	,nts.teamid
	,t.teamname
from ncaa_tourney_seeds nts
left join teams t on nts.teamid = t.teamid
where season = 2018;

-- combine each so that you get every possible combination for this tournament
create table submission_start as
select distinct x.season::varchar||x.team1::varchar||x.team2::varchar as game_id
	,x.season || '_' || x.team1 || '_' || x.team2 as game_id_submit
	,x.season as season
	,x.team1
	,x.season::varchar||x.team1 as team1seasonid
	,x.team1_name
	,x.team2
	,x.season::varchar||x.team2 as team2seasonid
	,x.team2_name
from (
select *
from (select * from (select distinct season, teamid as team1, teamname as team1_name from tourney_teams1) t1
left outer join (select distinct teamid as team2, teamname as team2_name from tourney_teams2) as t2 on t1.team1 < t2.team2) t3
where t3.team2 is not null
) x;

create table idx_adjem as
select distinct teamseasonid
	,season
	,teamid
	,adjem
	,(select min(adjem) from kenpom_master) as min_adjem
	,(select max(adjem) from kenpom_master) as max_adjem
	,(adjem-(select min(adjem) from kenpom_master))/((select max(adjem) from kenpom_master)-(select min(adjem) from kenpom_master)) as idx_adjem
from kenpom_master;

create table adj_wins as
select distinct rsr.season::varchar||rsr.wteamid as teamseasonid
	,rsr.season
	,rsr.wteamid as teamid
	,t.teamname
	,sum(case when idxl.idx_adjem is null then 0 else idxl.idx_adjem end) as adj_wins
from reg_season_results rsr
inner join teams t on rsr.wteamid = t.teamid
left join idx_adjem idxw on rsr.season=idxw.season and rsr.wteamid = idxw.teamid
left join idx_adjem idxl on rsr.season=idxl.season and rsr.lteamid = idxl.teamid
group by rsr.season::varchar||rsr.wteamid
	,rsr.season
	,rsr.wteamid
	,t.teamname;

/*
Step 3 - add kenpom data
*/

-- populate with kenpom team names
create table test_headtohead as
select distinct s.*
	,right(left(nts1.seed,3),2)::int as team1_seed
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
	,km1.defensivefingerprint as team1_defensivefingerprint
	,km1.off_1 as team1_off_1
	,km1.off_2 as team1_off_2
	,km1.off_3 as team1_off_3
	,km1.def_1 as team1_def_1
	,km1.def_2 as team1_def_2
	,km1.def_3 as team1_def_3
	,aw1.adj_wins as team1_adj_wins
	,right(left(nts2.seed,3),2)::int as team2_seed
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
	,km2.defensivefingerprint as team2_defensivefingerprint
	,km2.off_1 as team2_off_1
	,km2.off_2 as team2_off_2
	,km2.off_3 as team2_off_3
	,km2.def_1 as team2_def_1
	,km2.def_2 as team2_def_2
	,km2.def_3 as team2_def_3
	,aw2.adj_wins as team2_adj_wins
from submission_start as s
left join kenpom_master km1 on s.team1seasonid = km1.teamseasonid
inner join teams t1 on km1.teamid = t1.teamid
inner join ncaa_tourney_seeds nts1 on t1.teamid = nts1.teamid and km1.season = nts1.season
inner join adj_wins aw1 on km1.teamid = aw1.teamid and km1.season = aw1.season
left join kenpom_master km2 on s.team2seasonid = km2.teamseasonid
inner join teams t2 on km2.teamid = t2.teamid
inner join ncaa_tourney_seeds nts2 on t2.teamid = nts2.teamid and km2.season = nts2.season
inner join adj_wins aw2 on km2.teamid = aw2.teamid and km2.season = aw2.season;

copy test_headtohead to '/Users/ntmill/Library/Mobile Documents/com~apple~CloudDocs/Projects/March Madness/2018/data/test_headtohead.csv' delimiter ',' csv header;

drop table tourney_teams1;
drop table tourney_teams2;
drop table submission_start;
drop table idx_adjem;
drop table adj_wins;
drop table test_headtohead;
