/**********************************************************************
Created 3/4/2018 by NMiller
Objective - postgresql doesn't like uppercases in column name. adjusting so all column names are lowercase
**********************************************************************/

/* generates a series of alter table statements */
SELECT  'ALTER TABLE ' || quote_ident(c.table_schema) || '.'
  || quote_ident(c.table_name) || ' RENAME "' || c.column_name || '" TO ' || quote_ident(lower(c.column_name)) || ';' As ddlsql
  FROM information_schema.columns As c
  WHERE c.table_schema NOT IN('information_schema', 'pg_catalog') 
      AND c.column_name <> lower(c.column_name) 
  ORDER BY c.table_schema, c.table_name, c.column_name;

/* paste the alter table statements below */  
ALTER TABLE public.kenpom_pointdist RENAME "Def_1" TO def_1;
ALTER TABLE public.kenpom_pointdist RENAME "Def_2" TO def_2;
ALTER TABLE public.kenpom_pointdist RENAME "Def_3" TO def_3;
ALTER TABLE public.kenpom_pointdist RENAME "Off_1" TO off_1;
ALTER TABLE public.kenpom_pointdist RENAME "Off_2" TO off_2;
ALTER TABLE public.kenpom_pointdist RENAME "Off_3" TO off_3;
ALTER TABLE public.kenpom_pointdist RENAME "RankDef_1" TO rankdef_1;
ALTER TABLE public.kenpom_pointdist RENAME "RankDef_2" TO rankdef_2;
ALTER TABLE public.kenpom_pointdist RENAME "RankDef_3" TO rankdef_3;
ALTER TABLE public.kenpom_pointdist RENAME "RankOff_1" TO rankoff_1;
ALTER TABLE public.kenpom_pointdist RENAME "RankOff_2" TO rankoff_2;
ALTER TABLE public.kenpom_pointdist RENAME "RankOff_3" TO rankoff_3;
ALTER TABLE public.kenpom_pointdist RENAME "Season" TO season;
ALTER TABLE public.kenpom_pointdist RENAME "TeamName" TO teamname;