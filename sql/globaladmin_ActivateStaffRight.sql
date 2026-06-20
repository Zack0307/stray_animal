USE stray_animal;
GO

-- 🎯 【大波士人事控制面板】
DECLARE @TargetStaffName NVARCHAR(50) = N'suba'; -- 輸入你想處置的員工姓名
DECLARE @Action NVARCHAR(20)          = N'核准啟用';   -- 可輸入：N'核准啟用' 或 N'停權'

-- 🔒 人事防錯交易鎖
BEGIN TRANSACTION;
BEGIN TRY
    IF @Action = N'核准啟用'
        BEGIN
            UPDATE staff 
            SET status = N'已啟用' 
            WHERE name = @TargetStaffName AND status = N'審核中';
            PRINT N'🎉 成功！已將新志工 [' + @TargetStaffName + N'] 的帳號正式開通啟用。';
        END
    ELSE IF @Action = N'停權'
        BEGIN
            UPDATE staff 
            SET status = N'已停權' 
            WHERE name = @TargetStaffName;
            PRINT N'⛔ 警告！已將員工 [' + @TargetStaffName + N'] 強制停權封鎖，該帳號即刻失效。';
        END

    -- 顯示該員工異動後的最新狀態
    SELECT id, name, email, role, status FROM staff WHERE name = @TargetStaffName;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT N'❌ 人事異動失敗！原因：' + ERROR_MESSAGE();
END CATCH;
GO