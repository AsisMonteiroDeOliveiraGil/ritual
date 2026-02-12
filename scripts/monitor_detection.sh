#!/bin/bash

# Utility to detect how many external monitors are connected to a Mac.
# Can be sourced from other scripts or executed directly to print the count.

MONITOR_DETECTION_DEBUG="${MONITOR_DETECTION_DEBUG:-0}"

log_monitor_debug() {
  if [[ "$MONITOR_DETECTION_DEBUG" == "1" ]]; then
    echo "[monitor_detection] $1" >&2
  fi
}

detect_with_core_graphics() {
  local swift_bin="/usr/bin/swift"
  if [ ! -x "$swift_bin" ]; then
    swift_bin="$(command -v swift 2>/dev/null)"
  fi

  if [ -z "$swift_bin" ]; then
    log_monitor_debug "Swift no disponible; se omite CoreGraphics"
    return 1
  fi

  log_monitor_debug "Intentando detección con CoreGraphics (swift)"
  local result
  result=$("$swift_bin" - <<'SWIFT'
import CoreGraphics
import Foundation

let maxDisplays: UInt32 = 16
var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
var displayCount: UInt32 = 0

let error = CGGetOnlineDisplayList(maxDisplays, &displayIDs, &displayCount)
if error != .success {
    fputs("[monitor_detection] CoreGraphics falló con error \(error.rawValue)\n", stderr)
    exit(1)
}

var externalCount = 0
for index in 0..<Int(displayCount) {
    let displayID = displayIDs[index]
    if CGDisplayIsBuiltin(displayID) == 0 {
        externalCount += 1
    }
}

print(externalCount)
SWIFT
  )

  local status=$?
  local trimmed
  trimmed=$(echo "$result" | tr -d '\r' | awk 'NF { print $NF }')

  if [ $status -eq 0 ] && [[ "$trimmed" =~ ^[0-9]+$ ]]; then
    log_monitor_debug "CoreGraphics detectó ${trimmed} monitor(es) externo(s)"
    echo "$trimmed"
    return 0
  fi

  if [ $status -eq 0 ]; then
    log_monitor_debug "CoreGraphics devolvió salida inesperada: ${result}"
  else
    log_monitor_debug "CoreGraphics no disponible o falló (status=$status)"
  fi

  return 1
}

detect_with_appkit() {
  log_monitor_debug "Intentando detección con AppKit"
  local screen_count
  screen_count=$(/usr/bin/python3 - <<'PY'
import os
try:
    from AppKit import NSScreen
except ImportError:
    print("")
else:
    screens = NSScreen.screens()
    total = len(screens)
    debug = os.environ.get("MONITOR_DETECTION_DEBUG") == "1"
    if debug:
        import sys
        print(f"[monitor_detection] AppKit encontró {total} pantalla(s)", file=sys.stderr)
    if total <= 1:
        print(0)
    else:
        print(total - 1)
PY
  )

  if [ -n "$screen_count" ]; then
    echo "$screen_count"
    return 0
  fi

  return 1
}

detect_with_system_profiler_json() {
  log_monitor_debug "Intentando detección con system_profiler (JSON)"
  local profiler_json
  profiler_json=$(system_profiler SPDisplaysDataType -json 2>/dev/null)
  if [ -z "$profiler_json" ]; then
    return 1
  fi

  local python_count
  python_count=$(echo "$profiler_json" | /usr/bin/python3 - <<'PY'
import json
import sys
import os

try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(1)

count = 0
debug = os.environ.get("MONITOR_DETECTION_DEBUG") == "1"

for display in data.get("SPDisplaysDataType", []):
    for driver in display.get("spdisplays_ndrvs", []):
        is_internal = False

        connection = (driver.get("spdisplays_connection_type") or "").lower()
        if "internal" in connection:
            is_internal = True
        elif "external" in connection:
            is_internal = False

        if not is_internal:
            flag = driver.get("spdisplays_is_builtin")
            if isinstance(flag, bool):
                is_internal = flag
            elif isinstance(flag, str):
                val = flag.strip().lower()
                is_internal = val in {"1", "true", "yes", "y", "on", "spdisplays_yes"}

        if not is_internal:
            display_type = (driver.get("spdisplays_display_type") or "").lower()
            if "built" in display_type or "internal" in display_type or "retina" in display_type:
                is_internal = True

        if not is_internal:
            count += 1

if debug:
    print(f"[monitor_detection] system_profiler/json externos={count}", file=sys.stderr)

print(count)
PY
  )

  if [[ "$python_count" =~ ^[0-9]+$ ]]; then
    echo "$python_count"
    return 0
  fi

  return 1
}

detect_with_system_profiler_text() {
  log_monitor_debug "Intentando detección con system_profiler (texto)"
  local profiler_text
  profiler_text=$(system_profiler SPDisplaysDataType 2>/dev/null)
  if [ -z "$profiler_text" ]; then
    return 1
  fi

  local external_count
  external_count=$(echo "$profiler_text" | awk '
    BEGIN { built_in = 0; total = 0 }
    /Resolution:/ { total++ }
    /Display Type: Built-in/ { built_in++ }
    /Display Type: Internal/ { built_in++ }
    END {
      if (total == 0) {
        print 0
      } else {
        if (built_in == 0 && total > 0) {
          built_in = 1
        }
        count = total - built_in
        if (count < 0) { count = 0 }
        print count
      }
    }
  ')

  if [[ "$external_count" =~ ^[0-9]+$ ]]; then
    log_monitor_debug "system_profiler texto externos=${external_count}"
    echo "$external_count"
    return 0
  fi

  return 1
}

detect_external_monitors() {
  local count
  local best=0

  if count=$(detect_with_core_graphics); then
    best=$count
    if [ "$best" -gt 0 ]; then
      echo "$best"
      return
    fi
  fi

  if count=$(detect_with_appkit); then
    if [ "$count" -gt "$best" ]; then
      best=$count
    fi
    if [ "$best" -gt 0 ]; then
      echo "$best"
      return
    fi
  fi

  if count=$(detect_with_system_profiler_json); then
    if [ "$count" -gt "$best" ]; then
      best=$count
    fi
    if [ "$best" -gt 0 ]; then
      echo "$best"
      return
    fi
  fi

  if count=$(detect_with_system_profiler_text); then
    if [ "$count" -gt "$best" ]; then
      best=$count
    fi
    if [ "$best" -gt 0 ]; then
      echo "$best"
      return
    fi
  fi

  if [ "$best" -gt 0 ]; then
    echo "$best"
    return
  fi

  log_monitor_debug "No se pudo determinar la cantidad de monitores externos; devolviendo 0"
  echo 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_external_monitors
fi

