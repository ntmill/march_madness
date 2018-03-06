/*******************************************************************
Created 3/4/2018 by NMiller
Objective - to compile historical ncaa tournament results to predict #wins and prob of final four
*******************************************************************/

drop table train_finalfour_wins;

create table team_tournament_setup as
select distinct x.season::varchar||x.teamid::varchar as teamseasonid
	,x.season
	,x.teamid
from (
	select distinct season, wteamid as teamid from ncaa_tourney_results
	union all
	select distinct season, lteamid as teamid from ncaa_tourney_results
) x;

create table wins as
select season::varchar||wteamid::varchar as teamseasonid
	,count(*) as wins 
from ncaa_tourney_results 
group by season::varchar||wteamid::varchar;

create table losses as
select season::varchar||lteamid::varchar as teamseasonid
	,count(*) as losses 
from ncaa_tourney_results 
group by season::varchar||lteamid::varchar;

create table final_four_teams_id as
select distinct *
	,season::varchar||teamid::varchar as teamseasonid
from final_four_teams;

create table wins_finalfour_setup as
select distinct tts.teamseasonid
	,tts.season
	,tts.teamid
	,case when w.wins is not null then w.wins else 0 end as wins
	,case when ff.teamseasonid is not null then 1 else 0 end as final_four
from team_tournament_setup tts
left join wins w on tts.teamseasonid = w.teamseasonid
left join losses l on tts.teamseasonid = l.teamseasonid
left join final_four_teams_id ff on tts.teamseasonid = ff.teamseasonid;

create table conf_tourney_setup as
select distinct x.season::varchar||x.teamid::varchar as teamseasonid
	,x.season
	,x.teamid
from (
	select distinct season, wteamid as teamid from conf_tourney_results
	union all
	select distinct season, lteamid as teamid from conf_tourney_results
) x;

create table conf_wins as
select season::varchar||wteamid::varchar as teamseasonid
	,count(*) as wins 
from conf_tourney_results 
group by season::varchar||wteamid::varchar;

create table conf_tourney_wins as
select distinct cts.teamseasonid
	,cts.season
	,cts.teamid
	,case when w.wins is not null then w.wins else 0 end as conf_tourney_wins
from conf_tourney_setup cts
left join conf_wins w on cts.teamseasonid = w.teamseasonid;

create table train_finalfour_wins as
select distinct wffs.teamseasonid
	,wffs.season
	,wffs.teamid
	,km.teamname
	,km.tempo
	,km.adjtempo
	,km.oe
	,km.adjoe
	,km.de
	,km.adjde
	,km.adjem
	,km.efg_pct_off
	,km.to_pct_off
	,km.or_pct_off
	,km.ft_rate_off
	,km.efg_pct_def
	,km.to_pct_def
	,km.or_pct_def
	,km.ft_rate_def
	,km.size
	,km.hgteff
	,km.exp
	,km.bench
	,km.fg2pct
	,km.fg3pct
	,km.ftpct
	,km.blockpct
	,km.f3grate
	,km.arate
	,km.stlrate
	,km.oppfg2pct
	,km.oppfg3pct
	,km.oppftpct
	,km.oppblockpct
	,km.oppf3grate
	,km.opparate
	,km.oppstlrate
	,km.defensivefingerprint
	,km.off_1
	,km.off_2
	,km.off_3
	,km.def_1
	,km.def_2
	,km.def_3
	,right(left(nts.seed,3),2)::int as seed
	,ctw.conf_tourney_wins
	,wffs.wins as tourney_wins
	,wffs.final_four
	,case when wffs.wins >= 1 then 1 else 0 end as won_round1
	,case when wffs.wins >= 2 then 1 else 0 end as won_round2
	,case when wffs.wins >= 3 then 1 else 0 end as won_round3
	,case when wffs.wins >= 4 then 1 else 0 end as won_round4
	,case when wffs.wins >= 5 then 1 else 0 end as won_round5
	,case when wffs.wins >= 6 then 1 else 0 end as won_round6
from wins_finalfour_setup wffs
left join kenpom_master km on wffs.teamseasonid = km.teamseasonid
left join conf_tourney_wins ctw on wffs.teamseasonid = ctw.teamseasonid
left join ncaa_tourney_seeds nts on wffs.teamseasonid = nts.season::varchar||nts.teamid::varchar
where km.teamname is not null;

drop table team_tournament_setup;
drop table wins;
drop table losses;
drop table final_four_teams_id;
drop table wins_finalfour_setup;
drop table conf_tourney_setup;
drop table conf_tourney_wins;
drop table conf_wins;

/* export file */
copy train_finalfour_wins to '/Users/ntmill/Library/Mobile Documents/com~apple~CloudDocs/Projects/March Madness/2018/data/train_finalfour_wins.csv' delimiter ',' csv header;
