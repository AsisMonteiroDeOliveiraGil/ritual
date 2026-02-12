#!/bin/bash

# Script: Sube todos los cambios a la rama actual
# Uso: scripts/push.sh [mensaje del commit]

# Limpiar la terminal antes de empezar
clear

set -euo pipefail

# Función helper para mostrar mensajes con lolcat
print_message() {
  if command -v lolcat >/dev/null 2>&1; then
    echo "$1" | lolcat
  else
    echo "$1"
  fi
}

# Función para mostrar arte ASCII cuando no hay nada que subir
show_nothing_to_push_art() {
  local ascii_art
  ascii_art=$(figlet -f big "Listo")
  local max_width
  max_width=$(echo "$ascii_art" | awk '{print length}' | sort -n | tail -1)
  local separator
  separator=$(printf '=%.0s' $(seq 1 "$max_width"))
  echo "$separator" | lolcat
  echo "$ascii_art" | lolcat
  echo "$separator" | lolcat
}

# Función para mostrar estadísticas de cambios con arte ASCII
show_changes_stats() {
  local added_files
  added_files=$(git diff --cached --name-status | grep -E '^(A|M)' | wc -l | tr -d ' ')
  local diff_stats
  diff_stats=$(git diff --cached --numstat 2>/dev/null || echo "")
  local lines_added=0

  if [[ -n "$diff_stats" ]]; then
    while IFS=$'\t' read -r added deleted file; do
      if [[ -n "$added" ]] && [[ "$added" != "-" ]]; then
        lines_added=$((lines_added + added))
      fi
    done <<< "$diff_stats"
  fi

  local stats_message="${added_files} archivos · ${lines_added} líneas"
  figlet -f big "$stats_message" | lolcat
}

# Función para mostrar estadísticas del último commit con arte ASCII
show_final_stats() {
  local last_commit_hash
  last_commit_hash=$(git rev-parse HEAD)

  local files_added
  files_added=$(git diff-tree --no-commit-id --name-status -r "$last_commit_hash" | grep -E '^(A|M)' | wc -l | tr -d ' ')
  local files_deleted
  files_deleted=$(git diff-tree --no-commit-id --name-status -r "$last_commit_hash" | grep -E '^D' | wc -l | tr -d ' ')
  local diff_stats
  diff_stats=$(git diff-tree --numstat --no-commit-id "$last_commit_hash" 2>/dev/null || echo "")
  local lines_added=0

  if [[ -n "$diff_stats" ]]; then
    while IFS=$'\t' read -r added deleted file; do
      if [[ -n "$added" ]] && [[ "$added" != "-" ]]; then
        lines_added=$((lines_added + added))
      fi
    done <<< "$diff_stats"
  fi

  local stats_message=""
  if [[ $files_added -gt 0 ]]; then
    stats_message="${files_added}+"
  fi
  if [[ $files_deleted -gt 0 ]]; then
    if [[ -n "$stats_message" ]]; then
      stats_message="${stats_message} | ${files_deleted}-"
    else
      stats_message="${files_deleted}-"
    fi
  fi
  if [[ $lines_added -gt 0 ]]; then
    if [[ -n "$stats_message" ]]; then
      stats_message="${stats_message} | ${lines_added} líneas"
    else
      stats_message="${lines_added} líneas"
    fi
  fi

  if [[ -n "$stats_message" ]]; then
    local ascii_art
    ascii_art=$(figlet -f big "$stats_message")
    local max_width
    max_width=$(echo "$ascii_art" | awk '{print length}' | sort -n | tail -1)
    local separator
    separator=$(printf '=%.0s' $(seq 1 "$max_width"))
    echo "$separator" | lolcat
    echo "$ascii_art" | lolcat
    echo "$separator" | lolcat
  fi
}

# Función para detectar el tipo de cambio basándose en el diff
detect_change_type() {
  local diff_content
  diff_content=$(git diff --cached 2>/dev/null || git diff 2>/dev/null || echo "")

  if echo "$diff_content" | grep -qiE "(fix|bug|error|correg|solucion|arregl|resolv)"; then
    echo "fix"
    return
  fi
  if echo "$diff_content" | grep -qiE "(add|new|nuev|crear|implement|agreg|feat)"; then
    echo "feat"
    return
  fi
  if echo "$diff_content" | grep -qiE "(refactor|mejor|optimiz|clean|limpi|reorganiz)"; then
    echo "refactor"
    return
  fi

  echo ""
}

