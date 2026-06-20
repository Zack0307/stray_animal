USE stray_animal;
GO


DECLARE @NewID INT = 2026060210;                
DECLARE @Kind NVARCHAR(10) = N'狗';             
DECLARE @Variety NVARCHAR(50) = N'柴犬';         
DECLARE @Colour NVARCHAR(50) = N'赤柴色';        
DECLARE @Sex VARCHAR(5) = 'M';                  
DECLARE @Age VARCHAR(10) = 'CHILD';             
DECLARE @BodyType VARCHAR(20) = 'MEDIUM';       
DECLARE @FoundPlace NVARCHAR(255) = N'屏東市';  
DECLARE @Remark NVARCHAR(MAX) = N'尾巴會像直升機一樣瘋狂旋轉，非常親人！'; 
DECLARE @Photo VARCHAR(500) = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e'; 


DECLARE @ShelterID UNIQUEIDENTIFIER;
SELECT TOP 1 @ShelterID = id FROM Shelter; 


BEGIN TRANSACTION;

BEGIN TRY
    
    INSERT INTO Animal (
        gov_animal_id, kind, variety, colour, status, sex, age, 
        is_sterilized, is_vaccinated, found_place, shelter_id, is_deleted,
        gov_subid, body_type
    )
    VALUES (
        @NewID, @Kind, @Variety, @Colour, N'開放', @Sex, @Age, 
        0, 0, @FoundPlace, @ShelterID, 0, '---', @BodyType
    );

    
    INSERT INTO animal_stage (
        animal_id, animal_subid, animal_area_pkid, animal_shelter_pkid, 
        animal_place, animal_kind, animal_Variety, animal_sex, 
        animal_bodytype, animal_colour, animal_age, animal_sterilization, 
        animal_bacterin, animal_foundplace, animal_title, animal_status, 
        animal_remark, animal_caption, animal_opendate, animal_closeddate, 
        animal_update, animal_createtime, shelter_name, album_file, 
        album_update, cDate, shelter_address, shelter_tel
    )
    VALUES (
        @NewID, '---', 0, 0, 
        @FoundPlace, @Kind, @Variety, @Sex,
        @BodyType, @Colour, @Age, '0',
        '0', @FoundPlace, '', N'開放',
        @Remark, '', GETDATE(), GETDATE(),
        GETDATE(), GETDATE(), '---', @Photo,
        GETDATE(), GETDATE(), '---', '---'
    );

    
    COMMIT TRANSACTION;
    PRINT N'🎉🎉🎉 恭喜！新毛孩已突破所有封鎖線，成功同步寫入雙表！';
    
    
    SELECT A.gov_animal_id, A.kind, A.variety, A.body_type, stg.animal_remark 
    FROM Animal A
    INNER JOIN animal_stage stg ON A.gov_animal_id = stg.animal_id
    WHERE A.gov_animal_id = @NewID;

END TRY
BEGIN CATCH
    
    ROLLBACK TRANSACTION;
    PRINT N'❌ 新增失敗！錯誤原因：' + ERROR_MESSAGE();
END CATCH;
GO