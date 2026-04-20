export const runtime = "nodejs";

function escapeXml(s: string) {
  return s
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id: idRaw } = await params;
  const id = Number(idRaw) || 0;

  const url = new URL(req.url);
  const nameRaw = url.searchParams.get("name") || `Item #${id}`;
  const brandRaw = url.searchParams.get("brand") || "";

  const name = escapeXml(nameRaw.slice(0, 44));
  const brand = escapeXml(brandRaw.slice(0, 24));

  const hue = (id * 47) % 360;
  const hue2 = (hue + 36) % 360;

  const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="500" viewBox="0 0 800 500" role="img" aria-label="${name}">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="hsl(${hue} 90% 60%)" stop-opacity="0.95"/>
      <stop offset="1" stop-color="hsl(${hue2} 90% 55%)" stop-opacity="0.95"/>
    </linearGradient>
    <radialGradient id="v" cx="30%" cy="20%" r="90%">
      <stop offset="0" stop-color="#0b1020" stop-opacity="0.2"/>
      <stop offset="1" stop-color="#0b1020" stop-opacity="0.85"/>
    </radialGradient>
  </defs>

  <rect width="800" height="500" rx="36" fill="url(#g)"/>
  <rect width="800" height="500" rx="36" fill="url(#v)"/>

  <circle cx="640" cy="120" r="90" fill="rgba(255,255,255,0.12)"/>
  <circle cx="660" cy="110" r="55" fill="rgba(255,255,255,0.12)"/>
  <path d="M70 360 C 170 290, 270 430, 370 350 S 570 320, 730 390"
        fill="none" stroke="rgba(255,255,255,0.18)" stroke-width="10" stroke-linecap="round"/>

  <g transform="translate(56 320)">
    <rect x="0" y="-160" width="688" height="170" rx="24" fill="rgba(11,16,32,0.55)" stroke="rgba(255,255,255,0.16)"/>
    ${brand ? `<text x="24" y="-110" font-family="ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial" font-size="20" fill="rgba(232,236,255,0.78)">${brand}</text>` : ""}
    <text x="24" y="-72" font-family="ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial" font-size="34" font-weight="800" fill="#e8ecff">${name}</text>
    <text x="24" y="-28" font-family="ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial" font-size="16" fill="rgba(232,236,255,0.72)">TradeHub • Placeholder image</text>
  </g>
</svg>`;

  return new Response(svg, {
    headers: {
      "Content-Type": "image/svg+xml; charset=utf-8",
      "Cache-Control": "public, max-age=86400",
    },
  });
}

