sp_configure 'show advanced options',1
reconfigure
GO
sp_configure 'Agent XPs',1
reconfigure
GO
sp_configure 'user options',1
reconfigure
GO

sp_configure 'xp_cmdshell',1
reconfigure
GO

sp_configure 'clr_enabled',1
reconfigure
GO
reconfigure

/** restoring database AW2016CTP3
RESTORE DATABASE AdventureWorks2016CTP3  
   FROM DISK = 'C:\Samples\SQLLabs\SQLLabs\Databases\AdventureWorks2016CTP3.bak';
   GO
   **/