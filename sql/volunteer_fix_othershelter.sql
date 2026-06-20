USE stray_animal;
GO

-- 🎯 【網頁前端傳入】
DECLARE @OperatorName NVARCHAR(50) = N'suba';          -- 目前登入並動手指的員工
DECLARE @TargetGovId  VARCHAR(50)   = '2026060301';    -- 牠想要修改的動物晶片號碼
DECLARE @NewStatus    VARCHAR(20)   = N'醫療中';       -- 牠試圖變更的新狀態

-- 1️⃣ 宣告內部安全查驗變數
DECLARE @CurrentStaffId UNIQUEIDENTIFIER = NULL;
DECLARE @StaffRole       NVARCHAR(20)     = NULL;
DECLARE @MyShelterID     UNIQUEIDENTIFIER = NULL;  -- 裝「志工」的收容所 ID
DECLARE @AnimalShelterID UNIQUEIDENTIFIER = NULL;  -- 裝「毛孩」的收容所 ID

-- 🎯 【核心修正點】：宣告兩個文字變數，預備用來裝轉型後的收容所 ID 字串
DECLARE @MyShelterIDStr     VARCHAR(50) = '';
DECLARE @AnimalShelterIDStr   VARCHAR(50) = '';

-- 2️⃣ 【精準查驗志工】去 staff 表撈出這個人的真實 ID、角色、以及他工作的收容所
SELECT TOP 1 
    @CurrentStaffId = id,
    @StaffRole       = role,
    @MyShelterID     = shelter_id
FROM staff 
WHERE name = @OperatorName;

-- 3️⃣ 【核心步驟】：去 Animal 表，悄悄撈出這隻動物實際上歸屬於哪間收容所
SELECT TOP 1
    @AnimalShelterID = shelter_id
FROM Animal
WHERE gov_animal_id = @TargetGovId;

-- 🎯 【核心修正點】：在進防線前，先幫 UNIQUEIDENTIFIER 做好轉型，洗成純字串！
SET @MyShelterIDStr = ISNULL(CONVERT(VARCHAR(50), @MyShelterID), 'NULL');
SET @AnimalShelterIDStr = ISNULL(CONVERT(VARCHAR(50), @AnimalShelterID), 'NULL');


-- ===================================================
-- 🔐 🎯【核心權限門神：五道防線聯合鎖定】
-- ===================================================

-- 🛑 第一道防線：檢查操作者是不是我們系統的員工？
IF @CurrentStaffId IS NULL
BEGIN
    RAISERROR(N'❌ 權限攔截：操作失敗！【%s】並不在員工資料表中，此為非法操作！', 16, 1, @OperatorName);
END

-- 🛑 第二道防線：是員工沒錯，但檢查他的角色到底是不是「志工」？
ELSE IF @StaffRole <> N'志工'
BEGIN
    RAISERROR(N'❌ 權限攔截：操作失敗！【%s】的層級為【%s】，此功能限定【志工】層級才能操作！', 16, 1, @OperatorName, @StaffRole);
END

-- 🛑 第三道防線：是志工沒錯，但檢查他有沒有被指派收容所園區？
ELSE IF @MyShelterID IS NULL
BEGIN
    RAISERROR(N'❌ 權限攔截：操作失敗！志工【%s】尚未綁定任何收容所園區，無法操作！', 16, 1, @OperatorName);
END

-- 🛑 第四道防線：防呆！檢查網頁傳過來的晶片號碼，在資料庫裡到底存不存在？
ELSE IF @AnimalShelterID IS NULL
BEGIN
    RAISERROR(N'❌ 修改失敗：資料庫中查無中央晶片號碼為【%s】的動物資料！', 16, 1, @TargetGovId);
END

-- 🛑 第五道防線：🔥【跨區核對】🔥
-- 拿「志工上班的收容所」對決「毛孩所在的收容所」
ELSE IF @MyShelterID <> @AnimalShelterID
BEGIN
    -- 🎯 【核心修正點】：移除了內在的 CONVERT 函式，改為直接帶入剛剛算好的字串變數，安全通車！
    RAISERROR(
        N'🛑 安全警報！權限攔截成功：志工【%s】企圖跨區修改其他收容所的毛孩資料！[您的園區ID: %s ❌ 目標毛孩園區ID: %s]', 
        16, 
        1, 
        @OperatorName, 
        @MyShelterIDStr, 
        @AnimalShelterIDStr
    );
END

-- 🟢 【全線完美通過】所有安全規範全部吻合，代表要改的是自己家的狗，准予修改！
ELSE
BEGIN
    UPDATE Animal
    SET status = @NewStatus,
        updated_at = GETDATE()
    WHERE gov_animal_id = @TargetGovId;

    PRINT N'✨ [安全認證通過] 志工 【' + @OperatorName + N'】 已成功更新自家園區動物 [' + @TargetGovId + N'] 的狀態為【' + @NewStatus + N'】！';
END
GO