@echo off
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0clean.ps1""" -KillBuildProcesses -AdditionalBuildProcesses git,sh,wish %*"