# Función para generar mensaje de commit basado en los cambios
generate_commit_message() {
  local changed_files
  changed_files=$(git status --porcelain | awk '{print $2}' | grep -v '^$')
  local features=()
  local widgets=()
  local services=()
  local web_files=()
  local config_files=()
  local scripts=()
  local core_files=()
  local other_files=()
  local detected_type
  detected_type=$(detect_change_type)

  while IFS= read -r file; do
    if [[ -z "$file" ]]; then continue; fi
    if [[ "$file" == *"features/"* ]]; then
      local feature_name
      feature_name=$(echo "$file" | sed -n 's|.*features/\([^/]*\)/.*|\1|p' | head -n1)
      if [[ -n "$feature_name" ]]; then
        local found=0
        for existing_feature in "${features[@]+"${features[@]}"}"; do
          if [[ "$existing_feature" == "$feature_name" ]]; then
            found=1
            break
          fi
        done
        if [[ $found -eq 0 ]]; then
          features+=("$feature_name")
        fi
      fi
    elif [[ "$file" == *"core/widgets"* ]]; then
      widgets+=("$(basename "$file" .dart)")
    elif [[ "$file" == *"services/"* ]]; then
      services+=("$(basename "$file" .dart)")
    elif [[ "$file" == *"web/"* ]] || [[ "$file" == *"index.html"* ]] || [[ "$file" == *"firebase"* ]] || [[ "$file" == *".firebase/"* ]]; then
      web_files+=("$(basename "$file")")
    elif [[ "$file" == *"pubspec.yaml"* ]] || [[ "$file" == *"package.json"* ]] || [[ "$file" == *"package-lock.json"* ]] || [[ "$file" == *"firebase.json"* ]] || [[ "$file" == *"cors.json"* ]] || [[ "$file" == *".yaml"* ]] || [[ "$file" == *".json"* ]]; then
      config_files+=("$(basename "$file")")
    elif [[ "$file" == *"scripts/"* ]] || [[ "$file" == *".sh"* ]]; then
      scripts+=("$(basename "$file")")
    elif [[ "$file" == *"core/"* ]]; then
      core_files+=("$(basename "$file" .dart)")
    else
      other_files+=("$(basename "$file")")
    fi
  done <<< "$changed_files"

  local commit_type="${detected_type:-chore}"
  local commit_scope=""
  local commit_description=""

  if [[ ${#features[@]} -gt 0 ]]; then
    commit_type="feat"
    if [[ ${#features[@]} -eq 1 ]]; then
      commit_description="${features[0]}"
    else
      commit_description="${features[0]} y otros (${#features[@]} features)"
    fi
  elif [[ ${#widgets[@]} -gt 0 ]]; then
    commit_type="ui"
    commit_scope="widgets"
    if [[ ${#widgets[@]} -eq 1 ]]; then
      commit_description="${widgets[0]}"
    else
      commit_description="${widgets[0]} y otros (${#widgets[@]} widgets)"
    fi
  elif [[ ${#services[@]} -gt 0 ]]; then
    commit_type="refactor"
    commit_scope="services"
    if [[ ${#services[@]} -eq 1 ]]; then
      commit_description="${services[0]}"
    else
      commit_description="${services[0]} y otros (${#services[@]} servicios)"
    fi
  elif [[ ${#web_files[@]} -gt 0 ]]; then
    commit_type="${detected_type:-chore}"
    commit_scope="web"
    if [[ ${#web_files[@]} -eq 1 ]]; then
      commit_description="${web_files[0]}"
    else
      commit_description="configuración web (${#web_files[@]} archivos)"
    fi
  elif [[ ${#config_files[@]} -gt 0 ]]; then
    commit_type="${detected_type:-chore}"
    commit_scope="config"
    if [[ ${#config_files[@]} -eq 1 ]]; then
      commit_description="${config_files[0]}"
    else
      commit_description="configuración (${#config_files[@]} archivos)"
    fi
  elif [[ ${#scripts[@]} -gt 0 ]]; then
    commit_type="${detected_type:-chore}"
    commit_scope="scripts"
    if [[ ${#scripts[@]} -eq 1 ]]; then
      commit_description="${scripts[0]}"
    else
      commit_description="scripts (${#scripts[@]} archivos)"
    fi
  elif [[ ${#core_files[@]} -gt 0 ]]; then
    commit_type="refactor"
    commit_scope="core"
    if [[ ${#core_files[@]} -eq 1 ]]; then
      commit_description="${core_files[0]}"
    else
      commit_description="core (${#core_files[@]} archivos)"
    fi
  else
    commit_type="${detected_type:-chore}"
    local total_files
    total_files=$(echo "$changed_files" | wc -l | tr -d ' ')
    if [[ $total_files -eq 1 ]]; then
      local single_file
      single_file=$(echo "$changed_files" | head -n1)
      local basename
      basename=$(basename "$single_file" .dart)
      commit_description=$(echo "$basename" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    else
      commit_description="actualizar cambios ($total_files archivos)"
    fi
  fi

  if [[ -n "$commit_scope" ]]; then
    echo "${commit_type}(${commit_scope}): ${commit_description}"
  else
    echo "${commit_type}: ${commit_description}"
  fi
}

print_message "🎯 Sincronizando puntos de gamificación..."
if node <<'NODE'
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const MENU_UPLOAD_POINTS = 150;
const MENU_VERIFICATION_POINTS = 250;
const REVIEWER_POINTS = Math.floor(MENU_VERIFICATION_POINTS / 2);

const ACTION_POINTS = {
  menu_upload: MENU_UPLOAD_POINTS,
  menu_upload_restaurant: MENU_UPLOAD_POINTS,
  menu_verified: MENU_VERIFICATION_POINTS,
  menu_review: REVIEWER_POINTS,
};

function initializeFirebase() {
  if (admin.apps.length) return;

  const serviceAccountPath = path.resolve(
    process.cwd(),
    'firebase-service-account.json',
  );

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
    return;
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

function incrementAction(store, userId, action) {
  if (!userId) return;
  if (!store.has(userId)) {
    store.set(userId, { actions: {} });
  }
  const entry = store.get(userId);
  entry.actions[action] = (entry.actions[action] ?? 0) + 1;
}

function calculatePoints(actions) {
  return Object.entries(actions).reduce((total, [action, count]) => {
    const points = ACTION_POINTS[action] ?? 0;
    return total + points * count;
  }, 0);
}

function calculateLevel(points) {
  const threshold = 500;
  return Math.max(1, Math.floor(points / threshold) + 1);
}

async function sync() {
  initializeFirebase();
  const db = admin.firestore();

  console.log('🎯 Sincronizando estadísticas de gamificación...');

  const statsByUser = new Map();
  const menusSnapshot = await db.collectionGroup('menus').get();

  menusSnapshot.forEach((doc) => {
    const data = doc.data() ?? {};
    const restaurantId = data.restaurantId;
    const uploaderId = data.uploaderId;
    const status = (data.status || 'pending').toString().toLowerCase();
    const metadata = data.metadata ?? {};
    const reviewerId = metadata.statusReviewerId;

    if (uploaderId) {
      incrementAction(statsByUser, uploaderId, 'menu_upload');
    }
    if (restaurantId) {
      incrementAction(statsByUser, restaurantId, 'menu_upload_restaurant');
    }

    if (status === 'verified') {
      if (restaurantId) {
        incrementAction(statsByUser, restaurantId, 'menu_verified');
      }
      if (reviewerId) {
        incrementAction(statsByUser, reviewerId, 'menu_review');
      }
    }
  });

  if (statsByUser.size === 0) {
    console.log('ℹ️ No se encontraron menús para sincronizar.');
    return;
  }

  const now = admin.firestore.Timestamp.now();
  let batch = db.batch();
  let writes = 0;

  for (const [userId, entry] of statsByUser.entries()) {
    const actions = entry.actions;
    const points = calculatePoints(actions);
    const level = calculateLevel(points);

    const docRef = db
      .collection('users')
      .doc(userId)
      .collection('gamification')
      .doc('profile');

    batch.set(
      docRef,
      {
        points,
        level,
        actions,
        lastUpdate: now,
      },
      { merge: true },
    );

    writes += 1;
    if (writes >= 400) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }

  if (writes > 0) {
    await batch.commit();
  }

  console.log(`✅ Gamificación sincronizada para ${statsByUser.size} usuarios.`);
}

sync()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Error al sincronizar gamificación:', error);
    process.exit(1);
  });
NODE
then
  print_message "✅ Puntos de gamificación sincronizados"
else
  print_message "⚠️ No se pudieron sincronizar los puntos de gamificación. Continuamos..."
fi

print_message "🚀 Preparando commit y push..."

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  print_message "❌ Este directorio no es un repositorio git."
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
print_message "🔎 Rama actual: ${CURRENT_BRANCH}"

if [ -z "$(git status --porcelain)" ]; then
  show_nothing_to_push_art
  exit 0
fi

git add .

if [[ $# -gt 0 ]]; then
  COMMIT_MESSAGE="$*"
else
  COMMIT_MESSAGE=$(generate_commit_message)
fi

print_message "💾 Creando commit..."
git commit -m "${COMMIT_MESSAGE}"

show_changes_stats

print_message "⬆️ Haciendo push a origin/${CURRENT_BRANCH}..."
git push origin "${CURRENT_BRANCH}"

print_message "✅ Proceso completado."
show_final_stats

