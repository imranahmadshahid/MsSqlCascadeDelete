
declare @currentkey varchar(max)
declare @currenttableName varchar(max)
declare @currenttableKey varchar(max)
declare @currentparentTableName varchar(max)
declare @currentparentTableKey varchar(max)

create table #DeleteConstraints(sqlStatement varchar(max))
create table #AddConstraints(sqlStatement varchar(max))

create table #foreignKeyDetails (
foreignKey varchar(max),
tableName varchar(max),
tableKey varchar(max),
parentTableName varchar(max),
parentTableKey varchar(max),
)


insert into #foreignKeyDetails(foreignKey,tableName,tableKey,parentTableName,parentTableKey)
select 
sfk.name
,(select top 1 name from sys.objects where object_id= sfk.parent_object_id) TableName

,(select (select name from sys.columns  scs where scs.object_id=fkcs.parent_object_id and scs.column_id =fkcs.parent_column_id) 
from sys.foreign_key_columns fkcs where fkcs.constraint_object_id=sfk.object_id) aTbleKey

,(select top 1 name from sys.objects where object_id= sfk.referenced_object_id) ParentTableName

,(select (select name from sys.columns  scs where scs.object_id=fkcs.referenced_object_id and scs.column_id =fkcs.referenced_column_id) 
from sys.foreign_key_columns fkcs where fkcs.constraint_object_id=sfk.object_id) ParentTableKey

from sys.foreign_keys sfk



select * from #foreignKeyDetails

while exists (select * from #foreignKeyDetails)
begin

select top 1 @currentkey = foreignKey
from #foreignKeyDetails
order by foreignKey asc

select @currenttableName=tableName, 
@currenttableKey=tableKey, 
@currentparenttableName=parentTableName, 
@currentparenttableKey=parentTableKey
from #foreignKeyDetails where foreignKey=@currentkey

declare @sql varchar(max)


SET QUOTED_IDENTIFIER OFF;
set @sql ="IF (OBJECT_ID('"+@currentkey+"') IS NOT NULL) " + "alter table "+ @currenttableName+ " drop constraint "+ @currentkey
insert into  #DeleteConstraints(sqlStatement)values(@sql)
SET QUOTED_IDENTIFIER ON;

Declare @deletionSql varchar(max)
set @sql = 'ALTER TABLE ' + @currenttableName +
' ADD CONSTRAINT ' +  @currentkey + 
' FOREIGN KEY (' + @currenttableKey+')' +
' REFERENCES ['+ @currentparentTableName + ']('+@currentparentTableKey+')'

set @deletionSql = 'Begin Try ' + @sql + ' ON DELETE CASCADE;' + ' End Try Begin Catch ' + @sql +' End Catch' 



insert into  #AddConstraints(sqlStatement)values(@deletionSql)


Delete from #foreignKeyDetails where foreignKey=@currentkey

end

--while exists (select * from #DeleteConstraints)
--begin
--declare @currentDelete varchar(max)
--select top 1 @currentDelete=sqlstatement from #DeleteConstraints
--execute(@currentDelete)
--delete from #DeleteConstraints where sqlstatement = @currentDelete
--end

select * from #DeleteConstraints
select * from #AddConstraints


drop table #foreignKeyDetails
drop table #DeleteConstraints
drop table #AddConstraints



