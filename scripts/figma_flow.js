/**
 * FIGMA FLOW — Supabase -> Figma (hierarchical, infinite depth)
 * Runtime: Figma plugin (or Figma GPT), not Node.js.
 * Usage: paste/run this in the plugin runtime. It will:
 *  1) Clear the current page
 *  2) List all images in the Supabase bucket
 *  3) Parse names like 1, 1.1, 1.2.1 (infinite depth)
 *  4) Lay them out: column = depth-1, rows stacked by subtree height
 *  5) Download and draw each screenshot
 */

(function () {
    // === CONFIG ===
    var SUPABASE_URL = "https://mzczxyksaktchwnvvfpv.supabase.co";
    var BUCKET = "fotos";
    // Path base dentro del bucket (por si en el futuro anidas en una subcarpeta)
    var BASE_PREFIX = ""; // buscar en la raíz del bucket 'fotos' para el proyecto 'flow'
    // (Opcional) Forzar carpeta numérica si el listado está bloqueado por políticas RLS
    // Déjalo en "" para autodetección. Ejemplo: "5"
    var FORCE_LAST_DIR = "";
    // Anon key (public). Needed for listing and for signing URLs if bucket is private.
    var ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16Y3p4eWtzYWt0Y2h3bnZ2ZnB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwMTY0MjgsImV4cCI6MjA3MDU5MjQyOH0.AEt1flvkcAuFIEp0qfg9g-4OJAUawYsjsDcXVDSb6SY";

    // Layout
    var FRAME_W = 240, FRAME_H = 480; // image box size
    var CELL_W = 260, CELL_H = 500; // grid cell size (dx, dy)
    var GAP_X = 80, GAP_Y = 160;  // increased vertical spacing for children
    var CHILD_PAIR_OFFSET = 300; // px vertical offset (up/down) when a parent has exactly 2 children

    // === Embedded labels (replaces external labels.json) ===
    // Each node maps a hierarchical id to a file name and a friendly label.
    // Files are expected to live under: {lastDir}/movil/
    const EMBEDDED_NODES = [
        { id: "0", file: "iphone.png", label: "iphone" },
        { id: "0.0", file: "login.png", label: "login" },
        { id: "0.0.1", file: "register.png", label: "register" },
        { id: "0.0.2", file: "recover password.png", label: "recover password" },
        { id: "0.0.0", file: "sign in google permision.png", label: "sign in google permission" },
        { id: "0.0.0.0", file: "choose google account.png", label: "choose google account" },
        { id: "0.0.0.0.0.0.1.0.3.1", file: "profile change google account permission.png", label: "profile change google account permission" },
        { id: "0.0.0.0.0", file: "sign in google continue.png", label: "sign in google continue" },
        { id: "0.0.0.0.0.0", file: "loading.png", label: "loading" },

        // Maps
        { id: "0.0.0.0.0.0.1", file: "google map location permision.png", label: "google map location permission" },
        { id: "0.0.0.0.0.0.1.0", file: "google map zone 0.png", label: "google map zone 0" },
        // Children of google map zone 0 (top→bottom): zone 2, saved restaurants, competitions, profile
        { id: "0.0.0.0.0.0.1.0.0", file: "google map zone 2.png", label: "google map zone 2" },
        { id: "0.0.0.0.0.0.1.0.0.0", file: "google map zone 3.png", label: "google map zone 3" },
        // --- FUTURE placeholder under Google Map Zone 3
        { id: "0.0.0.0.0.0.1.0.0.0.0", label: "restaurant detail", future: true },
        { id: "0.0.0.0.0.0.1.0.1", file: "saved restaurants.png", label: "saved restaurants" },
        { id: "0.0.0.0.0.0.1.0.2", file: "competitions.png", label: "competitions" },
        { id: "0.0.0.0.0.0.1.0.3", file: "profile.png", label: "profile" },
        { id: "0.0.0.0.0.0.1.0.3.0", file: "profile change google.png", label: "profile change google" },
        { id: "0.0.0.0.0.0.1.0.3.2", file: "profile change google account.png", label: "profile change google account" },
        { id: "0.0.0.0.0.0.1.0.2.0", file: "events.png", label: "events" },
        { id: "0.0.0.0.0.0.1.0.2.0.0", file: "event detail.png", label: "event detail" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1", file: "game mode selection 1.png", label: "game mode selection 1" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1.1", file: "tinder.png", label: "tinder" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1.1.0", file: "tinder bacon queen.png", label: "tinder bacon queen" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1.1.1", file: "tinder 7 rest.png", label: "tinder 7 rest" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1.1.1.0", file: "tinder 1 rest.png", label: "tinder 1 rest" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1.1.1.0.0", file: "tinder winner.png", label: "tinder winner" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1.1.1.0.0.0", file: "payment.png", label: "payment" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1.1.1.0.0.0.0", file: "qr.png", label: "qr" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p1.1.1.0.0.0.0.0", file: "rate.png", label: "rate" },
        { id: "0.0.0.0.0.0.1.0.2.0.0.0~p2", file: "game mode selection 2.png", label: "game mode selection 2" }
    ];

    // Label rendering style for on-canvas names: 'TAIL2' | 'ELLIPSIS' | 'LETTERS'
    var LABEL_STYLE = 'TAIL2';

    function displayName(name) {
        try {
            var parts = String(name).split('.').filter(Boolean);
            if (!parts.length) return name;
            switch (LABEL_STYLE) {
                case 'TAIL2': {
                    // Show only the last 2 segments, prefixed with ellipsis when trimmed
                    if (parts.length <= 2) return parts.join('.');
                    return '… ' + parts.slice(-2).join('.');
                }
                case 'ELLIPSIS': {
                    // Show first and last segment: "first … last"
                    if (parts.length <= 2) return parts.join(' … ');
                    return parts[0] + ' … ' + parts[parts.length - 1];
                }
                case 'LETTERS': {
                    // Compact: L1, L2, L3 → A,B,C with indices. Example: A0·B2·C3
                    var alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                    var out = parts.map(function (seg, i) {
                        var lvl = alpha[i] || ('L' + (i + 1));
                        return lvl + seg;
                    });
                    return out.join('·');
                }
                default:
                    return name;
            }
        } catch (_) { return name; }
    }

    // Wrap long hierarchical names into two lines when there are more than 6 segments
    function twoLineName(name) {
        try {
            var parts = String(name).split('.').filter(Boolean);
            if (parts.length > 6) {
                return parts.slice(0, 6).join('.') + '\n' + parts.slice(6).join('.');
            }
            return name;
        } catch (_) { return name; }
    }

    // Allow full names to wrap across multiple lines by permitting breaks after each dot
    function wrapNameFull(name) {
        return String(name).replace(/\./g, ".\u200B");
    }

    // Allow wrapping on spaces and common separators as soft breaks
    function wrapAnyLabel(s) {
        try {
            return String(s)
                .replace(/ /g, " \u200B")
                .replace(/([_/.\-])/g, "$1\u200B");
        } catch (_) { return String(s); }
    }

    // Capitalize the first letter of a string
    function capFirst(s) {
        try { s = String(s); } catch (_) { return s; }
        if (!s.length) return s;
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    // Use embedded labels instead of external labels.json
    async function loadLabelsJSON(dirPrefix) {
        try {
            if (Array.isArray(EMBEDDED_NODES) && EMBEDDED_NODES.length) {
                return EMBEDDED_NODES;
            }
        } catch (_) { }
        return null;
    }

    // === SINGLE-NOTIFY LOGGING (una sola notificación) ===
    var __LOG__ = [];
    // Helper: compact notification
    function notif(msg) { try { figma.notify(String(msg)); } catch (_) { } }

    // === Utilities ===
    function nameToParts(n) { return n.split('.').map(function (x) { return parseInt(x, 10); }); }
    function parentName(n) { var p = n.split('.'); p.pop(); return p.length ? p.join('.') : null; }
    function cmpNames(a, b) {
        a = (typeof a === "string") ? a : "";
        b = (typeof b === "string") ? b : "";
        var pa = nameToParts(a);
        var pb = nameToParts(b);
        var L = Math.max(pa.length, pb.length);
        for (var i = 0; i < L; i++) {
            var va = (i < pa.length && typeof pa[i] === "number" && !isNaN(pa[i])) ? pa[i] : -1;
            var vb = (i < pb.length && typeof pb[i] === "number" && !isNaN(pb[i])) ? pb[i] : -1;
            if (va !== vb) return va - vb;
        }
        return 0;
    }

    // === Cluster helpers (split tall screens into parts: id~p1, id~p2, ...)
    function clusterBaseId(id) {
        try { return String(id).replace(/~p\d+$/i, ""); } catch (_) { return String(id); }
    }
    function isClusterPart(id) {
        try { return /~p\d+$/i.test(String(id)); } catch (_) { return false; }
    }
    function clusterPartIndex(id) { var m = String(id).match(/~p(\d+)$/i); return m ? parseInt(m[1], 10) : 0; }
    function cmpNamesCluster(a, b) {
        var ba = clusterBaseId(a), bb = clusterBaseId(b);
        var baseCmp = cmpNames(ba, bb);
        if (baseCmp !== 0) return baseCmp;
        var ia = clusterPartIndex(a), ib = clusterPartIndex(b);
        return ia - ib;
    }

    // === 0) Clear canvas ===
    figma.currentPage.children.forEach(function (n) { try { n.remove(); } catch (_) { } });

    // === 1) List objects in bucket (get latest numeric folder and its images) ===
    // Helper: listPrefix
    function listPrefix(prefix) {
        var listURL = SUPABASE_URL + "/storage/v1/object/list/" + BUCKET;
        return fetch(listURL, {
            method: "POST",
            headers: {
                "Authorization": "Bearer " + ANON_KEY,
                "apikey": ANON_KEY,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                prefix: prefix,
                limit: 1000,
                offset: 0,
                sortBy: { column: "name", order: "asc" },
                delimiter: "/" // importante: devolver subcarpetas
            })
        }).then(function (r) {
            if (!r.ok) {
                if (r.status === 400) {
                    throw new Error("Listado falló: HTTP 400 (verifica que ANON_KEY pertenezca al proyecto actual y que el bucket exista)");
                }
                throw new Error("Listado falló: HTTP " + r.status);
            }
            return r.json();
        });
    }

    // Helper: try listing with and without trailing slash
    async function listPrefixFlexible(prefix) {
        try {
            const a = await listPrefix(prefix);
            if (Array.isArray(a) && a.length > 0) return a;
        } catch (e) {
            // continue to try alt form
        }
        if (typeof prefix === 'string' && /\/$/.test(prefix)) {
            try {
                const alt = prefix.replace(/\/$/, "");
                const b = await listPrefix(alt);
                if (Array.isArray(b)) return b;
            } catch (e2) { }
        } else if (typeof prefix === 'string' && prefix.length > 0) {
            try {
                const b = await listPrefix(prefix + "/");
                if (Array.isArray(b)) return b;
            } catch (e3) { }
        }
        return [];
    }

    // Paso 1: intentar listar carpetas numéricas en BASE_PREFIX; si falla o viene vacío,
    // hacer un sondeo incremental 1..MAX_VERSION y quedarnos con la última que tenga imágenes
    var MAX_VERSION = 50; // ajustable (menos spam y más rápido)
    listPrefixFlexible(BASE_PREFIX).then(async function (arr) {
        // Intento A: detectar carpetas numéricas a partir del listado de raíz
        var numericDirs = [];
        try {
            numericDirs = arr
                .map(function (f) { var name = f && f.name ? String(f.name) : ""; return name.replace(/\/$/, ""); })
                .filter(function (name) { return /^\d+$/.test(name); });
        } catch (err) {
            // skip error
        }

        var lastDir = null;
        // Si se fuerza manualmente, saltamos autodetección
        if (FORCE_LAST_DIR) {
            lastDir = String(FORCE_LAST_DIR);
        } else
            if (numericDirs.length) {
                numericDirs.sort(function (a, b) { return parseInt(a, 10) - parseInt(b, 10); });
                lastDir = numericDirs[numericDirs.length - 1];
            } else {
                // Intento B: sondeo descendente MAX..1 para localizar la última con archivos
                var found = [];
                for (var v = MAX_VERSION; v >= 1; v--) {
                    try {
                        var probe = await listPrefixFlexible(BASE_PREFIX + v + "/movil/");
                        var hasImgs = Array.isArray(probe) && probe.some(function (f) { return f && f.name && /\.(png|jpg|jpeg|webp)$/i.test(f.name); });
                        if (hasImgs) { found.push(v); break; }
                    } catch (e) { /* ignorar */ }
                }
                if (found.length) {
                    lastDir = String(found[0]);
                }
            }

        figma.notify("Dir seleccionado: " + (lastDir ? (lastDir + "/movil/") : "<ninguno>"));

        if (!lastDir) {
            return Promise.reject("No numeric dirs");
        }

        // Paso 2: listar imágenes dentro de esa carpeta
        return listPrefixFlexible(BASE_PREFIX + lastDir + "/movil/").then(async function (filesArr) {
            var selectedPath = BASE_PREFIX + lastDir + "/movil/";
            // Build a case-insensitive map of available filenames in Supabase for robust resolution
            var availableFilesLC = new Map(); // key: lowercase name, value: actual name
            try {
                if (Array.isArray(filesArr)) {
                    filesArr.forEach(function (f) {
                        if (f && f.name) availableFilesLC.set(String(f.name).toLowerCase(), String(f.name));
                    });
                }
            } catch (_) { }

            function resolveExistingFileName(desired) {
                if (!desired) return null;
                var want = String(desired).trim();
                // If user passed a full filename, try direct case-insensitive match
                var direct = availableFilesLC.get(want.toLowerCase());
                if (direct) return direct;
                // If they passed without extension, try common image extensions
                var base = want.replace(/\.(png|jpg|jpeg|webp)$/i, "");
                var exts = [".png", ".jpg", ".jpeg", ".webp"];
                for (var i = 0; i < exts.length; i++) {
                    var cand = base + exts[i];
                    var hit = availableFilesLC.get(cand.toLowerCase());
                    if (hit) return hit;
                }
                // Last resort: try collapsing multiple spaces
                var collapsed = base.replace(/\s+/g, " ");
                for (var j = 0; j < exts.length; j++) {
                    var cand2 = collapsed + exts[j];
                    var hit2 = availableFilesLC.get(cand2.toLowerCase());
                    if (hit2) return hit2;
                }
                return null;
            }
            var items;
            try {
                // --- MERGE MODE ---
                // 1) Index embedded nodes by (a) lowercase full file name, (b) lowercase base name (no ext), (c) normalized label, and (d) id
                var byFile = new Map();      // key: lowercase full file name => node
                var byFileBase = new Map();  // key: lowercase base (no ext)   => node
                var byLabelBase = new Map(); // key: lowercase label (normalized) => node
                var byId = new Map();        // key: id => node
                var nodesFromJson = null;
                var dirPrefix = BASE_PREFIX + lastDir + "/movil/";
                try { nodesFromJson = await loadLabelsJSON(dirPrefix); } catch (_) { }
                if (Array.isArray(nodesFromJson)) {
                    nodesFromJson.forEach(function (n) {
                        if (!n) return;
                        if (n.file) {
                            var full = String(n.file).toLowerCase();
                            byFile.set(full, n);
                            var base = full.replace(/\.(png|jpg|jpeg|webp)$/i, "");
                            byFileBase.set(base, n);
                        }
                        if (n.label) {
                            var lab = String(n.label).toLowerCase();
                            var labNorm = lab.replace(/_/g, " ").replace(/\s+/g, " ").trim();
                            byLabelBase.set(labNorm, n);
                        }
                        if (n.id) byId.set(String(n.id), n);
                    });
                }

                // 2) Build items from ALL files present in Supabase
                var unmappedSet = new Set();
                items = filesArr
                    .filter(function (f) { return f && f.name && /\.(png|jpg|jpeg|webp)$/i.test(f.name); })
                    .map(function (f) {
                        var actual = String(f.name);
                        var actualLC = actual.toLowerCase();
                        var baseLC = actualLC.replace(/\.(png|jpg|jpeg|webp)$/i, "");
                        var baseNorm = baseLC.replace(/_/g, " ").replace(/\s+/g, " ").trim();
                        var n = byFile.get(actualLC)
                            || byFileBase.get(baseLC)
                            || byFileBase.get(baseNorm)
                            || byLabelBase.get(baseLC)
                            || byLabelBase.get(baseNorm)
                            || null;
                        var idForHierarchy = n && n.id ? String(n.id) : actual.replace(/\.(png|jpg|jpeg|webp)$/i, "");
                        var labelForText = n && (n.label || n.file) ? String(n.label || n.file) : actual.replace(/\.(png|jpg|jpeg|webp)$/i, "");
                        var isUnmapped = !n; // not present in embedded JSON
                        if (isUnmapped) unmappedSet.add(idForHierarchy);
                        return {
                            name: idForHierarchy,
                            file: dirPrefix + actual,
                            labelText: labelForText,
                            isUnmapped: isUnmapped
                        };
                    })
                    .sort(function (a, b) { return cmpNamesCluster(a.name, b.name); });

                // --- Add FUTURE placeholders from embedded JSON when no actual file exists
                try {
                    var addedFutures = 0;
                    if (Array.isArray(nodesFromJson)) {
                        nodesFromJson.forEach(function (n) {
                            if (!n || !n.future) return;
                            var id = String(n.id || "").trim();
                            if (!id) return;
                            var already = items.some(function (it) { return it.name === id; });
                            if (!already) {
                                items.push({
                                    name: id,
                                    file: null,
                                    labelText: n.label || id,
                                    isUnmapped: false,
                                    isFuture: true
                                });
                                addedFutures++;
                            }
                        });
                        if (addedFutures) {
                            items.sort(function (a, b) { return cmpNamesCluster(a.name, b.name); });
                        }
                    }
                } catch (_) { }
            } catch (err) {
                throw err;
            }
            if (!items.length) {
                figma.notify("⚠️ No files: path=" + selectedPath + " | entries=" + (Array.isArray(filesArr) ? filesArr.length : 0) + (Array.isArray(filesArr) && filesArr.length ? (" | first=\"" + (filesArr[0].name || "?") + "\"") : ""));
                return Promise.reject("No files");
            }


            // === Number labels in a stable hierarchical order
            var numberedLabelMap = new Map();
            try {
                for (var i = 0; i < items.length; i++) {
                    var itx = items[i];
                    var baseLabel = (typeof itx.labelText === 'string' && itx.labelText) ? itx.labelText : itx.name;
                    numberedLabelMap.set(itx.name, String(i + 1) + " " + baseLabel);
                }
            } catch (_) { }

            // === 2) Build tree (infinite depth) — now tracking parents
            var nodeMap = new Map();
            function ensure(n) {
                if (!nodeMap.has(n)) nodeMap.set(n, { name: n, children: [], height: 1, file: null, parent: null });
                return nodeMap.get(n);
            }
            items.forEach(function (it) {
                var node = ensure(it.name); node.file = it.file;
                var p = parentName(it.name);
                if (p) { var parentNode = ensure(p); node.parent = parentNode; parentNode.children.push(node); }
            });
            nodeMap.forEach(function (n) { n.children.sort(function (a, b) { return cmpNamesCluster(a.name, b.name); }); });
            var roots = []; nodeMap.forEach(function (n) { if (!n.parent) roots.push(n); });
            roots.sort(function (a, b) { return cmpNames(a.name, b.name); });
            if (!roots.length) { return Promise.reject("No roots"); }

            function computeHeights(n) { if (!n.children.length) { n.height = 1; return 1; } var sum = 0; n.children.forEach(function (c) { sum += computeHeights(c); }); n.height = Math.max(1, sum); return n.height; }
            roots.forEach(computeHeights);

            var pos = new Map();
            function depthOfName(name) { return nameToParts(name).length; }
            function placeCentered(node, startRow) {
                var col = depthOfName(node.name) - 1;
                if (!node.children || node.children.length === 0) { pos.set(node.name, { row: startRow, col: col }); return startRow + 1; }
                var current = startRow; for (var i = 0; i < node.children.length; i++) { current = placeCentered(node.children[i], current); }
                var firstChild = node.children[0]; var lastChild = node.children[node.children.length - 1];
                var firstRow = pos.get(firstChild.name).row; var lastRow = pos.get(lastChild.name).row;
                var parentRow = firstRow + (lastRow - firstRow) / 2; pos.set(node.name, { row: parentRow, col: col }); return current;
            }
            var nextRow = 0; for (var r = 0; r < roots.length; r++) { nextRow = placeCentered(roots[r], nextRow); }
            // --- Anchor node "0" to left column, aligned with its first child if any
            try {
                var zeroName = "0";
                if (nodeMap.has(zeroName)) {
                    var zeroNode = nodeMap.get(zeroName);
                    var targetRow = null;
                    if (zeroNode.children && zeroNode.children.length) {
                        var firstChild = zeroNode.children[0];
                        if (pos.has(firstChild.name)) {
                            targetRow = pos.get(firstChild.name).row;
                        }
                    }
                    if (targetRow === null) {
                        targetRow = Math.floor(nextRow / 2);
                    }
                    pos.set(zeroName, { row: targetRow, col: 0 });
                }
            } catch (_) { /* safe no-op */ }

            function publicURL(file) {
                // Encode each segment but keep path separators so Supabase can resolve nested paths
                var safePath = String(file).split('/').map(encodeURIComponent).join('/');
                return SUPABASE_URL + "/storage/v1/object/public/" + BUCKET + "/" + safePath;
            }
            function fetchBytes(url) { return fetch(url).then(function (r) { if (!r.ok) throw new Error("HTTP " + r.status); return r.arrayBuffer(); }).then(function (buf) { return new Uint8Array(buf); }); }

            var createdRects = new Map(); var createdLabels = new Map(); var promises = [];
            var drawnCount = 0;
            // --- debug: recolectar urls e incidencias
            var urlsTried = [];
            var urlsOK = [];
            var urlsFail = [];
            items.forEach(function (it) {
                var p = pos.get(it.name); if (!p) { return; }
                var pr = (async function () {
                    try {
                        // If this is a FUTURE placeholder, draw a synthetic frame instead of downloading an image
                        if (it.isFuture || !it.file) {
                            var rect = figma.createRectangle();
                            rect.resize(FRAME_W, FRAME_H);
                            rect.x = p.col * (CELL_W + GAP_X);
                            rect.y = p.row * (CELL_H + GAP_Y);
                            rect.fills = [{ type: 'SOLID', color: { r: 0.12, g: 0.12, b: 0.12 } }];
                            rect.strokes = [{ type: 'SOLID', color: { r: 1, g: 0.55, b: 0 } }];
                            rect.strokeWeight = 2;
                            try { rect.dashPattern = [8, 8]; } catch (_) { }
                            rect.cornerRadius = 12;
                            figma.currentPage.appendChild(rect);
                            createdRects.set(it.name, rect);
                            var _nodeF = nodeMap.get(it.name); if (_nodeF) _nodeF.frame = rect;

                            // Title label (white)
                            await figma.loadFontAsync({ family: "Inter", style: "Bold" });
                            var label = figma.createText();
                            label.fontName = { family: "Inter", style: "Bold" };
                            label.fontSize = 28;
                            label.textAlignHorizontal = 'CENTER';
                            try { label.textAutoResize = 'HEIGHT'; } catch (_) { }
                            var friendlyBaseF = (typeof it.labelText === "string" && it.labelText) ? it.labelText : it.name;
                            friendlyBaseF = capFirst(friendlyBaseF);
                            var friendlyNumberedF = (numberedLabelMap.has(it.name) ? numberedLabelMap.get(it.name) : ("1 " + friendlyBaseF));
                            label.characters = wrapAnyLabel(friendlyNumberedF);
                            label.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
                            try { label.resize(rect.width, label.height); } catch (_) { }
                            figma.currentPage.appendChild(label);
                            label.x = rect.x;
                            label.y = rect.y - (label.height + 12);
                            createdLabels.set(it.name, label);

                            // FUTURE badge (orange pill)
                            try {
                                await figma.loadFontAsync({ family: "Inter", style: "Medium" });
                                var badgeText = figma.createText();
                                badgeText.fontName = { family: "Inter", style: "Medium" };
                                badgeText.fontSize = 14;
                                badgeText.characters = 'FUTURE';
                                badgeText.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
                                try { badgeText.textAutoResize = 'WIDTH_AND_HEIGHT'; } catch (_) { }
                                figma.currentPage.appendChild(badgeText);
                                var padX = 8, padY = 4;
                                var pill = figma.createRectangle();
                                pill.cornerRadius = 999;
                                pill.fills = [{ type: 'SOLID', color: { r: 1, g: 0.55, b: 0 } }];
                                pill.strokes = [];
                                pill.resize(badgeText.width + padX * 2, badgeText.height + padY * 2);
                                pill.x = rect.x + 10;
                                pill.y = rect.y + 10;
                                badgeText.x = pill.x + padX;
                                badgeText.y = pill.y + padY;
                                // Ensure pill behind text
                                try { figma.currentPage.insertChild(Math.max(0, pill.parent.children.indexOf(pill)), pill); } catch (_) { }
                            } catch (_) { }

                            urlsOK.push('future:' + it.name);
                            return;
                        }

                        // Regular image case
                        var url = publicURL(it.file);
                        urlsTried.push(url);
                        var bytes = await fetchBytes(url);
                        var img = figma.createImage(bytes);
                        var rect = figma.createRectangle();
                        var s = (img.getSizeAsync ? await img.getSizeAsync() : { width: FRAME_W, height: FRAME_H });
                        var iw = s.width, ih = s.height;
                        var scale = Math.min(FRAME_W / iw, FRAME_H / ih);
                        var rw = Math.max(1, Math.round(iw * scale));
                        var rh = Math.max(1, Math.round(ih * scale));
                        rect.resize(rw, rh);
                        rect.x = p.col * (CELL_W + GAP_X);
                        rect.y = p.row * (CELL_H + GAP_Y);
                        rect.fills = [{ type: 'IMAGE', imageHash: img.hash, scaleMode: 'FILL' }];
                        rect.strokes = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }];
                        rect.strokeWeight = 1.5;
                        rect.cornerRadius = 12;
                        try { rect.strokeAlign = 'INSIDE'; } catch (_) { }
                        figma.currentPage.appendChild(rect);
                        createdRects.set(it.name, rect);
                        var _node = nodeMap.get(it.name); if (_node) _node.frame = rect;

                        await figma.loadFontAsync({ family: "Inter", style: "Bold" });
                        var label = figma.createText();
                        label.fontName = { family: "Inter", style: "Bold" };
                        label.fontSize = 28;
                        label.textAlignHorizontal = 'CENTER';
                        try { label.textAutoResize = 'HEIGHT'; } catch (_) { }
                        var friendlyBase = (typeof it.labelText === "string" && it.labelText) ? it.labelText : it.name;
                        friendlyBase = capFirst(friendlyBase);
                        var friendlyNumbered = (numberedLabelMap.has(it.name) ? numberedLabelMap.get(it.name) : ("1 " + friendlyBase));
                        label.characters = wrapAnyLabel(friendlyNumbered);
                        label.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
                        try { label.resize(rect.width, label.height); } catch (_) { }
                        figma.currentPage.appendChild(label);
                        label.x = rect.x;
                        label.y = rect.y - (label.height + 12);
                        createdLabels.set(it.name, label);
                        urlsOK.push(url);
                    } catch (err) {
                        urlsFail.push((it.file ? publicURL(it.file) : 'future') + " ⇢ " + (err && err.message ? err.message : String(err)));
                    }
                })();
                promises.push(pr);
            });

            return Promise.all(promises).then(function () {
                // --- Reposicionar archivos no mapeados (no están en EMBEDDED_NODES):
                // Colócalos a la izquierda del iPhone, sin flechas.
                try {
                    var iphoneRect = createdRects.get("0");
                    if (iphoneRect) {
                        var ORPHAN_SIDE_GAP = 60;         // separación horizontal respecto a iPhone
                        var ORPHAN_STACK_GAP = 60;        // separación vertical entre huérfanos
                        var orphanIndex = 0;
                        // Colocar en el mismo orden que en 'items'
                        for (var k = 0; k < items.length; k++) {
                            var it = items[k];
                            if (!it.isUnmapped) continue;
                            var r = createdRects.get(it.name);
                            var l = createdLabels.get(it.name);
                            if (!r) continue;
                            r.x = iphoneRect.x - ORPHAN_SIDE_GAP - r.width;
                            r.y = iphoneRect.y + orphanIndex * (FRAME_H + ORPHAN_STACK_GAP);
                            if (l) {
                                l.x = r.x;
                                l.y = r.y - (l.height + 12);
                            }
                            orphanIndex++;
                        }
                    }
                } catch (_) { }

                // --- Enforce consistent compact spacing for any parent with exactly 2 children
                try {
                    nodeMap.forEach(function (n) {
                        if (!n || !n.children || n.children.length !== 2) return;

                        const c1 = n.children[0], c2 = n.children[1];
                        const parentRect = n.frame || createdRects.get(n.name);
                        const r1 = createdRects.get(c1.name);
                        const r2 = createdRects.get(c2.name);
                        if (!parentRect || !r1 || !r2) return;

                        // Center children around parent's center with a fixed, compact offset
                        const midY = parentRect.y + parentRect.height / 2;
                        r1.y = (midY - CHILD_PAIR_OFFSET) - (r1.height / 2);
                        r2.y = (midY + CHILD_PAIR_OFFSET) - (r2.height / 2);

                        // Move their labels accordingly
                        const l1 = createdLabels.get(c1.name);
                        const l2 = createdLabels.get(c2.name);
                        if (l1) l1.y = r1.y - (l1.height + 12);
                        if (l2) l2.y = r2.y - (l2.height + 12);
                    });
                } catch (_) { }

                // Background para clústeres (ids que comparten baseId con sufijos ~pN)
                try {
                    var clusters = new Map(); // baseId -> array de rects
                    createdRects.forEach(function (rect, id) {
                        var base = clusterBaseId(id);
                        if (base !== id) {
                            if (!clusters.has(base)) clusters.set(base, []);
                            clusters.get(base).push(rect);
                        }
                    });
                    clusters.forEach(function (rects, base) {
                        if (!Array.isArray(rects) || rects.length < 2) return; // sólo cuando hay 2+ partes
                        // calcular bounding box
                        var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                        for (var i = 0; i < rects.length; i++) {
                            var r = rects[i];
                            if (!r) continue;
                            minX = Math.min(minX, r.x);
                            minY = Math.min(minY, r.y);
                            maxX = Math.max(maxX, r.x + r.width);
                            maxY = Math.max(maxY, r.y + r.height);
                        }
                        if (!isFinite(minX) || !isFinite(minY) || !isFinite(maxX) || !isFinite(maxY)) return;
                        var PAD = 16; // padding alrededor del grupo
                        var TOP_EXTRA = 96; // extra top space to fully cover titles
                        var bg = figma.createRectangle();
                        bg.x = minX - PAD;
                        bg.y = minY - PAD - TOP_EXTRA;
                        bg.resize((maxX - minX) + PAD * 2, (maxY - minY) + PAD * 2 + TOP_EXTRA);
                        bg.cornerRadius = 12;
                        // fondo muy suave + borde negro fino
                        bg.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.98, b: 0.98 }, opacity: 0.6 }];
                        bg.strokes = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }];
                        bg.strokeWeight = 1;
                        try { bg.strokeAlign = 'INSIDE'; } catch (_) { }
                        // Enviar el fondo detrás de las capturas del clúster
                        try { figma.currentPage.insertChild(0, bg); } catch (_) { figma.currentPage.appendChild(bg); }
                    });
                } catch (_) { }

                try {
                    nodeMap.forEach(function (n) {
                        if (!n || !n.children || !n.children.length) return;
                        var parentRect = n.frame || createdRects.get(n.name);
                        if (!parentRect) return;
                        for (var i = 0; i < n.children.length; i++) {
                            var child = n.children[i];
                            // Skip connectors into cluster parts (allow only ~p1)
                            if (isClusterPart(child.name) && clusterPartIndex(child.name) > 1) continue;
                            // No dibujar flechas si alguno es "huérfano" (no mapeado)
                            if (unmappedSet.has(n.name) || unmappedSet.has(child.name)) continue;
                            var childRect = child && (child.frame || createdRects.get(child.name));
                            if (!childRect) continue;
                            try {
                                var conn = figma.createConnector();
                                conn.connectorStart = { position: { x: parentRect.x + parentRect.width, y: parentRect.y + parentRect.height / 2 } };
                                conn.connectorEnd = { position: { x: childRect.x, y: childRect.y + childRect.height / 2 } };
                                try { conn.connectorLineType = 'STRAIGHT'; } catch (_) { }
                                conn.strokeWeight = 2;
                                conn.strokes = [{ type: 'SOLID', color: { r: 1, g: 0.55, b: 0 } }];
                            } catch (err) { }
                        }
                    });
                } catch (e) { }
                // Manual extra connector: Register ("0.0.1") -> Google Map Location Permission ("0.0.0.0.0.0.1")
                try {
                    var fromRect = createdRects.get("0.0.1");
                    var toRect = createdRects.get("0.0.0.0.0.0.1");
                    if (fromRect && toRect) {
                        var extra = figma.createConnector();
                        extra.connectorStart = { position: { x: fromRect.x + fromRect.width, y: fromRect.y + fromRect.height / 2 } };
                        extra.connectorEnd = { position: { x: toRect.x, y: toRect.y + toRect.height / 2 } };
                        try { extra.connectorLineType = 'STRAIGHT'; } catch (_) { }
                        extra.strokeWeight = 2;
                        extra.strokes = [{ type: 'SOLID', color: { r: 1, g: 0.55, b: 0 } }];
                    }
                } catch (_) { }
                // Manual extra connector: Login ("0.0") -> Loading ("0.0.0.0.0.0")
                try {
                    var fromLogin = createdRects.get("0.0");
                    var toLoading = createdRects.get("0.0.0.0.0.0");
                    if (fromLogin && toLoading) {
                        var extra2 = figma.createConnector();
                        extra2.connectorStart = { position: { x: fromLogin.x + fromLogin.width, y: fromLogin.y + fromLogin.height / 2 } };
                        extra2.connectorEnd = { position: { x: toLoading.x, y: toLoading.y + toLoading.height / 2 } };
                        try { extra2.connectorLineType = 'STRAIGHT'; } catch (_) { }
                        extra2.strokeWeight = 2;
                        extra2.strokes = [{ type: 'SOLID', color: { r: 1, g: 0.55, b: 0 } }];
                    }
                } catch (_) { }

                // Manual extra connector: Google Map Zone 2 ("0.0.0.0.0.0.1.0.0") -> Google Map Zone 3 ("0.0.0.0.0.0.1.0.0.0")
                try {
                    var fromZone2 = createdRects.get("0.0.0.0.0.0.1.0.0");
                    var toZone3 = createdRects.get("0.0.0.0.0.0.1.0.0.0");
                    if (fromZone2 && toZone3) {
                        var extra3 = figma.createConnector();
                        extra3.connectorStart = { position: { x: fromZone2.x + fromZone2.width, y: fromZone2.y + fromZone2.height / 2 } };
                        extra3.connectorEnd = { position: { x: toZone3.x, y: toZone3.y + toZone3.height / 2 } };
                        try { extra3.connectorLineType = 'STRAIGHT'; } catch (_) { }
                        extra3.strokeWeight = 2;
                        extra3.strokes = [{ type: 'SOLID', color: { r: 1, g: 0.55, b: 0 } }];
                    }
                } catch (_) { }
                // ===== Canvas background (BLACK) covering entire viewport (oversized) =====
                try {
                    const vp = figma.viewport.bounds; // visible area of the canvas
                    const M = 100000; // bigger oversize to cover any canvas movement
                    const bgCanvas = figma.createRectangle();
                    bgCanvas.x = vp.x - M;
                    bgCanvas.y = vp.y - M;
                    bgCanvas.resize(vp.width + M * 2, vp.height + M * 2);
                    bgCanvas.cornerRadius = 0;
                    bgCanvas.fills = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }]; // BLACK
                    bgCanvas.name = "Background";
                    bgCanvas.locked = true;
                    try { bgCanvas.strokeWeight = 0; } catch (_) { }
                    // Send to back
                    try { figma.currentPage.insertChild(0, bgCanvas); } catch (_) { figma.currentPage.appendChild(bgCanvas); }
                } catch (_) { }
                // Final one-shot summary notification
                try {
                    var summary = "✅ Pantallas: " + urlsOK.length + "  |  ❌ Fallos: " + urlsFail.length;
                    if (urlsFail.length) {
                        // Extract filenames from failed URLs for readability
                        var failedNames = urlsFail.slice(0, 6).map(function (s) {
                            var m = String(s).match(/\/movil\/([^?\s]+)$/); // capture trailing name
                            return m ? decodeURIComponent(m[1]) : s;
                        });
                        summary += "\nFaltan/No cargan (ejemplos):\n- " + failedNames.join("\n- ");
                    }
                    notif(summary);
                } catch (_) { }
            });
        });
    })
        .catch(function (err) { figma.notify("⚠️ Error generando diagrama: " + ((err && err.message) ? err.message : String(err))); });
})();

