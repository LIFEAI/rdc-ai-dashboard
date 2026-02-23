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
pause

:: ── Paths ─────────────────────────────────────────────────────
set INSTALL_DIR=%LOCALAPPDATA%\RDC_Dashboard
set TEMP_DIR=%TEMP%\RDC_Dashboard_Install
set REPO_ZIP=%TEMP_DIR%\repo.zip
set REPO_URL=https://github.com/LIFEAI/rdc-ai-dashboard/archive/refs/heads/main.zip

echo  [..] Install location: %INSTALL_DIR%

:: ── Python check ─────────────────────────────────────────────
python --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Python not found. Install from https://python.org then re-run.
    start https://www.python.org/downloads/
    pause & exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  [OK] %%v

:: ── Clean previous ────────────────────────────────────────────
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
if exist "%TEMP_DIR%"    rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
mkdir "%INSTALL_DIR%"

:: ── Download ──────────────────────────────────────────────────
echo  [..] Downloading RDC Dashboard...
powershell -NoProfile -Command "& {[Net.ServicePointManager]::SecurityProtocol='Tls12'; (New-Object Net.WebClient).DownloadFile('%REPO_URL%','%REPO_ZIP%')}"
if not exist "%REPO_ZIP%" ( echo  [ERROR] Download failed. & pause & exit /b 1 )
echo  [OK] Downloaded.

:: ── Extract ───────────────────────────────────────────────────
echo  [..] Extracting...
powershell -NoProfile -Command "Expand-Archive -Path '%REPO_ZIP%' -DestinationPath '%TEMP_DIR%' -Force"
for /d %%d in ("%TEMP_DIR%\rdc-ai-dashboard-*") do xcopy /e /i /q "%%d\*" "%INSTALL_DIR%\" >nul
echo  [OK] Files installed.

:: ── Install dependencies ──────────────────────────────────────
echo  [..] Installing dependencies...
pip install -r "%INSTALL_DIR%\requirements.txt" -q
pip install pillow -q
echo  [OK] Dependencies installed.

:: ── Icons ─────────────────────────────────────────────────────
echo  [..] Generating icons...
python "%INSTALL_DIR%\assets\create_icon.py" >nul 2>&1
echo  [OK] Icons ready.

:: ── Write launcher ────────────────────────────────────────────
(
    echo @echo off
    echo set QT_QPA_PLATFORM_PLUGIN_PATH=%LOCALAPPDATA%\Programs\Python\Python312\Lib\site-packages\PyQt6\Qt6\plugins\platforms
    echo cd /d "%INSTALL_DIR%"
    echo python "%INSTALL_DIR%\src\rdc_dashboard.py"
) > "%INSTALL_DIR%\RDC_Dashboard.bat"

:: ── Desktop shortcut ──────────────────────────────────────────
echo  [..] Creating shortcuts...
powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut([Environment]::GetFolderPath('Desktop')+'\RDC Dashboard.lnk'); $s.TargetPath='%INSTALL_DIR%\RDC_Dashboard.bat'; $s.WorkingDirectory='%INSTALL_DIR%'; $s.IconLocation='%INSTALL_DIR%\assets\icon.ico'; $s.Description='RDC AI Dashboard'; $s.Save()"

:: ── Start Menu ────────────────────────────────────────────────
set START_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\RDC Dashboard
mkdir "%START_DIR%" >nul 2>&1
powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut('%START_DIR%\RDC Dashboard.lnk'); $s.TargetPath='%INSTALL_DIR%\RDC_Dashboard.bat'; $s.WorkingDirectory='%INSTALL_DIR%'; $s.IconLocation='%INSTALL_DIR%\assets\icon.ico'; $s.Description='RDC AI Dashboard'; $s.Save()"
(
    echo @echo off
    echo rmdir /s /q "%INSTALL_DIR%"
    echo del /f /q "%USERPROFILE%\Desktop\RDC Dashboard.lnk"
    echo rmdir /s /q "%START_DIR%"
    echo echo Done. & pause
) > "%START_DIR%\Uninstall RDC Dashboard.bat"
echo  [OK] Shortcuts created.

:: ── Cleanup ───────────────────────────────────────────────────
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

:: ── Done ─────────────────────────────────────────────────────
echo.
echo  ============================================================
echo    Done! Launch from Desktop or Start Menu.
echo  ============================================================
echo.
set /p LAUNCH="  Launch now? (Y/N): "
if /i "%LAUNCH%"=="Y" start "" "%INSTALL_DIR%\RDC_Dashboard.bat"
echo.
pause
