#!/bin/bash

set -euo pipefail

echo -ne "\033]0;android_emulator_bigger\007"

DEFAULT_HEIGHT=3200
DEFAULT_X=80
DEFAULT_Y=40

TARGET_HEIGHT="${1:-$DEFAULT_HEIGHT}"
TARGET_X="${TARGET_X:-$DEFAULT_X}"
TARGET_Y="${TARGET_Y:-$DEFAULT_Y}"

if ! command -v osascript >/dev/null 2>&1; then
  echo "❌ osascript not available."
  exit 1
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "❌ adb not available in PATH."
  exit 1
fi

connected_devices=$(adb devices | grep 'emulator-' | awk '{print $1}')

if [ -z "$connected_devices" ]; then
  echo "❌ No Android emulators detected."
  exit 1
fi

echo "📱 Android emulators detected:"
echo "$connected_devices"
echo ""

APPLE_SCRIPT=$(cat <<EOF
set targetHeight to $TARGET_HEIGHT
set targetX to $TARGET_X
set targetY to $TARGET_Y

set reportLines to {}

tell application "System Events"
  repeat with proc in (every process whose background only is false)
    try
      set procName to name of proc
      if procName contains "Emulator" or procName contains "qemu" then
        repeat with win in windows of proc
          set winName to name of win
          if winName contains "Android Emulator" then
            set frontmost of proc to true
            delay 0.2
            set {curW, curH} to size of win
            set position of win to {targetX, targetY}
            delay 0.2
            set size of win to {curW, targetHeight}
            delay 0.3
            set {finalW, finalH} to size of win
            set end of reportLines to procName & "|" & winName & "|" & finalW & "|" & finalH
          end if
        end repeat
      end if
    end try
  end repeat
end tell

set text item delimiters to "\n"
set reportText to reportLines as text
set text item delimiters to ""
return reportText
EOF
)

echo "📐 Trying to maximize height up to ${TARGET_HEIGHT}px (or OS limit)..."
echo ""

results=$(osascript -e "$APPLE_SCRIPT" 2>/dev/null || true)

if [ -z "$results" ]; then
  echo "⚠️  No Android emulator windows found."
  exit 1
fi

echo "📊 Final sizes:"
while IFS='|' read -r proc win width height; do
  [ -z "$proc" ] && continue
  echo "  • $win (${proc}): ${width}x${height}"
done <<< "$results"

echo ""
echo "✅ Done. To run again with a different target height:"
echo "   TARGET_X=120 TARGET_Y=80 ./scripts/android_emulator_bigger.sh 3500"

