// BOOTSTRAP FIJO para Figma GPT
(async () => {
    const REMOTE_JS =
        "https://mzczxyksaktchwnvvfpv.supabase.co/storage/v1/object/public/fotos/code/figma_flow.js";

    try {
        const url = REMOTE_JS + "?t=" + Date.now(); // evitar caché
        const res = await fetch(url, { cache: "no-store" });
        if (!res.ok) throw new Error("HTTP " + res.status + " al descargar script");

        const src = await res.text();
        new Function(src + "\n//# sourceURL=remote-figma-flow.js")();
    } catch (e) {
        figma.notify("❌ No se pudo cargar el script remoto: " + (e.message || e));
    }
})();