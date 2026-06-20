USE stray_animal;
GO


DECLARE @TargetID INT = 2026060210;              

DECLARE @NewVariety NVARCHAR(50) = N'柴犬';     
DECLARE @NewColour NVARCHAR(50)  = N'赤柴色';   
DECLARE @NewPlace NVARCHAR(255)  = N'內湖區';  
DECLARE @NewPhoto VARCHAR(500)   = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e';
DECLARE @NewRemark NVARCHAR(MAX) = N'牠今天學會坐下了，非常聰明！';  


BEGIN TRANSACTION;

BEGIN TRY
    
    UPDATE Animal
    SET variety = @NewVariety,
        colour = @NewColour,
        found_place = @NewPlace
    WHERE gov_animal_id = @TargetID;

    
    UPDATE animal_stage
    SET album_file = @NewPhoto,
        animal_remark = @NewRemark,
        animal_place = @NewPlace
    WHERE animal_id = @TargetID;

    
    COMMIT TRANSACTION;
    PRINT N'🎉 雙表修改成功！資料已完全同步。';
END TRY
BEGIN CATCH
   
    ROLLBACK TRANSACTION;
    PRINT N'❌ 修改失敗！錯誤原因：' + ERROR_MESSAGE();
END CATCH;
GO