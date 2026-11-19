const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const src = path.join(root, "index.html");
const destDir = path.join(root, "www");
const dest = path.join(destDir, "index.html");

fs.mkdirSync(destDir, { recursive: true });
let html = fs.readFileSync(src, "utf8");

if (!html.includes("apple-mobile-web-app-capable")) {
  html = html.replace(
    /<meta name="viewport"[^>]*>/,
    `<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
<meta name="mobile-web-app-capable" content="yes" />
<meta name="theme-color" content="#071018" />
<link rel="manifest" href="manifest.webmanifest" />
<link rel="apple-touch-icon" href="icons/icon-180.png" />`
  );
}

html = html.replace(/width:\s*min\(100vw,\s*430px\);/g, "width: 100%; max-width: 100vw;");
html = html.replace(/padding:\s*14px 14px 0;/g, "padding: calc(14px + env(safe-area-inset-top)) 14px 0;");
html = html.replace(/bottom:\s*18px;\s*inset-inline:\s*16px;/g, "bottom: calc(18px + env(safe-area-inset-bottom)); inset-inline: 16px;");

if (!html.includes("serviceWorker")) {
  html = html.replace(
    "</body>",
    `<script>
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => navigator.serviceWorker.register("./sw.js").catch(() => {}));
}
</script>
</body>`
  );
}

fs.writeFileSync(dest, html, "utf8");
console.log("Synced www/index.html");
