const batasPiksel = 24000000;
const tandaPng = [137, 80, 78, 71, 13, 10, 26, 10];
const penandaUkuranJpeg = new Set([
  0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb,
  0xcd, 0xce, 0xcf,
]);

function infoFoto(data) {
  const view = new DataView(data.buffer, data.byteOffset, data.byteLength);
  if (data.length >= 24 && tandaPng.every((byte, i) => data[i] === byte)) {
    return { lebar: view.getUint32(16), tinggi: view.getUint32(20), jpg: false };
  }
  if (data[0] !== 0xff || data[1] !== 0xd8) {
    throw new Error('Format foto harus JPG atau PNG.');
  }

  let lebar = 0;
  let tinggi = 0;
  let punyaMetadata = false;
  let offset = 2;
  while (offset + 3 < data.length && data[offset] === 0xff) {
    while (data[offset] === 0xff) offset++;
    const penanda = data[offset++];
    if (penanda === 0xda || penanda === 0xd9 || offset + 2 > data.length) break;
    const panjang = view.getUint16(offset);
    if (panjang < 2 || offset + panjang > data.length) break;
    if (penandaUkuranJpeg.has(penanda) && panjang >= 7) {
      tinggi = view.getUint16(offset + 3);
      lebar = view.getUint16(offset + 5);
    }
    if (penanda === 0xe1 || penanda === 0xe2 || penanda === 0xed) {
      punyaMetadata = true;
    }
    offset += panjang;
  }
  return { lebar, tinggi, jpg: true, punyaMetadata };
}

async function sidikPiksel(gambar) {
  const sisi = 512;
  const kanvas = new OffscreenCanvas(sisi, sisi);
  const ctx = kanvas.getContext('2d', { willReadFrequently: true });
  const { width, height } = gambar;
  const jumlah = Math.ceil(width / sisi) * Math.ceil(height / sisi);
  const ringkasan = new Uint8Array(8 + jumlah * 32);
  const view = new DataView(ringkasan.buffer);
  view.setUint32(0, width);
  view.setUint32(4, height);
  let offset = 8;
  for (let y = 0; y < height; y += sisi) {
    for (let x = 0; x < width; x += sisi) {
      const w = Math.min(sisi, width - x);
      const h = Math.min(sisi, height - y);
      ctx.clearRect(0, 0, w, h);
      ctx.drawImage(gambar, x, y, w, h, 0, 0, w, h);
      const rgba = ctx.getImageData(0, 0, w, h).data;
      const hash = await crypto.subtle.digest('SHA-256', rgba);
      ringkasan.set(new Uint8Array(hash), offset);
      offset += 32;
    }
  }
  const hash = await crypto.subtle.digest('SHA-256', ringkasan);
  return Array.from(new Uint8Array(hash), byte => byte.toString(16).padStart(2, '0')).join('');
}

function polaFoto(gambar) {
  const ctx = new OffscreenCanvas(9, 8).getContext('2d');
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(gambar, 0, 0, 9, 8);
  const rgba = ctx.getImageData(0, 0, 9, 8).data;
  const terang = i => 299 * rgba[i] + 587 * rgba[i + 1] + 114 * rgba[i + 2];
  let pola = '';
  for (let y = 0; y < 8; y++) {
    for (let x = 0; x < 8; x++) {
      const i = (y * 9 + x) * 4;
      pola += terang(i) > terang(i + 4) ? '1' : '0';
    }
  }
  return pola;
}

async function kompresJpeg(gambar, ukuranAwal) {
  const skala = Math.min(1, 1600 / Math.max(gambar.width, gambar.height));
  if (skala === 1 && ukuranAwal <= 450000) return null;
  const kanvas = new OffscreenCanvas(
    Math.max(1, Math.round(gambar.width * skala)),
    Math.max(1, Math.round(gambar.height * skala)),
  );
  const ctx = kanvas.getContext('2d', { alpha: false });
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(gambar, 0, 0, kanvas.width, kanvas.height);
  const blob = await kanvas.convertToBlob({ type: 'image/jpeg', quality: 0.84 });
  if (blob.type !== 'image/jpeg' || blob.size >= ukuranAwal) return null;
  return new Uint8Array(await blob.arrayBuffer());
}

self.onmessage = async ({ data: { data, kompres } }) => {
  let gambar;
  try {
    if (typeof OffscreenCanvas !== 'function' || !self.crypto?.subtle) {
      throw new Error('Buka aplikasi di Chrome melalui HTTPS atau localhost untuk memproses foto.');
    }
    const info = infoFoto(data);
    if (!info.lebar || !info.tinggi || info.lebar * info.tinggi > batasPiksel) {
      throw new Error('Foto rusak atau melebihi 24 megapiksel.');
    }
    gambar = await createImageBitmap(
      new Blob([data], { type: info.jpg ? 'image/jpeg' : 'image/png' }),
    );
    const piksel = await sidikPiksel(gambar);
    const pola = polaFoto(gambar);
    const hasil = kompres && info.jpg && !info.punyaMetadata
      ? await kompresJpeg(gambar, data.length)
      : null;
    self.postMessage({ piksel, pola, data: hasil }, hasil ? [hasil.buffer] : []);
  } catch (galat) {
    self.postMessage({
      galat: galat instanceof DOMException ? 'Foto belum dapat dibaca.' : galat.message,
    });
  } finally {
    gambar?.close();
  }
};