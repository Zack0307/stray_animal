USE stray_animal;
GO

-- 🎯 【網頁前端傳入】目前在後台點擊按鈕的員工姓名 (可以用妳 staff 表裡現有的名字測試)
DECLARE @OperatorName NVARCHAR(50) = N'suba'; 

-- 1️⃣ 宣告用來暫存檢查結果的變數
DECLARE @CurrentStaffId UNIQUEIDENTIFIER = NULL;
DECLARE @StaffRole       NVARCHAR(20)     = NULL;
DECLARE @MyShelterID     UNIQUEIDENTIFIER = NULL;

-- 2️⃣ 【精準查驗身分】去 staff 表撈出這個人的真實 ID、角色、以及他工作的收容所
SELECT TOP 1 
    @CurrentStaffId = id,
    @StaffRole       = role,
    @MyShelterID     = shelter_id
FROM staff 
WHERE name = @OperatorName;

-- 3️⃣ 準備要上架的毛孩新資料
DECLARE @GovId VARCHAR(50)   = '2026060302'; 
DECLARE @Kind VARCHAR(20)    = '貓';
DECLARE @Variety VARCHAR(50) = N'美短';
DECLARE @Sex CHAR(1)         = 'F';
DECLARE @Status VARCHAR(20)  = N'開放'; 


-- ===================================================
-- 🔐 🎯【核心權限門神：三重防禦機制發動】
-- ===================================================

-- 🛑 第一道防線：檢查這個人到底是不是我們公司的員工？
IF @CurrentStaffId IS NULL
BEGIN
    RAISERROR(N'❌ 權限攔截：操作失敗！【%s】並不在 staff 員工資料表中，此為非法操作！', 16, 1, @OperatorName);
END

-- 🛑 第二道防線：是員工沒錯，但檢查他的角色到底是不是「志工」？
ELSE IF @StaffRole <> N'志工'
BEGIN
    RAISERROR(N'❌ 權限攔截：操作失敗！【%s】的層級為【%s】，此功能限定【志工】層級才能操作！', 16, 1, @OperatorName, @StaffRole);
END

-- 🛑 第三道防線：是志工沒錯，但檢查他有沒有被指派收容所園區？
ELSE IF @MyShelterID IS NULL
BEGIN
    RAISERROR(N'❌ 權限攔截：操作失敗！志工【%s】尚未綁定任何收容所園區 (shelter_id 為空)，無法上架毛孩！', 16, 1, @OperatorName);
END

-- 🟢 【全線通過】身分正確、角色吻合、園區對齊 ➔ 准予放行寫入！
ELSE
BEGIN
    INSERT INTO Animal (id, shelter_id, gov_animal_id, kind, variety, sex, status, is_sterilized, is_vaccinated)
    VALUES (NEWID(), @MyShelterID, @GovId, @Kind, @Variety, @Sex, @Status, 0, 0);

    PRINT N'🐾 [安全認證通過] 志工 【' + @OperatorName + N'】 已成功為自家園區上架一隻新貓咪 [' + @GovId + N']！';
END
GO