#!/bin/bash

# Path to ESET Antivirus uninstaller
ESET_ANTIVIRUS_UNINSTALLER="/Applications/ESET Endpoint Antivirus.app/Contents/Helpers/Uninstaller.app/Contents/Scripts/uninstall.sh"

# Path to ESET Security uninstaller
ESET_SECURITY_UNINSTALLER="/Applications/ESET Endpoint Security.app/Contents/Helpers/Uninstaller.app/Contents/Scripts/uninstall.sh"

# Check for ESET Antivirus
if [ -f "$ESET_ANTIVIRUS_UNINSTALLER" ]; then
  echo "ESET Antivirus found. Initiating uninstallation..."
  sudo "$ESET_ANTIVIRUS_UNINSTALLER"
  
  echo "Cleaning up ESET Antivirus leftovers..."
  sudo rm -Rf "/Applications/ESET Endpoint Antivirus.app/"
  sudo rm -Rf "/Library/LaunchAgents/com.eset.esets_gui.plist"
  sudo rm -Rf "/Library/LaunchAgents/com.eset.firewall.prompt.plist"
  
  echo "ESET Antivirus uninstallation and cleanup complete."
  
# Check for ESET Security
elif [ -f "$ESET_SECURITY_UNINSTALLER" ]; then
  echo "ESET Security found. Initiating uninstallation..."
  sudo "$ESET_SECURITY_UNINSTALLER"
  
  echo "Cleaning up ESET Security leftovers..."
  sudo rm -Rf "/Applications/ESET Endpoint Security.app/"
  sudo rm -Rf "/Library/LaunchAgents/com.eset.esets_gui.plist"
  sudo rm -Rf "/Library/LaunchAgents/com.eset.firewall.prompt.plist"
  
  echo "ESET Security uninstallation and cleanup complete."
  
# Neither ESET product found
else
  echo "No ESET products found. Exiting."
fi
