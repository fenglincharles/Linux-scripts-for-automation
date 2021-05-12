/*################################################################################################################################################## 
--##                  
--##  Purpose:		 	Following scripts are to 1.create analogpoint for devices which have AMP remote point in DAS_RTDB table.
--##        													   2.create remote point for analogpoint in DAS_RTDB table.
--##     														   3.create command target for schematic version
--##															   4.update Tile name in Mapnames table for schematic version
--##															   5.create tabular for analogpoints 
--##							    							   6.create RMU backgroundblock with OLine version 						
--##
--##  Created on:      	2017-01-16 by JK
--##  Last modify:     	2017-01-16 by JK
--##   
--##################################################################################################################################################*/

--##Create RMU background block for OLine version
update gis_switch a set TEXTHEIGHT=(select TEXTHEIGHT from gis_switch where a.ufid=ufid and ver='LIVE') where ver ='OLine';
commit;

delete gis_backgroundblock where ver = 'OLine' ; 
commit;

drop table gis_backgroundblock_sch ;
Create table gis_backgroundblock_sch as select * from gis_backgroundblock
 where TEXTHEIGHT in (select TEXTHEIGHT from gis_switch where ver = 'OLine' and (name like '%OD%' or name like '%VL%') ) ;
update gis_backgroundblock_sch set ver='OLine', ufid=ufid+100000000,featid=featid+100000000;
commit;

insert into gis_backgroundblock select * from  gis_backgroundblock_sch ;
commit;

drop table gis_backgroundblock_sch ;

--##Create analogpoint for devices which have AMP remote point in DAS_RTDB table.
 
delete analogpoint where TEXTJUSTIFICATION='Dummy';
commit;
 
--## For GIS_SWITCH 

set serveroutput on
begin
for sw in (select * from gis_switch where ver= 'OLine' and name in (select equip_num from das_rtdb where colname = 'AMPA' and category='R' and (equip_num like '%OD%' or equip_num like '%VL%'))) 
loop 
--dbms_output.put_line(sw.TEXTHEIGHT);

 insert into  analogpoint
 ( CLASSID,  REVISIONNUMBER, PROPOSEDSTATUS, TYPE, ANALOG_ID, VER,
 UFID, SUBSTATION, FSC, FLOWDIR, FEEDER, PLOTSTYLE, NORMAL, LINEWEIGHT, LINETYPESCALE,
 LINETYPE, LAYER, ENTITYTYPE, COLOR,TEXTJUSTIFICATION,TEXTHEIGHT,
 BLOCKSCALE, BLOCKROTATION, BLOCKNAME, GEOMETRY, FEATID)
 select 
 7,0,1,'DATAVALUE',name||'A','OLine',
 UFID+100000000,SUBSTATION,202,0,'FEEDER','ByBlock','(0,0,1)', -1,1,
 'ByLayer',LAYER,'BlockReference',0,'Dummy',TEXTHEIGHT,
 '(0.05,0.05,0.05)',0,'ANALOGPOINT',(select GEOMETRY from gis_backgroundblock where ver= a.ver and TEXTHEIGHT=a.TEXTHEIGHT),FEATID+100000000 
  from gis_switch a where name=sw.name and ufid=sw.ufid and ver=sw.ver ; 
 
  insert into  analogpoint
 ( CLASSID,  REVISIONNUMBER, PROPOSEDSTATUS, TYPE, ANALOG_ID, VER,
 UFID, SUBSTATION, FSC, FLOWDIR, FEEDER, PLOTSTYLE, NORMAL, LINEWEIGHT, LINETYPESCALE,
 LINETYPE, LAYER, ENTITYTYPE, COLOR,TEXTJUSTIFICATION,TEXTHEIGHT,
 BLOCKSCALE, BLOCKROTATION, BLOCKNAME, GEOMETRY, FEATID)
 select 
 7,0,1,'DATAVALUE',name||'B','OLine',
 UFID+200000000,SUBSTATION,202,0,'FEEDER','ByBlock','(0,0,1)', -1,1,
 'ByLayer',LAYER,'BlockReference',0,'Dummy',TEXTHEIGHT,
 '(0.05,0.05,0.05)',0,'ANALOGPOINT',(select GEOMETRY from gis_backgroundblock where ver= a.ver and TEXTHEIGHT=a.TEXTHEIGHT),FEATID+200000000 
  from gis_switch a where  name=sw.name and ufid=sw.ufid and ver=sw.ver ; 

  insert into  analogpoint
 ( CLASSID,  REVISIONNUMBER, PROPOSEDSTATUS, TYPE, ANALOG_ID, VER,
 UFID, SUBSTATION, FSC, FLOWDIR, FEEDER, PLOTSTYLE, NORMAL, LINEWEIGHT, LINETYPESCALE,
 LINETYPE, LAYER, ENTITYTYPE, COLOR,TEXTJUSTIFICATION,TEXTHEIGHT,
 BLOCKSCALE, BLOCKROTATION, BLOCKNAME, GEOMETRY, FEATID)
 select 
 7,0,1,'DATAVALUE',name||'C','OLine',
 UFID+300000000,SUBSTATION,202,0,'FEEDER','ByBlock','(0,0,1)', -1,1,
 'ByLayer',LAYER,'BlockReference',0,'Dummy',TEXTHEIGHT,
 '(0.05,0.05,0.05)',0,'ANALOGPOINT',(select GEOMETRY from gis_backgroundblock where ver= a.ver and TEXTHEIGHT=a.TEXTHEIGHT),FEATID+300000000 
  from gis_switch a where  name=sw.name and ufid=sw.ufid and ver=sw.ver ;
