@echo off 
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0CreateTestHost.ps1""" %*"
exit /b %ErrorLevel%