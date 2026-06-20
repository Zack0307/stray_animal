USE stray_animal;
GO

-- 1️⃣ 宣告變數 
DECLARE @JimId UNIQUEIDENTIFIER;
DECLARE @DatongId UNIQUEIDENTIFIER;

-- 🎯 【核心修正】：配合妳的資料庫，將型態改為 VARCHAR(50) 字串型態！
DECLARE @AniId1 VARCHAR(50); 
DECLARE @AniId2 VARCHAR(50); 

-- 2️⃣ 智慧查表：精準抓出林志明與陳大同的真實 UUID
SELECT TOP 1 @JimId = id FROM Adopter WHERE name = N'林志明';
SELECT TOP 1 @DatongId = id FROM Adopter WHERE name = N'陳大同';

-- 3️⃣ 🎯 【核心修正】：改抓政府的 gov_animal_id 文字欄位
SELECT @AniId1 = MIN(gov_animal_id), @AniId2 = MAX(gov_animal_id) FROM Animal;


-- 🔒 啟動安全交易鎖
BEGIN TRANSACTION;
BEGIN TRY

    -- 💥 紀錄一：幫林志明製造第一次「已駁回」的黑歷史
    INSERT INTO Adoption_application (id, adopter_id, animal_id, status, memo, created_at, updated_at)
    VALUES (
        NEWID(), @JimId, @AniId1, N'已駁回', 
        N'現場環境複查：該住處無陽台防護網，且認養人拒絕配合後續追蹤，予以駁回。', 
        GETDATE(), GETDATE()
    );

    -- 💥 紀錄二：幫林志明製造第二次「跨區被駁回」的黑歷史
    INSERT INTO Adoption_application (id, adopter_id, animal_id, status, memo, created_at, updated_at)
    VALUES (
        NEWID(), @JimId, @AniId2, N'已駁回', 
        N'動保聯合雲端查核：此人過去有不良放養紀錄，不予通過。', 
        GETDATE(), GETDATE()
    );

    -- 👍 紀錄三：幫陳大同建立一筆正常的「審核中」申請
    INSERT INTO Adoption_application (id, adopter_id, animal_id, status, memo, created_at, updated_at)
    VALUES (
        NEWID(), @DatongId, @AniId1, N'審核中', 
        N'第一階段書面審查通過，已預約本週六至現場進行毛孩互動。', 
        GETDATE(), GETDATE()
    );

    COMMIT TRANSACTION;
    PRINT N'🎉 成功！已使用政府 gov_animal_id (VARCHAR) 將測試數據順利植入申請表！';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT N'❌ 新增失敗！原因：' + ERROR_MESSAGE();
END CATCH;
GO