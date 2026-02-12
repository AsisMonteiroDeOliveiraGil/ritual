#!/bin/bash

echo -e "\033[38;5;39m📝 Cambiando títulos de ventanas de Chrome...\033[0m"

# Cambiar títulos de las ventanas
osascript -e 'tell application "Google Chrome"
  repeat with w in windows
    repeat with t in tabs of w
      if URL of t contains "localhost:8080" then
        tell t to execute javascript "document.title = \"iPhone - The Final Burger\""
        log "Título cambiado a iPhone para puerto 8080"
      else if URL of t contains "localhost:8081" then
        tell t to execute javascript "document.title = \"Android - The Final Burger\""
        log "Título cambiado a Android para puerto 8081"
      end if
    end repeat
  end repeat
end tell'

echo -e "\033[38;5;46m✅ Títulos cambiados exitosamente\033[0m"
echo -e "\033[38;5;226m📱 iPhone: localhost:8080\033[0m"
echo -e "\033[38;5;226m📱 Android: localhost:8081\033[0m"