commit;
end loop;
end;
/
--## For GIS_BREAKER

begin
for brk in (select * from gis_breaker where ver= 'OLine' and name in (select equip_num from das_rtdb where colname = 'AMPA' and category='R' and (equip_num like '%OD%' or equip_num like '%VL%'))) 
loop 
 insert into  analogpoint
 ( CLASSID,  REVISIONNUMBER, PROPOSEDSTATUS, TYPE, ANALOG_ID, VER,
 UFID, SUBSTATION, FSC, FLOWDIR, FEEDER, PLOTSTYLE, NORMAL, LINEWEIGHT, LINETYPESCALE,
 LINETYPE, LAYER, ENTITYTYPE, COLOR,TEXTJUSTIFICATION,TEXTHEIGHT,
 BLOCKSCALE, BLOCKROTATION, BLOCKNAME, GEOMETRY, FEATID)
 select 
 7,0,1,'DATAVALUE',name||'A','OLine',
 UFID+100000000,SUBSTATION,202,0,'FEEDER','ByBlock','(0,0,1)', -1,1,
 'ByLayer',LAYER,'BlockReference',0,'Dummy',TEXTHEIGHT,
 '(0.05,0.05,0.05)',0,'ANALOGPOINT',(select GEOMETRY from gis_backgroundblock where ver= a.ver and TEXTHEIGHT=a.TEXTHEIGHT),FEATID+100000000 
  from GIS_BREAKER a where name=brk.name and ufid=brk.ufid and ver=brk.ver ; 
 
  insert into  analogpoint
 ( CLASSID,  REVISIONNUMBER, PROPOSEDSTATUS, TYPE, ANALOG_ID, VER,
 UFID, SUBSTATION, FSC, FLOWDIR, FEEDER, PLOTSTYLE, NORMAL, LINEWEIGHT, LINETYPESCALE,
 LINETYPE, LAYER, ENTITYTYPE, COLOR,TEXTJUSTIFICATION,TEXTHEIGHT,
 BLOCKSCALE, BLOCKROTATION, BLOCKNAME, GEOMETRY, FEATID)
 select 
 7,0,1,'DATAVALUE',name||'B','OLine',
 UFID+200000000,SUBSTATION,202,0,'FEEDER','ByBlock','(0,0,1)', -1,1,
 'ByLayer',LAYER,'BlockReference',0,'Dummy',TEXTHEIGHT,
 '(0.05,0.05,0.05)',0,'ANALOGPOINT',(select GEOMETRY from gis_backgroundblock where ver= a.ver and TEXTHEIGHT=a.TEXTHEIGHT),FEATID+200000000 
  from GIS_BREAKER a where name=brk.name and ufid=brk.ufid and ver=brk.ver   ; 

  insert into  analogpoint
 ( CLASSID,  REVISIONNUMBER, PROPOSEDSTATUS, TYPE, ANALOG_ID, VER,
 UFID, SUBSTATION, FSC, FLOWDIR, FEEDER, PLOTSTYLE, NORMAL, LINEWEIGHT, LINETYPESCALE,
 LINETYPE, LAYER, ENTITYTYPE, COLOR,TEXTJUSTIFICATION,TEXTHEIGHT,
 BLOCKSCALE, BLOCKROTATION, BLOCKNAME, GEOMETRY, FEATID)
 select 
 7,0,1,'DATAVALUE',name||'C','OLine',
 UFID+300000000,SUBSTATION,202,0,'FEEDER','ByBlock','(0,0,1)', -1,1,
 'ByLayer',LAYER,'BlockReference',0,'Dummy',TEXTHEIGHT,
 '(0.05,0.05,0.05)',0,'ANALOGPOINT',(select GEOMETRY from gis_backgroundblock where ver= a.ver and TEXTHEIGHT=a.TEXTHEIGHT),FEATID+300000000 
  from GIS_BREAKER a where name=brk.name and ufid=brk.ufid and ver=brk.ver   ; 
