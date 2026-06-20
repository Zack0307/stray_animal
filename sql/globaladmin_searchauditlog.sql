USE stray_animal;
GO

-- 🎯 【智慧日誌篩選面板】測試時先將篩選全部留空 ''，把 DaysAgo 放寬，確保能抓到所有歷史
DECLARE @FilterStaffName NVARCHAR(50) = N'';        
DECLARE @FilterAction NVARCHAR(50)    = N'';  -- 填 '' 代表連 INSERT/UPDATE 一起抓出來看
DECLARE @DaysAgo INT                  = 30;         

SELECT 
    L.created_at AS [操作精準時間],
    L.user_id AS [日誌內記載的員工ID],
    
    -- 💡 觀察重點：如果這裡顯示 NULL，代表你日誌填的 ID 在 staff 表根本不存在！
    ISNULL(ST.name, N'⚠️ 查無此志工(ID未對接)') AS [操作人員姓名],
    ST.role AS [人員職位],
    
    -- 💡 觀察重點：如果這裡顯示 NULL，代表這位志工在 staff 表裡沒有填寫正確的 shelter_id！
    ISNULL(SH.name, N'⚠️ 員工未綁定收容所') AS [所屬收容所園區],
    
    L.action AS [敏感動作],
    L.details AS [詳細軌跡內容]
FROM Audit_Log L

-- 🎯 1. 改用 LEFT JOIN，且精準對接你的新增欄位 user_id
LEFT JOIN staff ST ON L.user_id = ST.id

-- 🎯 2. 改用 LEFT JOIN，對接員工的所屬收容所
LEFT JOIN shelter SH ON ST.shelter_id = SH.id

WHERE L.created_at >= DATEADD(DAY, -@DaysAgo, GETDATE()) 
  AND (@FilterStaffName = '' OR ST.name = @FilterStaffName)
  AND (@FilterAction = '' OR L.action = @FilterAction)
ORDER BY L.created_at DESC; 
GO