/***********************************************************
Created 3/4/2018 by NMiller
Objective - to create a master kenpom data table to append to historical tournament results
***********************************************************/

drop table kenpom_master;

/* step 1 - create base table with kenpom summary statistics */
create table kenpom_base as
select distinct ks.season::int::text||t.teamid::int::text as teamseasonid
	,ks.season
	,t.teamid
	,t.teamname
	,ks.tempo
	,ks.adjtempo
	,ks.oe
	,ks.adjoe
	,ks.de
	,ks.adjde
	,ks.adjem
from kenpom_summary ks
left join teams t on ks.teamname = t.teamname
where t.teamid is not null;

/* step 2 - add four factor offensive statistics */
create table kenpom_ffo as
select kb.*
	,ffo.efg_pct as efg_pct_off
	,ffo.to_pct as to_pct_off
	,ffo.or_pct as or_pct_off
	,ffo.ft_rate as ft_rate_off
from kenpom_base kb
left join kenpom_fourfactor_off ffo on kb.season = ffo.season and kb.teamname = ffo.teamname;

/* step 3 - add four factor defensive statistics */
create table kenpom_ffd as
select ffo.*
	,ffd.efg_pct as efg_pct_def
	,ffd.to_pct as to_pct_def
	,ffd.or_pct as or_pct_def
	,ffd.ft_rate as ft_rate_def
from kenpom_ffo ffo
left join kenpom_fourfactor_def ffd on ffo.season = ffd.season and ffo.teamname = ffd.teamname;

/* step 4 - add height and experience data */
create table kenpom_add_heighexp as
select ffd.*
	,he.size
	,he.hgteff
	,he.exp
	,he.bench
from kenpom_ffd ffd
left join kenpom_heightexp he on ffd.season = he.season and ffd.teamname = he.teamname;

/* step 5 - add misc metrics */
create table kenpom_add_misc as
select fhe.*
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
from kenpom_add_heighexp fhe
left join kenpom_misc km on km.season = fhe.season and km.teamname = fhe.teamname;

/* step 6 - add point distribution data to finish master table */
create table kenpom_master as
select fm.*
	,kpd.off_1
	,kpd.off_2
	,kpd.off_3
	,kpd.def_1
	,kpd.def_2
	,kpd.def_3
from kenpom_add_misc fm
left join kenpom_pointdist kpd on kpd.season = fm.season and kpd.teamname = fm.teamname;

drop table kenpom_base;
drop table kenpom_ffo;
drop table kenpom_ffd;
drop table kenpom_add_heighexp;
drop table kenpom_add_misc;
