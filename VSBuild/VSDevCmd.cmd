@echo off 
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0VSDevCmd.ps1""" -Command %*"
exit /b %ErrorLevel%