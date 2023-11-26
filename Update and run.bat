@echo off

if exist .git (
echo Attempting to update - requires GIT to be installed
git pull
) else (
echo Auto update requires GIT clone of repository
)

start run.bat
timeout /t 3 > nul
