
USE [master]
GO

CREATE DATABASE [JobWithNormalization]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'JobWithNormalization', FILENAME = N'D:\DATA\JobWithNormalization.mdf' , SIZE = 7168KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'JobWithNormalization_log', FILENAME = N'D:\DATA\JobWithNormalization_log.ldf' , SIZE = 1280KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

/* export*/


Select * from [JobWithNormalization].dbo.Orders$


USE [JobWithNormalization]
GO

CREATE TABLE dbo.Customers   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null
   )


INSERT INTO [dbo].Customers
           ([Name])
     SELECT DISTINCT [Customer Name] FROM [Order] 
GO

Select * from [JobWithNormalization].dbo.Customers

CREATE TABLE dbo.ShipModes   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null
   )

INSERT INTO [dbo].[ShipModes]
           ([Name])
     SELECT DISTINCT [Ship Mode] FROM [Order] 
GO

Select * from [JobWithNormalization].dbo.[ShipMode]


CREATE TABLE [JobWithNormalization].[dbo].[Segments]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null
   )

INSERT INTO [dbo].[Segments]
           ([Name])
     SELECT DISTINCT [Segment] FROM [Order] 
GO

Select * from [JobWithNormalization].dbo.[Segments]

CREATE TABLE [JobWithNormalization].[dbo].[Addresses]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Country] [nvarchar](50) not null,
    [Region] [nvarchar](50) not null,
    [State] [nvarchar](50) not null,
    [City] [nvarchar](50) not null,
    [PostalCode] [int] 
   )

INSERT INTO [dbo].[Addresses]
           ([Country],[Region],[State],[City],[PostalCode])
     SELECT DISTINCT [Country], [Region],  [State],  [City],  [Postal Code] FROM [Order] 
GO

Select * from [JobWithNormalization].dbo.[Addresses]


/*version 1*/
CREATE TABLE [JobWithNormalization].[dbo].[Categories]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null
   )

INSERT INTO [dbo].[Categories]
           ([Name])
     SELECT DISTINCT [Category] FROM [Order] 
GO

Select * from [JobWithNormalization].dbo.[Categories]

CREATE TABLE [JobWithNormalization].[dbo].[SubCategories]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [CategoryID] [UNIQUEIDENTIFIER] not null,
    [Name] [nvarchar](50) not null
   )

INSERT INTO [dbo].[SubCategory]
           ([Name], [CategoryID])
     SELECT DISTINCT o.[Sub-Category], (select c.id from [Category] c where c.name = o.[Category]) FROM [Order] o
GO

Select * from [JobWithNormalization].dbo.[SubCategory]

DROP TABLE [dbo].[SubCategories]
GO

DROP TABLE [dbo].[Categories]
GO

/*version 2*/

CREATE TABLE [JobWithNormalization].[dbo].[Categories]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null,
   )

ALTER TABLE [JobWithNormalization].[dbo].[Categories] ADD CategoryID [UNIQUEIDENTIFIER];
ALTER TABLE [JobWithNormalization].[dbo].[Categories] ADD foreign key (CategoryID) references [JobWithNormalization].[dbo].[Categories](id);

INSERT INTO [JobWithNormalization].[dbo].[Categories]
           ([Name])
     SELECT DISTINCT [Category] FROM [Order]
GO

INSERT INTO [JobWithNormalization].[dbo].[Categories]
           ([Name], [CategoryID])
     SELECT DISTINCT [Sub-Category], (select c.id from [Categories] c where c.name = o.[Category]) FROM [Order] o
GO

Select * from [JobWithNormalization].dbo.[Categories] /*where [CategoryID] is null*/

DROP TABLE [dbo].[Categories]
GO


/*FUNCTION*/
CREATE FUNCTION GETPRICE (@SALES money, @Quantity int, @Discount money, @Profit money) 
RETURNs money
AS
BEGIN
	DECLARE @Price money
	set @Price = (@SALES - @Quantity * @Discount)/ @Quantity; 
	RETURN @Price

END
GO


DROP TABLE [dbo].[Products]
GO

CREATE TABLE [JobWithNormalization].[dbo].[Products]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [ProductID] [nvarchar](15) not null,
    [CategoryID] [UNIQUEIDENTIFIER] not null foreign key references [Categories](id),
    [Name] [nvarchar](150) not null,
	[Count] int not null default(0),
	[Price] money default(0)
   )

INSERT INTO [JobWithNormalization].[dbo].[Products]
           ([ProductID], [Name], [CategoryID], [Count], [Price])
     SELECT DISTINCT [Product ID], [Product Name], (select c.id from [Categories] c where c.name = o.[Category]), Quantity, dbo.GETPRICE(o.SALES, o.Quantity, o.Discount, o.Profit) FROM [Order] o
GO

Select * from [JobWithNormalization].dbo.[Products] --where [Name] like '%Living Dimensions 2-Shelf Bookcases'




/*VIEW*/
CREATE VIEW [JobWithNormalization].[dbo].[Order]
AS
SELECT        dbo.Orders$.*
FROM            dbo.Orders$

GO









