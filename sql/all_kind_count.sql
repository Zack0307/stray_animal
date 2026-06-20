USE stray_animal;
GO

-- 🎯 想看什麼動物的排行榜？可以自由改成 N'貓' 或 N'狗'
DECLARE @SearchKind NVARCHAR(20) = N'狗'; 

SELECT 
    variety AS [品種名稱],
    COUNT(*) AS [全台灣收容總隻數] -- 自動算出這個品種有幾隻
FROM Animal
WHERE kind = @SearchKind
  AND variety IS NOT NULL
  AND variety <> ''
GROUP BY variety                  -- 依品種分組
ORDER BY [全台灣收容總隻數] DESC; -- 數量最多的排在最上面（例如：米克斯、柴犬）
GO 