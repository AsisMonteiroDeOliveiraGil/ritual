#!/bin/bash

echo "📐 Capturando posiciones actuales de todas las ventanas..."
echo ""
echo "=== CURSOR ==="
osascript -e 'tell application "System Events"
  tell process "Cursor"
    repeat with w in windows
      set winPos to position of w
      set winSize to size of w
      set xPos to item 1 of winPos
      set yPos to item 2 of winPos
      set winWidth to item 1 of winSize
      set winHeight to item 2 of winSize
      log "Cursor - x:" & xPos & " y:" & yPos & " w:" & winWidth & " h:" & winHeight & " bounds:{" & xPos & "," & yPos & "," & (xPos + winWidth) & "," & (yPos + winHeight) & "}"
    end repeat
  end tell
end tell' 2>&1 | grep "Cursor -"

echo ""
echo "=== CHROME (todas las ventanas visibles) ==="
osascript -e 'tell application "System Events"
  set chromeProcs to every process whose name contains "Chrome"
  repeat with proc in chromeProcs
    set procName to name of proc
    tell proc
      repeat with w in windows
        try
          set winPos to position of w
          set winSize to size of w
          set winTitle to name of w
          set xPos to item 1 of winPos
          set yPos to item 2 of winPos  
          set winWidth to item 1 of winSize
          set winHeight to item 2 of winSize
          log procName & " | " & winTitle & " - x:" & xPos & " y:" & yPos & " w:" & winWidth & " h:" & winHeight & " bounds:{" & xPos & "," & yPos & "," & (xPos + winWidth) & "," & (yPos + winHeight) & "}"
        end try
      end repeat
    end tell
  end repeat
end tell' 2>&1 | grep -E "(The Final Burger|localhost|DevTools)" | sort -u

echo ""
echo "Por favor indica qué ventana corresponde a cada puerto:"
echo "  - ¿Cuál es la ventana del puerto 8080?"
echo "  - ¿Cuál es la ventana del puerto 8081?"

