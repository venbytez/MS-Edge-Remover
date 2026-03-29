# MS Edge Remover by venbytez

A batch script for Windows 10/11 that removes Microsoft Edge, cleans leftovers, and helps reduce automatic reinstallation.

## Features

- Stops Edge-related processes
- Attempts uninstall with `setup.exe --uninstall`
- Removes Edge leftover folders
- Removes Edge update services and scheduled tasks (if present)
- Applies registry policies to limit Edge install/update behavior
- Optional startup **Guard** for recurring cleanup
- Built-in **Quick verify** menu option

## What It Does Not Do

- It does **not** guarantee 100% permanent blocking after every future Windows update
- It does **not** remove WebView2 (kept for compatibility with other apps)

## Requirements

- Windows 10 or Windows 11
- Administrator privileges

## Usage

1. Run `EdgeRemover.bat` as **Administrator**
2. Select a menu option:
   - `1` Remove Edge + clean leftovers + apply block + install guard
   - `2` Install/update guard only
   - `3` Remove guard
   - `4` Quick verify
3. Restart your PC after major actions
4. Run Quick verify again after major Windows updates

## Guard (Optional)

Guard is a startup task that re-checks and re-cleans Edge-related components at boot.

- Script path: `%ProgramData%\EdgeGuard\EdgeGuard.cmd`
- Task name: `EdgeGuardStartup`

## Safety Notes

- This tool changes system folders, services/tasks, and registry policies
- Create a restore point before use
- Use at your own risk

## Disclaimer

This project is provided **as is**, without warranty.  
The author is not responsible for system issues, compatibility problems, or data loss.
