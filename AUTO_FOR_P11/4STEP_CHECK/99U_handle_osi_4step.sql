--Reference table : das_4step_check,das_osi_check
--Nmae : handle 4step n osi 
--date brith : 20170221
--creater : CL
--
--
--
--


drop table check_list_osi4step;

create table check_list_osi4step as select equip_num name,equip_num blockname,station osi,point fourstep,inoutflag both,rtdbtype empty from das_rtdb  where station='-999'
;
insert into check_list_osi4step select b.equip_num,a.blockname,0,0,0,0 from das_rtdb b,view_electric_conn a where station||point in (select station||point from das_4step_check union  select station||point from das_osi_check ) 
and  b.colname ='STASTATUS' and b.category='R' and a.name=b.equip_num
;
--update 4step
update check_list_osi4step set fourstep=1 where name in 
(select equip_num from das_rtdb where station||point in (select station||point from das_4step_check ))
;
--update osi
update check_list_osi4step set osi=1 where name in 
(select equip_num from das_rtdb where station||point in (select station||point from das_osi_check ))
;
--update both

update check_list_osi4step set both=1 where fourstep=1 and osi=1;

commit;
exit;



update CHECK_LIST_OSI4STEP set blockname=replace(blockname,'_IV','');
update CHECK_LIST_OSI4STEP set blockname=replace(blockname,'_4','');
--update CHECK_LIST_OSI4STEP set blockname=blockname||'_IV' where osi=1 and both=0;
update CHECK_LIST_OSI4STEP set blockname=blockname||'_4' where fourstep=1 ;
--update CHECK_LIST_OSI4STEP set blockname=blockname||'_4_IV' where osi=1 and both=1;
commit;
--update CHECK_LIST_OSI4STEP a set blockname=(select blockname from CHECK_LIST_OSI4STEP_tmp where name=a.name);

update breaker a set blockname=(select blockname from CHECK_LIST_OSI4STEP where name=a.name) where name in (select name from CHECK_LIST_OSI4STEP);
update switch a set blockname=(select blockname from CHECK_LIST_OSI4STEP where name=a.name) where name in (select name from CHECK_LIST_OSI4STEP);



select distinct blockname from CHECK_LIST_OSI4STEP where blockname not in (select name from FSCLOOKUP);

BRK_V_4_IV