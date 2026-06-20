USE stray_animal;
GO


DECLARE @LoginStaffID UNIQUEIDENTIFIER;
SELECT TOP 1 @LoginStaffID = id FROM staff WHERE role = N'志工' AND name LIKE N'suba'; 


DECLARE @MyShelterID UNIQUEIDENTIFIER;
DECLARE @MyRole NVARCHAR(20);
SELECT @MyShelterID = shelter_id, @MyRole = role FROM staff WHERE id = @LoginStaffID;


SELECT 
    A.gov_animal_id AS [晶片號碼],
    A.kind AS [類型],
    A.variety AS [品種],
    A.status AS [當前狀態],
    A.found_place AS [尋獲地點]
FROM Animal A
WHERE A.is_deleted = 0
  
  AND A.shelter_id = @MyShelterID; 
GO