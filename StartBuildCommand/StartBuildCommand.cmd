@echo off 
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0StartBuildCommand.ps1""" -Commands %*"
exit /b %ErrorLevel%