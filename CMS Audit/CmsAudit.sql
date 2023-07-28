/*CREATES AUDIT TABLE FOR CMS ITEMS*/
CREATE TABLE [dbo].[Basiscore_CmsAudit_Items](
    [RowId] [bigint] IDENTITY(1,1) NOT NULL,
    [ItemId] [uniqueidentifier] NULL,
    [ItemName] [varchar](300) NULL,
	[ItemPath] [varchar](2000) NULL,
	[TemplateId] [uniqueidentifier] NULL,
	[ItemLanguage] [varchar](50) NULL,
	[ItemVersion] [int] NULL,
	[Event] [varchar](100) NULL,
	[ActionedBy] [varchar](100) NULL,
	[ItemDataBeforeSave] [nvarchar](MAX) NULL,	
	[ItemDataAfterSave] [nvarchar](MAX) NULL,	
	[Comments] [nvarchar](4000) NULL,
    [LoggedTime] [datetime] NULL,
 CONSTRAINT [PK_Basiscore_CmsAudit_Items] PRIMARY KEY CLUSTERED 
(
    [RowId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
) ON [PRIMARY]
GO

/*CREATES STORED PROCEDURE TO INSERT CMS ITEM AUDIT LOG*/
CREATE PROCEDURE usp_Basiscore_CmsAudit_InsertItemAuditLog
	@ItemId uniqueidentifier,
    @ItemName varchar(300),
	@ItemPath varchar(2000),
	@TemplateId uniqueidentifier,
	@ItemLanguage varchar(50),
	@ItemVersion int,
	@Event varchar(100),
	@ActionedBy varchar(100),
	@ItemDataBeforeSave nvarchar(MAX),	
	@ItemDataAfterSave nvarchar(MAX),	
	@Comments nvarchar(4000),
    @LoggedTime datetime
AS
BEGIN
	SET NOCOUNT ON;

    INSERT INTO Basiscore_CmsAudit_Items(
		ItemId,
		ItemName,
		ItemPath,
		TemplateId,
		ItemLanguage,
		ItemVersion,
		[Event],
		ActionedBy,
		ItemDataBeforeSave,
		ItemDataAfterSave,
		Comments,
		LoggedTime
	)
	VALUES(
		@ItemId,
		@ItemName,
		@ItemPath,
		@TemplateId,
		@ItemLanguage,
		@ItemVersion,
		@Event,
		@ActionedBy,
		@ItemDataBeforeSave,
		@ItemDataAfterSave,
		@Comments,
		@LoggedTime
	)
END
GO

/*CREATES SP TO FETCH ITEM AUDIT LOGS*/
--exec [usp_Basiscore_CmsAudit_GetItemLogs] 0, 0, 0, '', '', '', '2023-07-13', '2023-07-25'
CREATE PROCEDURE [dbo].[usp_Basiscore_CmsAudit_GetItemLogs]
	@GetOnlySitePublishLogs bit,
	@GetOnlyItemPublishLogs bit,
	@GetOnlyPublishLogs bit,
	@ItemId nvarchar(1000) = null,  
	@ActionedBy varchar(100) = null,
	@ItemLanguage varchar(50) = null,
    @FromDate datetime,
	@ToDate datetime
AS
BEGIN
	DECLARE @GetPublishLogs bit = 0
	DECLARE @Event varchar(100) = ''
	DECLARE @ItemIdGuid uniqueidentifier = null
	DECLARE @dtFrom date
	DECLARE @dtTo date

	--adding 1 day to passed todate
	SET @ToDate = DATEADD(day, 1, @ToDate)

	SET @dtFrom = CONVERT(DATE, @FromDate)
	SET @dtTo = CONVERT(DATE, @ToDate)

	IF(ISNULL(@ItemId,'') <> '')
	BEGIN
		SET @ItemIdGuid = CONVERT(uniqueidentifier, @ItemId)
	END

	IF(@GetOnlySitePublishLogs = 1)
	BEGIN
		SELECT *
		FROM Basiscore_CmsAudit_Items(NOLOCK)
		WHERE LoggedTime BETWEEN @dtFrom AND @dtTo
		AND Event = 'Site Published' 
		AND (ActionedBy LIKE '%' + @ActionedBy + '%' OR ISNULL(@ActionedBy,'') = '')
		ORDER BY LoggedTime DESC
	END
	ELSE IF(@GetOnlyItemPublishLogs = 1)
	BEGIN
		SELECT *
		FROM Basiscore_CmsAudit_Items(NOLOCK)
		WHERE LoggedTime BETWEEN @dtFrom AND @dtTo
		AND Event = 'Item Published' 
		AND (ItemId = @ItemIdGuid OR @ItemIdGuid IS NULL)
		AND (ActionedBy LIKE '%' + @ActionedBy + '%' OR ISNULL(@ActionedBy,'') = '')
		ORDER BY LoggedTime DESC
	END
	ELSE IF(@GetOnlyPublishLogs = 1)
	BEGIN
		SELECT *
		FROM Basiscore_CmsAudit_Items(NOLOCK)
		WHERE LoggedTime BETWEEN @dtFrom AND @dtTo
		AND Event LIKE '%Published%'		
		AND (ActionedBy LIKE '%' + @ActionedBy + '%' OR ISNULL(@ActionedBy,'') = '')
		ORDER BY LoggedTime DESC
	END	
	ELSE
	BEGIN
		SELECT *
		FROM Basiscore_CmsAudit_Items(NOLOCK)
		WHERE LoggedTime BETWEEN @dtFrom AND @dtTo
		AND (ItemId = @ItemIdGuid OR @ItemIdGuid IS NULL)
		AND (ActionedBy LIKE '%' + @ActionedBy + '%' OR ISNULL(@ActionedBy,'') = '')
		AND (ItemLanguage = @ItemLanguage OR ISNULL(@ItemLanguage,'') = '')
		ORDER BY LoggedTime DESC
	END
END
GO

/*GET SUMMARY OF ITEM AUDIT LOGS*/
--exec usp_Basiscore_CmsAudit_GetItemAuditDataSummary
CREATE PROCEDURE usp_Basiscore_CmsAudit_GetItemAuditDataSummary
AS
BEGIN
	DECLARE @FirstLogDate datetime
	DECLARE @RecentLogDate datetime
	DECLARE @TotalRows int

	SELECT TOP 1 @FirstLogDate = LoggedTime 
	FROM Basiscore_CmsAudit_Items (NOLOCK)
	ORDER BY LoggedTime ASC

	SELECT TOP 1 @RecentLogDate = LoggedTime 
	FROM Basiscore_CmsAudit_Items (NOLOCK)
	ORDER BY LoggedTime DESC

	SELECT @TotalRows = COUNT(1) 
	FROM Basiscore_CmsAudit_Items (NOLOCK)
	
	SELECT @FirstLogDate AS FirstLogDate, @RecentLogDate AS RecentLogDate, @TotalRows AS TotalRows
END
GO

/*DELETE ITEM AUDIT LOGS*/
--exec usp_Basiscore_CmsAudit_DeleteItemAuditLogs '2023-07-19', '2023-07-19', 1, 30
CREATE PROCEDURE [dbo].[usp_Basiscore_CmsAudit_DeleteItemAuditLogs]
	@FromDate datetime,
	@ToDate datetime,
	@IsScheduledDelete bit = 0,
	@DataRetentionDays int = 30
AS
BEGIN
	DECLARE @dtFrom date
	DECLARE @dtTo date

	IF(@IsScheduledDelete = 1)
	BEGIN
		SET @DataRetentionDays = @DataRetentionDays - 1
		SET @dtTo = CONVERT(DATE, DATEADD(dd,(-1*@DataRetentionDays),GETDATE()))

		DELETE FROM Basiscore_CmsAudit_Items
		WHERE LoggedTime < @dtTo
	END
	ELSE
	BEGIN
		--adding 1 day to passed todate
		SET @ToDate = DATEADD(day, 1, @ToDate)

		SET @dtFrom = CONVERT(DATE, @FromDate)
		SET @dtTo = CONVERT(DATE, @ToDate)

		DELETE FROM Basiscore_CmsAudit_Items
		WHERE LoggedTime BETWEEN @dtFrom AND @dtTo
	END
END
GO
