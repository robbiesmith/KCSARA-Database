﻿/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
IF NOT EXISTS (SELECT 1 FROM [dbo].[aspnet_Applications] WHERE ApplicationName LIKE 'Kcsar')
  INSERT INTO aspnet_Applications VALUES('Kcsar','kcsar','F4266656-79F7-4723-9580-0A1AF8B13F0D','King County Users and Groups')

IF NOT EXISTS (SELECT 1 FROM aspnet_Roles WHERE ApplicationId='F4266656-79F7-4723-9580-0A1AF8B13F0D' AND roleName LIKE 'cdb.admins')
  INSERT INTO aspnet_Roles (ApplicationId,RoleId,RoleName,LoweredRoleName) VALUES('F4266656-79F7-4723-9580-0A1AF8B13F0D',NEWID(),'cdb.admins','cdb.admins')
IF NOT EXISTS (SELECT 1 FROM aspnet_Roles WHERE ApplicationId='F4266656-79F7-4723-9580-0A1AF8B13F0D' AND roleName LIKE 'cdb.users')
  INSERT INTO aspnet_Roles (ApplicationId,RoleId,RoleName,LoweredRoleName) VALUES('F4266656-79F7-4723-9580-0A1AF8B13F0D',NEWID(),'cdb.users','cdb.users')
IF NOT EXISTS (SELECT 1 FROM aspnet_Roles WHERE ApplicationId='F4266656-79F7-4723-9580-0A1AF8B13F0D' AND roleName LIKE 'site.accounts')
  INSERT INTO aspnet_Roles (ApplicationId,RoleId,RoleName,LoweredRoleName) VALUES('F4266656-79F7-4723-9580-0A1AF8B13F0D',NEWID(),'site.accounts','site.accounts')

DECLARE @userid UNIQUEIDENTIFIER
DECLARE @RC bit

DECLARE @now DATETIME = GETUTCDATE()

IF NOT EXISTS (SELECT 1 FROM aspnet_Users WHERE username='admin' AND ApplicationId='F4266656-79F7-4723-9580-0A1AF8B13F0D')
BEGIN
  -- Seed admin account with password 'password'
	execute [dbo].[aspnet_Membership_CreateUser] 'Kcsar','admin','+taapl3jPAcYr8P/gF4hGPz/7XQ=','obW1Z+SoySqNDfoTqRItCA==','admin@kingcountysar.org',null,null,1,@now,@now,1,1,@userid OUTPUT
END
ELSE
  SET @userid = (SELECT UserId FROM aspnet_Users WHERE username='admin' AND ApplicationId='F4266656-79F7-4723-9580-0A1AF8B13F0D')



EXECUTE @RC = [dbo].[aspnet_UsersInRoles_IsUserInRole] 'Kcsar','admin','site.accounts'
IF (1 <> @RC)
  EXECUTE [dbo].[aspnet_UsersInRoles_AddUsersToRoles] 'Kcsar','admin','site.accounts',@now

IF NOT EXISTS (SELECT 1 FROM RolesInRoles rr JOIN aspnet_Roles c ON c.RoleId=rr.ChildRoleId JOIN aspnet_Roles p ON p.RoleId=rr.ParentRoleId WHERE c.RoleName LIKE 'cdb.admins' AND p.RoleName like 'cdb.users')
  INSERT INTO RolesInRoles (ChildRoleId, ParentRoleId) VALUES((SELECT RoleId FROM aspnet_Roles WHERE ApplicationId='f4266656-79f7-4723-9580-0a1af8b13f0d' AND RoleName='cdb.admins'),(SELECT RoleId FROM aspnet_Roles WHERE ApplicationId='f4266656-79f7-4723-9580-0a1af8b13f0d' AND RoleName='cdb.users'))

IF NOT EXISTS (SELECT 1 FROM RolesInRoles rr JOIN aspnet_Roles c ON c.RoleId=rr.ChildRoleId JOIN aspnet_Roles p ON p.RoleId=rr.ParentRoleId WHERE c.RoleName LIKE 'site.accounts' AND p.RoleName like 'cdb.admins')
  INSERT INTO RolesInRoles (ChildRoleId, ParentRoleId) VALUES((SELECT RoleId FROM aspnet_Roles WHERE ApplicationId='f4266656-79f7-4723-9580-0a1af8b13f0d' AND RoleName='site.accounts'),(SELECT RoleId FROM aspnet_Roles WHERE ApplicationId='f4266656-79f7-4723-9580-0a1af8b13f0d' AND RoleName='cdb.admins'))

