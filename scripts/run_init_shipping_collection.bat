@echo off
REM Initialize shippingRequests Firestore Collection
REM Usage: run_init_shipping_collection.bat

echo.
echo Initializing shippingRequests Firestore Collection
echo.

REM Get the project root
for %%I in ("%~dp0..") do set "projectRoot=%%~fI"

REM Check if Node script exists
if not exist "%projectRoot%\scripts\init_shipping_requests_collection.js" (
    echo ERROR: Script not found: %projectRoot%\scripts\init_shipping_requests_collection.js
    echo Please ensure init_shipping_requests_collection.js is in the scripts folder
    exit /b 1
)

REM Check if service account key exists
if not exist "%projectRoot%\functions\serviceAccountKey.json" (
    echo ERROR: Firebase service account key not found
    echo Expected at: %projectRoot%\functions\serviceAccountKey.json
    echo.
    echo To get your service account key:
    echo 1. Go to Firebase Console: https://console.firebase.google.com
    echo 2. Select shopsnports project
    echo 3. Click Project Settings icon (gear)
    echo 4. Go to Service Accounts tab
    echo 5. Click Generate New Private Key
    echo 6. Save JSON file as serviceAccountKey.json in the functions folder
    echo.
    exit /b 1
)

echo SUCCESS: Service account key found
echo.
echo Running initialization...
echo ======================================
echo.

REM Run the Node.js script
node "%projectRoot%\scripts\init_shipping_requests_collection.js"

set exitCode=%ERRORLEVEL%

echo.
echo ======================================

if %exitCode% equ 0 (
    echo SUCCESS: Collection initialized successfully!
    echo Ready to receive shipping requests
    echo.
) else (
    echo ERROR: Initialization failed (Exit code: %exitCode%)
)

exit /b %exitCode%
