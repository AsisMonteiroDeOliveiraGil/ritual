#!/usr/bin/env python3

import json
import subprocess
import sys

def find_debug_ports():
    """Encuentra los puertos de debugging remoto y PIDs de las ventanas de Flutter"""
    try:
        # Ejecutar ps para encontrar los puertos de debugging y PIDs
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        
        debug_ports = {}
        for line in lines:
            if 'remote-debugging-port' in line:
                # Extraer PID (segunda columna)
                parts = line.split()
                if len(parts) > 1:
                    pid = parts[1]
                    
                    if '8080' in line:
                        # Extraer el puerto de debugging
                        port_parts = line.split('remote-debugging-port=')
                        if len(port_parts) > 1:
                            port = port_parts[1].split()[0]
                            debug_ports['8080'] = {'port': port, 'pid': pid}
                    elif '8081' in line:
                        # Extraer el puerto de debugging
                        port_parts = line.split('remote-debugging-port=')
                        if len(port_parts) > 1:
                            port = port_parts[1].split()[0]
                            debug_ports['8081'] = {'port': port, 'pid': pid}
        
        return debug_ports
    except Exception as e:
        print(f"Error encontrando puertos de debugging: {e}")
        return {}

def get_window_info(debug_port):
    """Obtiene información de la ventana usando Chrome DevTools Protocol"""
    try:
        result = subprocess.run(['curl', '-s', f'http://localhost:{debug_port}/json'], capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            data = json.loads(result.stdout)
            if data and len(data) > 0:
                return data[0]
        return None
    except Exception as e:
        print(f"Error obteniendo información de ventana en puerto {debug_port}: {e}")
        return None

def find_main_pid_by_url(url_suffix: str):
    """Encuentra el PID del proceso principal de Chrome que abrió una URL concreta (ej: localhost:8080)."""
    try:
        # Buscar el proceso principal: binario "Google Chrome" con la URL como último argumento
        # Ejemplo de línea:
        # /Applications/Google Chrome.app/.../Google Chrome --user-data-dir=... --remote-debugging-port=63932 ... http://localhost:8080
        result = subprocess.run(
            ['ps', 'aux'], capture_output=True, text=True
        )
        lines = result.stdout.split('\n')
        for line in lines:
            if 'Google Chrome --user-data-dir=' in line and url_suffix in line:
                parts = line.split()
                if len(parts) > 1:
                    return parts[1]  # PID
        return None
    except Exception as e:
        print(f"Error encontrando PID por URL {url_suffix}: {e}")
        return None

def set_window_position_size_by_pid(pid: str, x: int, y: int, width: int, height: int):
    """Reposiciona mediante AppleScript usando position/size (más fiable que bounds)."""
    try:
        script = f'''
tell application "System Events"
  tell (first process whose unix id is {pid})
    tell window 1
      set position to {{{x}, {y}}}
      set size to {{{width}, {height}}}
    end tell
  end tell
end tell
'''
        res = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
        if res.returncode == 0:
            return 'success'
        return f"error: {res.stderr.strip()}"
    except Exception as e:
        return f"exception: {str(e)}"

def reposition_cursor_window():
    """Reposiciona la ventana de Cursor a su posición actual."""
    try:
        script = '''
tell application "System Events"
  tell process "Cursor"
    tell window 1
      set position to {851, 38}
      set size to {661, 855}
    end tell
  end tell
end tell
'''
        res = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
        if res.returncode == 0:
            return 'success'
        return f"error: {res.stderr.strip()}"
    except Exception as e:
        return f"exception: {str(e)}"

def reposition_window_by_cdp(web_port, bounds):
    """Reposiciona una ventana usando Chrome DevTools Protocol"""
    try:
        x, y, width, height = bounds
        
        # Usar CDP para reposicionar la ventana - buscar por el puerto web correcto
        script = f'''
tell application "Google Chrome"
  repeat with w in windows
    repeat with t in tabs of w
      if URL of t contains "localhost:{web_port}" then
        set bounds of w to {{{x}, {y}, {width}, {height}}}
        return "success"
      end if
    end repeat
  end repeat
  return "window_not_found"
end tell
'''
        
        result = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
        
        if result.returncode == 0:
            output = result.stdout.strip()
            if "success" in output:
                return "success"
            else:
                return f"not_found: {output}"
        else:
            print(f"AppleScript error: {result.stderr}")
            return f"error: {result.stderr.strip()}"
            
    except Exception as e:
        print(f"Error reposicionando ventana: {e}")
        return f"exception: {str(e)}"

def reposition_window_fallback_by_title(bounds):
    """Método de respaldo usando título de ventana"""
    try:
        x, y, width, height = bounds
        
        # Buscar ventanas de Chrome que contengan "The Final Burger" o "localhost"
        script = f'''
tell application "System Events"
  try
    tell process "Google Chrome"
      repeat with w in windows
        if name of w contains "The Final Burger" or name of w contains "localhost" then
          set bounds of w to {{{x}, {y}, {width}, {height}}}
          return "success"
        end if
      end repeat
      return "no_window_found"
    end tell
  on error errMsg
    return "error: " & errMsg
  end try
end tell
'''
        
        result = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
        
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            return f"fallback_error: {result.stderr.strip()}"
            
    except Exception as e:
        return f"fallback_exception: {str(e)}"

def reposition_all_windows_directly():
    """Método directo para reposicionar todas las ventanas de Chrome y cambiar títulos"""
    try:
        script = '''
tell application "Google Chrome"
  set windowCount to 0
  repeat with w in windows
    set windowName to name of w
    if windowName contains "localhost" or windowName contains "The Final Burger" then
      set windowCount to windowCount + 1
      if windowCount is 1 then
        -- Primera ventana (puerto 8080) - lado izquierdo
        set bounds of w to {-69, 38, 431, 893}
        -- Cambiar título a iPhone
        tell tab 1 of w
          execute javascript "document.title = 'iPhone - The Final Burger'"
        end tell
        log "Ventana 1 (Puerto 8080) reposicionada a {-69, 38, 431, 893} y título cambiado"
      else if windowCount is 2 then
        -- Segunda ventana (puerto 8081) - lado derecho
        set bounds of w to {350, 38, 850, 893}
        -- Cambiar título a Android
        tell tab 1 of w
          execute javascript "document.title = 'Android - The Final Burger'"
        end tell
        log "Ventana 2 (Puerto 8081) reposicionada a {350, 38, 850, 893} y título cambiado"
      end if
    end if
  end repeat
  return windowCount
end tell
'''
        
        result = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
        
        if result.returncode == 0:
            output = result.stdout.strip()
            print(f"✅ Método directo completado: {output}")
            return True
        else:
            print(f"❌ Error en método directo: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Excepción en método directo: {e}")
        return False

def main():
    print("🔄 Reposicionando ventanas de Flutter...")
    
    # Intentar método directo primero
    print("🚀 Intentando método directo...")
    if reposition_all_windows_directly():
        print("✅ Reposicionamiento directo exitoso")
    else:
        print("⚠️ Método directo falló, intentando método detallado...")
        
        # Encontrar puertos de debugging
        debug_ports = find_debug_ports()
        print(f"🔍 Puertos encontrados: {debug_ports}")
        
        if not debug_ports:
            print("❌ No se encontraron puertos de debugging")
            return
        
        # Reposicionar ventana 8080 (iPhone)
        if '8080' in debug_ports:
            info = debug_ports['8080']
            debug_port = info['port']
            pid = info['pid']
            print(f"📱 Reposicionando ventana 8080 (PID: {pid}, puerto debug: {debug_port})...")
            
            window_info = get_window_info(debug_port)
            if window_info:
                print(f"   Título: {window_info.get('title', 'N/A')}")
                print(f"   URL: {window_info.get('url', 'N/A')}")
            
            # Reposicionar a posición exacta: {-69, 38, 431, 893}
            target_bounds_8080 = [-69, 38, 431, 893]
            result = reposition_window_by_cdp(8080, target_bounds_8080)
            print(f"   Resultado: {result}")
            
            # Si no se encontró por URL, intentar por título
            fallback_result = None
            if "not_found" in result:
                print("   🔄 Intentando método de respaldo por título...")
                fallback_result = reposition_window_fallback_by_title(target_bounds_8080)
                print(f"   Resultado fallback: {fallback_result}")

            # Último recurso: localizar PID principal por URL y usar position/size
            if ("not_found" in str(result)) and (fallback_result is None or "success" not in str(fallback_result)):
                print("   🧩 Último intento con PID principal por URL...")
                pid_main = find_main_pid_by_url('localhost:8080')
                if pid_main:
                    x, y, right, bottom = target_bounds_8080
                    width = right - x
                    height = bottom - y
                    final_res = set_window_position_size_by_pid(pid_main, x, y, width, height)
                    print(f"   Resultado PID-url: {final_res}")
                else:
                    print("   ❌ No se pudo localizar el PID principal por URL para 8080")
        
        # Reposicionar ventana 8081
        if '8081' in debug_ports:
            info = debug_ports['8081']
            debug_port = info['port']
            pid = info['pid']
            print(f"📱 Reposicionando ventana 8081 (PID: {pid}, puerto debug: {debug_port})...")
            
            window_info = get_window_info(debug_port)
            if window_info:
                print(f"   Título: {window_info.get('title', 'N/A')}")
                print(f"   URL: {window_info.get('url', 'N/A')}")
            
            # Reposicionar a posición exacta: {350, 38, 850, 893}
            result = reposition_window_by_cdp(8081, [350, 38, 850, 893])
            print(f"   Resultado: {result}")
    
    # Reposicionar ventana de Cursor
    print("💻 Reposicionando ventana de Cursor...")
    cursor_result = reposition_cursor_window()
    print(f"   Resultado Cursor: {cursor_result}")
    
    print("✅ Reposicionamiento completado")
    
    # Verificar posiciones finales
    print("🔍 Verificando posiciones finales...")
    try:
        script = '''
tell application "Google Chrome"
  repeat with w in windows
    set {x, y, width, height} to bounds of w
    log "Ventana: " & (name of w) & " - x: " & x & ", y: " & y & ", w: " & width & ", h: " & height
  end repeat
end tell
'''
        subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
    except Exception as e:
        print(f"Error verificando posiciones: {e}")

if __name__ == "__main__":
    main()
