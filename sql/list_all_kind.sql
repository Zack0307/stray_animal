USE stray_animal;
GO

SELECT 
    gov_animal_id AS [中央晶片號碼],
    kind          AS [動物類型],
    variety       AS [品種],
    colour        AS [毛色],
    sex           AS [性別],
    age           AS [年齡],
    status        AS [目前狀態]
FROM Animal
-- 🎯 核心過濾：只抓狗狗！
WHERE kind = N'貓'; 
GO