@echo off
setlocal EnableDelayedExpansion
title RDC AI Dashboard — Windows 11 Installer
echo.
echo ============================================================
echo   RDC AI Dashboard  —  Windows 11 Install
echo ============================================================
echo.

:: ── Check Python ────────────────────────────────────────────
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found.
    echo Please install Python 3.11+ from https://python.org
    echo Make sure to check "Add Python to PATH" during install.
    pause & exit /b 1
)
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PY_VER=%%v
echo [OK] Python %PY_VER% found.

:: ── Set project root (folder containing this script's parent) ──
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..
pushd "%PROJECT_DIR%"
set PROJECT_DIR=%CD%
popd
echo [OK] Project dir: %PROJECT_DIR%

:: ── Create virtual environment ───────────────────────────────
set VENV_DIR=%PROJECT_DIR%\venv
if exist "%VENV_DIR%\Scripts\activate.bat" (
    echo [OK] Virtual environment already exists.
) else (
    echo [..] Creating virtual environment...
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create venv.
        pause & exit /b 1
    )
    echo [OK] Virtual environment created.
)

:: ── Install dependencies ─────────────────────────────────────
echo [..] Installing dependencies (this may take a minute)...
call "%VENV_DIR%\Scripts\activate.bat"
pip install --upgrade pip -q
pip install -r "%PROJECT_DIR%\requirements.txt" -q
if errorlevel 1 (
    echo [ERROR] pip install failed. Check your internet connection.
    pause & exit /b 1
)
echo [OK] Dependencies installed.

:: ── Write launcher .bat ──────────────────────────────────────
set LAUNCHER=%PROJECT_DIR%\launchers\Launch_Dashboard.bat
(
    echo @echo off
    echo call "%VENV_DIR%\Scripts\activate.bat"
    echo python "%PROJECT_DIR%\src\rdc_dashboard.py" %%*
) > "%LAUNCHER%"
echo [OK] Launcher written: %LAUNCHER%

:: ── Desktop shortcut (via PowerShell) ───────────────────────
set DESKTOP=%USERPROFILE%\Desktop
set SHORTCUT=%DESKTOP%\RDC Dashboard.lnk
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $s = $ws.CreateShortcut('%SHORTCUT%'); ^
   $s.TargetPath = '%LAUNCHER%'; ^
   $s.WorkingDirectory = '%PROJECT_DIR%'; ^
   $s.IconLocation = 'shell32.dll,43'; ^
   $s.Description = 'RDC AI Dashboard'; ^
   $s.Save()"
echo [OK] Desktop shortcut created.

:: ── Startup (optional tray launch) ──────────────────────────
set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\RDC_Dashboard_Tray.bat
(
    echo @echo off
    echo call "%VENV_DIR%\Scripts\activate.bat"
    echo start "" pythonw "%PROJECT_DIR%\src\rdc_dashboard.py" --tray
) > "%STARTUP%"
echo [OK] Startup tray entry created (runs on login).

echo.
echo ============================================================
echo   Install complete!
echo   Double-click "RDC Dashboard" on your Desktop to launch.
echo ============================================================
echo.
pause
