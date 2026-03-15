@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=C:\Users\taham\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;D:\Work\Freelance\BudgetApp\nodejs22\node-v22.11.0-win-x64;%PATH%"
cd /d "d:\Work\Freelance\BudgetApp\budget-app\android"
call gradlew.bat assembleDebug
if %ERRORLEVEL% NEQ 0 (
    echo BUILD FAILED
    exit /b 1
)
echo.
echo BUILD SUCCESS
echo APK location:
echo   android\app\build\outputs\apk\debug\app-debug.apk
