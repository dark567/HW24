
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

DROP TABLE [dbo].[Customers]
GO

CREATE TABLE dbo.Customers   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [CustomersID] [nvarchar](15) not null,
    [Name] [nvarchar](50) not null
   )


INSERT INTO [dbo].Customers
           ([CustomersID], [Name])
     SELECT DISTINCT [Customer ID],[Customer Name] FROM Orders$ 
GO

Select * from [JobWithNormalization].dbo.Customers

CREATE TABLE dbo.ShipModes   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null
   )

INSERT INTO [dbo].[ShipModes]
           ([Name])
     SELECT DISTINCT [Ship Mode] FROM Orders$ 
GO

Select * from [JobWithNormalization].dbo.[ShipModes]


CREATE TABLE [JobWithNormalization].[dbo].[Segments]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null
   )

INSERT INTO [dbo].[Segments]
           ([Name])
     SELECT DISTINCT [Segment] FROM Orders$ 
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
     SELECT DISTINCT [Country], [Region],  [State],  [City],  [Postal Code] FROM [Orders$] 
GO

Select * from [JobWithNormalization].dbo.[Addresses]


/*version 1*/
CREATE TABLE [JobWithNormalization].[dbo].[Categories]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null
   )

INSERT INTO [dbo].[Categories]
           ([Name])
     SELECT DISTINCT [Category] FROM [Orders] 
GO

Select * from [JobWithNormalization].dbo.[Categories]

CREATE TABLE [JobWithNormalization].[dbo].[SubCategories]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [CategoryID] [UNIQUEIDENTIFIER] not null,
    [Name] [nvarchar](50) not null
   )

INSERT INTO [dbo].[SubCategory]
           ([Name], [CategoryID])
     SELECT DISTINCT o.[Sub-Category], (select c.id from [Category] c where c.name = o.[Category]) FROM [Orders$] o
GO

Select * from [JobWithNormalization].dbo.[SubCategory]

DROP TABLE [dbo].[SubCategories]
GO

DROP TABLE [dbo].[Categories]
GO

/*version 2*/

DROP TABLE [dbo].[Categories]
GO

CREATE TABLE [JobWithNormalization].[dbo].[Categories]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [Name] [nvarchar](50) not null,
   )

ALTER TABLE [JobWithNormalization].[dbo].[Categories] ADD CategoryID [UNIQUEIDENTIFIER];
ALTER TABLE [JobWithNormalization].[dbo].[Categories] ADD foreign key (CategoryID) references [JobWithNormalization].[dbo].[Categories](id);

INSERT INTO [JobWithNormalization].[dbo].[Categories]
           ([Name])
     SELECT DISTINCT [Category] FROM [Orders$]
GO

INSERT INTO [JobWithNormalization].[dbo].[Categories]
           ([Name], [CategoryID])
     SELECT DISTINCT [Sub-Category], (select c.id from [Categories] c where c.name = o.[Category]) FROM [Orders$] o
GO

Select * from [JobWithNormalization].dbo.[Categories] /*where [CategoryID] is null*/




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
     SELECT DISTINCT [Product ID], [Product Name], (select c.id from [Categories] c where c.name = o.[Category]), Quantity, dbo.GETPRICE(o.SALES, o.Quantity, o.Discount, o.Profit) FROM [Orders$] o
GO

Select * from [JobWithNormalization].dbo.[Products] --where [Name] like '%Living Dimensions 2-Shelf Bookcases'

/*VIEW*/
CREATE VIEW [JobWithNormalization].[dbo].[OrdersView]
AS
SELECT        dbo.Orders$.*
FROM            dbo.[Orders$]

GO


DROP TABLE [dbo].[OrderFull]
GO

CREATE TABLE [JobWithNormalization].[dbo].[OrderFull]   
   ([ID] [UNIQUEIDENTIFIER] PRIMARY KEY DEFAULT newsequentialid(),
    [OrderDate] datetime2 not null,
    [ShipID] [UNIQUEIDENTIFIER] not null foreign key references [ShipModes](id),
	[ShipDate] datetime2 not null,
	[CustomerID] [UNIQUEIDENTIFIER] not null foreign key references [Customers](id),
	[SegmentID] [UNIQUEIDENTIFIER] not null foreign key references [Segments](id),
	[CategoryID] [UNIQUEIDENTIFIER] not null foreign key references [Categories](id),
	[AddressesID] [UNIQUEIDENTIFIER] not null foreign key references [Addresses](id),
	[ProductsID] [UNIQUEIDENTIFIER] not null foreign key references [Products](id),
	[Quantity] int default 0,
	[Discount] money default 0,
	[Profit] money default 0
   )


INSERT INTO [JobWithNormalization].[dbo].[OrderFull]
           ([OrderDate], [ShipID], [ShipDate], [CustomerID], [SegmentID], [CategoryID], [AddressesID], [ProductsID], [Quantity], [Discount], [Profit])
    SELECT o.[Order Date], sm.ID as ShipID, o.[Ship Date], cu.ID as [CustomerID], se.ID as SegmentID, cat.ID as CategoryID, adr.ID as AddressesID,
	 pr.ID as [ProductsID], o.[Quantity], o.[Discount], o.[Profit]
	FROM [Orders$] o
 join dbo.[ShipModes] sm on sm.Name = o.[Ship Mode]
 join dbo.[Customers] cu on cu.CustomersID = o.[Customer ID]
 join dbo.[Segments] se on se.Name = o.[Segment]
 join dbo.[Categories] cat on cat.Name = o.[Category]
 join dbo.[Addresses] adr on adr.Country = o.Country and adr.City =	o.City and adr.Region = o.Region and adr.PostalCode= o.[Postal Code]
 join dbo.[Products] pr on pr.ProductID = o.[Product ID]
GO

select * from [dbo].[OrderFull]


DROP VIEW dbo.[OrderFullView]

CREATE VIEW [dbo].[OrderFullView]
AS
SELECT orf.OrderDate, orf.ShipDate, sm.Name as [Ship Mode], cu.CustomersID as [Customer ID], se.Name as [Segment], 
cu.Name as [Customer Name], addr.Region, addr.Country, addr.City, addr.State, addr.PostalCode, ca.Name as [Categories Name], 
pr.ProductID, pr.Name, pr.[Count], orf.[Discount], pr.Price
	FROM  dbo.[OrderFull] orf
	left join dbo.[ShipModes] sm on sm.ID = orf.ShipID
	left join dbo.[Categories] ca on ca.ID = orf.CategoryID
	left join dbo.[Segments] se on se.ID = orf.SegmentID
	left join dbo.[Customers] cu on cu.ID = orf.CustomerID
	left join dbo.[Addresses] addr on addr.ID = orf.AddressesID
	left join dbo.[Products] pr on pr.ID = orf.ProductsID
GO

select * from [dbo].[OrderFullView]






