commit;
end loop;
end;
/

set serveroutput on
DECLARE

X integer ;

	PROCEDURE ProcName(X in integer, sw_ufid in integer)
	Is
	   	sqlstr1 VARCHAR2(2000);
	    sqlstr2 VARCHAR2(2000);
	    sqlstr3 VARCHAR2(2000);
	begin
	
	sqlstr1 := 'update analogpoint a set geometry=
	(select SDO_GEOMETRY(3001, NULL, SDO_POINT_TYPE(b.x+'||X||', b.y+0.2, 0),NULL,NULL)
	from table( sdo_UTIL.getvertices(a.geometry))  b) where a.ufid='||sw_ufid||' and a.ANALOG_ID like ''%A'''; 
	EXECUTE IMMEDIATE sqlstr1;
	
	sqlstr2 :='update analogpoint a set geometry=
	(select SDO_GEOMETRY(3001, NULL, SDO_POINT_TYPE(b.x+'||X||', b.y, 0),NULL,NULL)
	from table( sdo_UTIL.getvertices(a.geometry))  b) where a.ufid='||sw_ufid||' and a.ANALOG_ID like ''%B'''; 
	EXECUTE IMMEDIATE sqlstr2;

	sqlstr3 :='update analogpoint a set geometry=
	(select SDO_GEOMETRY(3001, NULL, SDO_POINT_TYPE(b.x+'||X||', b.y-0.2, 0),NULL,NULL)
	from table( sdo_UTIL.getvertices(a.geometry))  b) where a.ufid='||sw_ufid||' and a.ANALOG_ID like ''%C'''; 
	EXECUTE IMMEDIATE sqlstr3;

	END ProcName;	
	
Begin 
For sw in (select * from analogpoint where ver = 'OLine' and (ANALOG_ID like '%OD%' or ANALOG_ID like '%VL%'))
Loop 
dbms_output.put_line(sw.ANALOG_ID);
--dbms_output.put_line(sw.ufid);

--dbms_output.put_line(substr(sw.ANALOG_ID,length(sw.ANALOG_ID)-3,3));
if substr(sw.ANALOG_ID,length(sw.ANALOG_ID)-3,3) = 'OD1' then
ProcName(0.5,sw.ufid) ;
commit;
end if;

if substr(sw.ANALOG_ID,length(sw.ANALOG_ID)-3,3) = 'OD2' then
ProcName(1,sw.ufid) ;
commit;
end if;

if substr(sw.ANALOG_ID,length(sw.ANALOG_ID)-3,3) = 'VL1' then
ProcName(1.5,sw.ufid) ;
commit;
end if;

end loop;
end;
/

delete backgroundblock where TEXTJUSTIFICATION='Dummy';
commit;

begin
for ana in (select TEXTHEIGHT from analogpoint where ver= 'OLine' and rownum=1 group by TEXTHEIGHT )
loop 

insert into backgroundblock 
(CLASSID, REVISIONNUMBER,TEXTSTRING3,TEXTSTRING2,TEXTSTRING1,VER,
SUBSTATION,FLOWDIR,FEEDER,UFID,PLOTSTYLE,NORMAL, LINEWEIGHT, LINETYPESCALE,
LINETYPE, LAYER, ENTITYTYPE, COLOR,TEXTJUSTIFICATION,
BLOCKSCALE, BLOCKROTATION, BLOCKNAME, GEOMETRY, FEATID)
select 
8,0,0,0,TEXTHEIGHT||'TAB','OLine',
SUBSTATION,0,'FEEDER',UFID+200000000,'ByBlock','(0,0,1)', -1,1,
'ByLayer',LAYER,'BlockReference',0,'Dummy',
'(1.65,1,1)',0,'ACS_TAB',(select GEOMETRY from gis_backgroundblock where ver= a.ver and TEXTHEIGHT=a.TEXTHEIGHT),FEATID+200000000 
from gis_backgroundblock a where ver='OLine' and TEXTHEIGHT=ana.TEXTHEIGHT; 
commit;

end loop;
end;
/

update backgroundblock a set geometry=
(select SDO_GEOMETRY(3001, NULL, SDO_POINT_TYPE(b.x+0.47, b.y-0.26, 0),NULL,NULL)
from table( sdo_UTIL.getvertices(a.geometry))  b) ; 
commit;

/*
drop table analogpoint_GEO; 
create table analogpoint_GEO as select b.id ,a.ANALOG_ID,a.ufid,b.x , b.y from analogpoint a, table( sdo_UTIL.getvertices(a.geometry)) b where a.ANALOG_ID like '%A';
update analogpoint a set geometry=
(select SDO_GEOMETRY(3001, NULL, SDO_POINT_TYPE(b.x+:position_X, b.y+0.25, 0),NULL,NULL)
from analogpoint_GEO b where a.ufid = b.ufid) where ANALOG_ID like '%A'; 
commit;

drop table analogpoint_GEO; 
create table analogpoint_GEO as select b.id ,a.ANALOG_ID,a.ufid,b.x , b.y from analogpoint a, table( sdo_UTIL.getvertices(a.geometry)) b where a.ANALOG_ID like '%B';
update analogpoint a set geometry=
(select SDO_GEOMETRY(3001, NULL, SDO_POINT_TYPE(b.x+:position_X, b.y, 0),NULL,NULL)
from analogpoint_GEO b where a.ufid = b.ufid ) where ANALOG_ID like '%B'; 
commit;


drop table analogpoint_GEO; 
create table analogpoint_GEO as select b.id ,a.ANALOG_ID,a.ufid,b.x , b.y from analogpoint a, table( sdo_UTIL.getvertices(a.geometry)) b where a.ANALOG_ID like '%C';
update analogpoint a set geometry=
(select SDO_GEOMETRY(3001, NULL, SDO_POINT_TYPE(b.x+:position_X, b.y-0.25, 0),NULL,NULL)
from analogpoint_GEO b where a.ufid = b.ufid) where ANALOG_ID like '%C'; 
commit;
*/
 
--## Create Remote Point For analog point
drop table RTDB_analog ;
Create table RTDB_analog 
as select * from das_rtdb where  colname like 'AMP%' and category='R' and (equip_num like '%OD%' or equip_num like '%VL%')
and equip_num in (select name from gis_switch where  ver= 'OLine' union select name from gis_breaker where  ver= 'OLine');
 
update RTDB_analog set tablename='SCADADATA', equip_num=equip_num||'A',colname='DATAVALUE', inoutflag=4 where colname like 'AMPA';
update RTDB_analog set tablename='SCADADATA', equip_num=equip_num||'B',colname='DATAVALUE', inoutflag=4 where colname like 'AMPB';
update RTDB_analog set tablename='SCADADATA', equip_num=equip_num||'C',colname='DATAVALUE', inoutflag=4 where colname like 'AMPC';
commit;

delete das_rtdb where  tablename='SCADADATA' and colname='DATAVALUE' and inoutflag=4 ;
commit;
insert into das_rtdb select * from RTDB_analog;
commit;

drop table RTDB_analog; 
 --## Create command target for schematic version
delete command where ver = 'OLine' ;
commit;

drop table command_sch ;
Create table command_sch as select * from command ;
update command_sch set ver='OLine', ufid=ufid+100000000,featid=featid+100000000;
commit;

insert into command select * from  command_sch ;
commit;

drop table command_sch ;

--## Update Tile name in Mapnames table for schematic version
update mapnames set name=replace(name,'Tile','TSch') where name like 'Tile%';
commit;

update CONFIGURATION set value='OLine' where profile='DXFWriter' and name='VerName' ;
commit;

exit;
