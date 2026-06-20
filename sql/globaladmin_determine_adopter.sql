USE stray_animal;
GO

-- 🎯 【網頁前端傳入面板】
DECLARE @OperatorName   NVARCHAR(50) = N'大波士超級管理員';          -- 登入操作的大波士姓名
DECLARE @TargetAppID    UNIQUEIDENTIFIER = NULL;        -- 準備審核的申請單 ID
DECLARE @ReviewResult   VARCHAR(20)  = '已通過';        -- 審核決策：'已通過' 或 '拒絕'
DECLARE @ReviewMemo     NVARCHAR(MAX) = N'最高管理員親自拒絕：認養人各項條件極佳，予以通過！';

-- 1️⃣ 智慧防空：若沒有指定 App ID，我們先自動抓取資料庫內目前第一筆「審核中」的申請單來測試
SELECT TOP 1 @TargetAppID = id FROM Adoption_Application WHERE status = '審核中';


-- 2️⃣ 宣告內部核心審查變數
DECLARE @CurrentStaffId   UNIQUEIDENTIFIER = NULL;
DECLARE @StaffRole         NVARCHAR(20)     = NULL;
DECLARE @AdopterID         UNIQUEIDENTIFIER = NULL;
DECLARE @GovAnimalID       VARCHAR(50)      = NULL;
DECLARE @AdopterName       NVARCHAR(50)     = NULL;
DECLARE @PastRejections    INT              = 0; -- 累計被拒次數


-- 3️⃣ 【大數據情資蒐集】跨表撈出這筆申請單的詳細身世（認養人是誰、申請哪隻動物）
SELECT TOP 1 
    @AdopterID   = App.adopter_id,
    @GovAnimalID = App.animal_id,
    @AdopterName = Ad.name
FROM Adoption_Application App
INNER JOIN Adopter Ad ON App.adopter_id = Ad.id
WHERE App.id = @TargetAppID;

-- 4️⃣ 【大數據情資蒐集】自動算出這個人在「全台灣所有園區」過去累積被拒絕過幾次
IF @AdopterID IS NOT NULL
BEGIN
    SELECT @PastRejections = COUNT(*) 
    FROM Adoption_Application 
    WHERE adopter_id = @AdopterID AND status = '拒絕';
END


-- ===================================================
-- 🔐 🎯【第一階段：大波士天神身分驗證防線】
-- ===================================================

-- 去 staff 表查出目前的審核者是不是大波士管理員
SELECT TOP 1 @CurrentStaffId = id, @StaffRole = role FROM staff WHERE name = @OperatorName;

IF @CurrentStaffId IS NULL
BEGIN
    RAISERROR(N'❌ 審核失敗：操作者【%s】並非系統登記員工！', 16, 1, @OperatorName);
END
ELSE IF @StaffRole <> N'管理員'
BEGIN
    -- 🛡️ 成功攔截：如果是普通志工想用這個最高權限，當場轟出去！
    RAISERROR(N'❌ 權限攔截：志工層級無法啟動「全域會審機制」，請使用專屬志工面板！', 16, 1);
END
ELSE IF @TargetAppID IS NULL
BEGIN
    RAISERROR(N'❌ 審核失敗：目前資料庫中沒有任何處於【審核中】的申請單供您審查！', 16, 1);
END


-- ===================================================
-- ⚡ 🎯【第二階段：全線放行 ➔ 啟動資料庫多表聯動齒輪】
-- ===================================================
ELSE
BEGIN
    -- 🔒 啟動安全交易鎖，確保多表更新要嘛全部成功，要嘛全部失敗
    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- 🌟 動作 A：更新申請單狀態
        UPDATE Adoption_Application
        SET status = @ReviewResult,
            memo = @ReviewMemo,
            updated_at = GETDATE()
        WHERE id = @TargetAppID;

        -- 🌟 動作 B：【智慧聯動機制】
        -- 如果大波士批准了 ('已通過')，自動把 Animal 表的動物狀態切換為 '已認養'
        IF @ReviewResult = '已通過'
        BEGIN
            UPDATE Animal
            SET status = N'已認養', updated_at = GETDATE()
            WHERE gov_animal_id = @GovAnimalID;
        END

        -- 🌟 動作 C：【不可否認性】自動寫入中央資安審計日誌 (Audit_Log)
        DECLARE @LogText NVARCHAR(MAX);
        SET @LogText = N'管理員審核民眾 [' + @AdopterName + N'] 認養晶片 [' + @GovAnimalID + N'] 的申請。決策：【' + CONVERT(NVARCHAR(20), @ReviewResult) + N'】。(該民眾歷史被拒次數：' + CAST(@PastRejections AS NVARCHAR(10)) + N' 次)';

        INSERT INTO Audit_Log (user_id, name, action, details)
        VALUES (@CurrentStaffId, @OperatorName, 'UPDATE', @LogText);


        -- 📯 萬事具備，提交所有齒輪變更！
        COMMIT TRANSACTION;
        
        PRINT N'======================================================';
        PRINT N'🎉 【最高審核通車成功】';
        PRINT N'👤 審核主管：' + @OperatorName + N' (層級：管理員)';
        PRINT N'📝 領養人姓名：' + @AdopterName + N' (全台累計歷史被拒：' + CAST(@PastRejections AS NVARCHAR(10)) + N' 次)';
        PRINT N'🐾 申請毛孩晶片：' + @GovAnimalID;
        PRINT N'📢 最終決策：【' + CONVERT(NVARCHAR(20), @ReviewResult) + N'】';
        IF @ReviewResult = '已通過' PRINT N'⚙️  [系統自動聯動]：該毛孩在 Animal 表中的狀態已自動切換為【已認養】！';
        PRINT N'======================================================';

    END TRY
    BEGIN CATCH
        -- 發生任何意外，全部退回重來，不弄髒資料庫
        ROLLBACK TRANSACTION;
        PRINT N'❌ 審核執行崩潰！原因：' + ERROR_MESSAGE();
    END CATCH;
END
GO