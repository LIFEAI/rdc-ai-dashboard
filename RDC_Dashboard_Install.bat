@echo off
setlocal EnableDelayedExpansion
title RDC Dashboard — Installer
color 0A

echo.
echo  ============================================================
echo    RDC Dashboard Installer
echo    Regenerative Development Corp
echo  ============================================================
echo.
echo  This will install RDC Dashboard to your computer.
echo  No Git or technical setup required.
echo.
pause

:: ── Admin check (request elevation if needed) ─────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [..] Requesting administrator rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ── Install location ──────────────────────────────────────────
set INSTALL_DIR=%LOCALAPPDATA%\RDC_Dashboard
set TEMP_DIR=%TEMP%\RDC_Dashboard_Install
set REPO_ZIP=%TEMP_DIR%\repo.zip
set REPO_URL=https://github.com/LIFEAI/rdc-ai-dashboard/archive/refs/heads/main.zip

echo  [..] Install location: %INSTALL_DIR%
echo.

:: ── Python check ─────────────────────────────────────────────
echo  [..] Checking for Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] Python is not installed.
    echo.
    echo  Please install Python 3.11 from:
    echo  https://www.python.org/downloads/
    echo.
    echo  IMPORTANT: Check "Add Python to PATH" during install,
    echo             then re-run this installer.
    echo.
    start https://www.python.org/downloads/
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PY_VER=%%i
echo  [OK] Found %PY_VER%

:: ── Create temp and install dirs ─────────────────────────────
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
mkdir "%INSTALL_DIR%"

:: ── Download repo zip from GitHub ─────────────────────────────
echo  [..] Downloading RDC Dashboard from GitHub...
powershell -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
    "Invoke-WebRequest -Uri '%REPO_URL%' -OutFile '%REPO_ZIP%' -UseBasicParsing"
if not exist "%REPO_ZIP%" (
    echo  [ERROR] Download failed. Check your internet connection and try again.
    pause & exit /b 1
)
echo  [OK] Download complete.

:: ── Extract repo ──────────────────────────────────────────────
echo  [..] Extracting files...
powershell -NoProfile -Command ^
    "Expand-Archive -Path '%REPO_ZIP%' -DestinationPath '%TEMP_DIR%' -Force"

:: Find the extracted folder (GitHub adds -main suffix)
for /d %%d in ("%TEMP_DIR%\rdc-ai-dashboard-*") do set EXTRACTED=%%d
if not defined EXTRACTED (
    echo  [ERROR] Extraction failed.
    pause & exit /b 1
)

:: Copy to install dir
xcopy /e /i /q "%EXTRACTED%\*" "%INSTALL_DIR%\" >nul
echo  [OK] Files installed to %INSTALL_DIR%

:: ── Create Python venv ────────────────────────────────────────
echo  [..] Setting up Python environment (first time only, ~2 min)...
python -m venv "%INSTALL_DIR%\venv"
if %errorlevel% neq 0 (
    echo  [ERROR] Failed to create Python environment.
    pause & exit /b 1
)

:: ── Install dependencies ──────────────────────────────────────
echo  [..] Installing dependencies...
"%INSTALL_DIR%\venv\Scripts\pip.exe" install --upgrade pip -q
"%INSTALL_DIR%\venv\Scripts\pip.exe" install -r "%INSTALL_DIR%\requirements.txt" -q
"%INSTALL_DIR%\venv\Scripts\pip.exe" install pillow -q
echo  [OK] Dependencies installed.

:: ── Generate icon ─────────────────────────────────────────────
echo  [..] Generating icons...
"%INSTALL_DIR%\venv\Scripts\python.exe" "%INSTALL_DIR%\assets\create_icon.py" >nul 2>&1
echo  [OK] Icons ready.

:: ── Create launcher script ────────────────────────────────────
echo  [..] Creating launcher...
(
    echo @echo off
    echo cd /d "%INSTALL_DIR%"
    echo start "" "%INSTALL_DIR%\venv\Scripts\pythonw.exe" "%INSTALL_DIR%\src\rdc_dashboard.py"
) > "%INSTALL_DIR%\RDC_Dashboard.bat"

:: ── Desktop shortcut ──────────────────────────────────────────
echo  [..] Creating desktop shortcut...
powershell -NoProfile -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\RDC Dashboard.lnk'); " ^
    "$s.TargetPath = '%INSTALL_DIR%\RDC_Dashboard.bat'; " ^
    "$s.WorkingDirectory = '%INSTALL_DIR%'; " ^
    "$s.IconLocation = '%INSTALL_DIR%\assets\icon.ico'; " ^
    "$s.Description = 'RDC AI Dashboard'; " ^
    "$s.Save()"
echo  [OK] Desktop shortcut created.

:: ── Start Menu shortcut ───────────────────────────────────────
set START_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\RDC Dashboard
mkdir "%START_DIR%" >nul 2>&1
powershell -NoProfile -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$s = $ws.CreateShortcut('%START_DIR%\RDC Dashboard.lnk'); " ^
    "$s.TargetPath = '%INSTALL_DIR%\RDC_Dashboard.bat'; " ^
    "$s.WorkingDirectory = '%INSTALL_DIR%'; " ^
    "$s.IconLocation = '%INSTALL_DIR%\assets\icon.ico'; " ^
    "$s.Description = 'RDC AI Dashboard'; " ^
    "$s.Save()"

:: Uninstaller shortcut in Start Menu
(
    echo @echo off
    echo echo Uninstalling RDC Dashboard...
    echo rmdir /s /q "%INSTALL_DIR%"
    echo del /f /q "%USERPROFILE%\Desktop\RDC Dashboard.lnk"
    echo rmdir /s /q "%START_DIR%"
    echo echo Done.
    echo pause
) > "%START_DIR%\Uninstall RDC Dashboard.bat"

echo  [OK] Start Menu shortcuts created.

:: ── Cleanup temp ─────────────────────────────────────────────
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

:: ── Done ─────────────────────────────────────────────────────
echo.
echo  ============================================================
echo    Installation complete!
echo.
echo    RDC Dashboard is now installed.
echo    Launch it from your Desktop or Start Menu.
echo  ============================================================
echo.

set /p LAUNCH="  Launch RDC Dashboard now? (Y/N): "
if /i "%LAUNCH%"=="Y" (
    start "" "%INSTALL_DIR%\RDC_Dashboard.bat"
)

echo.
echo  Thank you. Life before Profits.
echo.
pause
