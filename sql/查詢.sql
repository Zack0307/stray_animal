USE stray_animal;
GO


DECLARE @SearchText NVARCHAR(100) = N'柴犬'; 

SELECT 
    A.gov_animal_id AS [中央晶片號碼],
    A.kind AS [動物類型],
    A.variety AS [品種],
    A.colour AS [毛色],
    A.sex AS [性別],
    A.age AS [年齡],
    A.found_place AS [尋獲地點],
    stg.animal_subid AS [收容所內部編號],
    stg.shelter_tel AS [收容所電話],
    stg.animal_remark AS [備註故事]
FROM Animal A

INNER JOIN animal_stage stg ON A.gov_animal_id = stg.animal_id
WHERE A.is_deleted = 0 
  AND (
      
      A.variety LIKE '%' + @SearchText + '%'
      OR A.kind LIKE '%' + @SearchText + '%'
      OR A.colour LIKE '%' + @SearchText + '%'
      OR A.found_place LIKE '%' + @SearchText + '%'
      OR stg.animal_subid LIKE '%' + @SearchText + '%'
      
      OR (ISNUMERIC(@SearchText) = 1 AND TRY_CAST(A.gov_animal_id AS VARCHAR) = @SearchText)
  );
GO