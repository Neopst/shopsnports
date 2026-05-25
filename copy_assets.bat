@echo off
cd admin\admin
echo Copying assets to web build...
xcopy assets\icons build\web\assets\icons\ /E /Y
if %ERRORLEVEL% EQU 0 (
    echo Assets copied successfully!
) else (
    echo Failed to copy assets
)
cd ..\..\
