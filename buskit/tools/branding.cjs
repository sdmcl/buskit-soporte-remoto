// Reproduce the checked-in brand assets from the unmodified official BUSKIT vectors.
const fs = require('node:fs');
const path = require('node:path');
const { Resvg } = require('@resvg/resvg-js');
const root = path.resolve(__dirname, '../..');
const brand = JSON.parse(fs.readFileSync(path.join(root, 'buskit/brand.json')));
const out = path.join(root, 'buskit/brand');
const rustConstants = {DISPLAY_NAME: brand.name, APP_ID: brand.appId, ID_SERVER: brand.idServer, RELAY_SERVER: brand.relayServer, PUBLIC_KEY: brand.publicKey};
fs.writeFileSync(path.join(root, 'buskit/brand.rs'), '// Generated from buskit/brand.json by buskit/tools/branding.cjs.\n' + Object.entries(rustConstants).map(([key,value]) => `pub const ${key}: &str = ${JSON.stringify(value)};`).join('\n') + '\n');
fs.writeFileSync(path.join(root, 'flutter/lib/buskit_brand.dart'), '// Generated from buskit/brand.json by buskit/tools/branding.cjs.\n' + `const buskitName = ${JSON.stringify(brand.name)};\nconst buskitEdition = ${JSON.stringify(brand.edition)};\nconst buskitRepository = ${JSON.stringify(brand.repository)};\n`);
const read = name => fs.readFileSync(path.join(out, 'source', name), 'utf8');
const nested = (svg, x, y, width, height) => svg.replace(/<svg[^>]+>/, tag =>
  tag.replace(/\s(?:width|height)="[^"]*"/g, '').replace('<svg', `<svg x="${x}" y="${y}" width="${width}" height="${height}"`));
const svg = (w, h, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><title>${brand.name}</title>${body}</svg>`;
const logo = (white) => svg(1200, 380,
  nested(read(white ? 'buskit-white.svg' : 'buskit-color.svg'), 20, 20, 1160, 278) +
  `<text x="340" y="352" font-family="Segoe UI,Arial,sans-serif" font-size="60" font-weight="600" letter-spacing="3" fill="${white ? '#FFFFFF' : brand.colors.navy}">SOPORTE REMOTO</text>`);
const icon = svg(512, 512,
  `<rect width="512" height="512" rx="106" fill="${brand.colors.navy}"/>` +
  nested(read('buskit-icon-white.svg'), 38, 20, 404, 404) +
  `<circle cx="414" cy="410" r="85" fill="${brand.colors.teal}" stroke="#FFFFFF" stroke-width="12"/>` +
  '<path d="M384 365 L445 408 L417 414 L406 441 Z" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="5" stroke-linejoin="round"/>');
function save(name, data) { fs.writeFileSync(path.join(out, name), data); }
function png(source, width) {
  return new Resvg(source, {fitTo: {mode: 'width', value: width}, font: {loadSystemFonts: true}}).render().asPng();
}
save('buskit-soporte-remoto.svg', logo(false));
save('buskit-soporte-remoto-white.svg', logo(true));
save('buskit-soporte-remoto.png', png(logo(false), 1200));
save('buskit-soporte-remoto-white.png', png(logo(true), 1200));
save('buskit-soporte-remoto-icon.svg', icon);
save('buskit-soporte-remoto-icon.png', png(icon, 512));
const sizes = [16, 24, 32, 48, 64, 128, 256];
const images = sizes.map(size => png(icon, size));
const header = Buffer.alloc(6 + 16 * sizes.length);
header.writeUInt16LE(1, 2);
header.writeUInt16LE(sizes.length, 4);
let offset = header.length;
sizes.forEach((size, i) => {
  const base = 6 + 16 * i;
  header[base] = header[base + 1] = size === 256 ? 0 : size;
  header.writeUInt16LE(1, base + 4);
  header.writeUInt16LE(32, base + 6);
  header.writeUInt32LE(images[i].length, base + 8);
  header.writeUInt32LE(offset, base + 12);
  offset += images[i].length;
});
save('buskit-soporte-remoto.ico', Buffer.concat([header, ...images]));
const copies = {
  'buskit-soporte-remoto.png': ['flutter/assets/logo.png', 'flutter/assets/logo_light.png'],
  'buskit-soporte-remoto-white.png': ['flutter/assets/logo_dark.png'],
  'buskit-soporte-remoto-icon.png': ['flutter/assets/icon.png', 'res/icon.png'],
  'buskit-soporte-remoto-icon.svg': ['flutter/assets/icon.svg'],
  'buskit-soporte-remoto.ico': ['flutter/assets/icon.ico', 'res/icon.ico', 'res/tray-icon.ico', 'flutter/windows/runner/resources/app_icon.ico'],
};
for (const [source, destinations] of Object.entries(copies)) {
  for (const destination of destinations) fs.copyFileSync(path.join(out, source), path.join(root, destination));
}
const preview = svg(1440, 850,
  '<rect width="1440" height="850" fill="#F3F7FA"/>' +
  '<rect x="50" y="50" width="1340" height="445" rx="32" fill="#FFFFFF"/>' +
  nested(logo(false), 190, 85, 1060, 335) +
  `<rect x="50" y="530" width="1340" height="270" rx="32" fill="${brand.colors.navy}"/>` +
  nested(icon, 90, 565, 200, 200) + nested(logo(true), 370, 555, 730, 230));
save('preview.png', png(preview, 1440));
console.log(`Generated ${brand.name}: SVG, PNG, ICO and Windows/Flutter resources.`);
