/*
 * Render one image master into the PNG sizes used by the ecosystem and a
 * Windows ICO containing those PNG images.
 *
 * Usage:
 *   node scripts/render-ecosystem-icon.cjs input.png output-stem
 */

const fs = require("node:fs");
const path = require("node:path");
const sharp = require("sharp");

const [, , inputArgument, outputStemArgument] = process.argv;
if (!inputArgument || !outputStemArgument) {
  console.error("usage: render-ecosystem-icon.cjs <input-image> <output-stem>");
  process.exit(2);
}

const sizes = [16, 24, 32, 48, 64, 128, 256, 512];
const inputPath = path.resolve(inputArgument);
const outputStem = path.resolve(outputStemArgument);

function icoEntry(size, image, offset) {
  const entry = Buffer.alloc(16);
  entry.writeUInt8(size === 256 ? 0 : size, 0);
  entry.writeUInt8(size === 256 ? 0 : size, 1);
  entry.writeUInt8(0, 2);
  entry.writeUInt8(0, 3);
  entry.writeUInt16LE(1, 4);
  entry.writeUInt16LE(32, 6);
  entry.writeUInt32LE(image.length, 8);
  entry.writeUInt32LE(offset, 12);
  return entry;
}

async function main() {
  fs.mkdirSync(path.dirname(outputStem), { recursive: true });

  const rendered = [];
  for (const size of sizes) {
    const image = await sharp(inputPath, { density: 384 })
      .resize(size, size, { fit: "contain" })
      .png({ compressionLevel: 9, palette: false })
      .toBuffer();
    fs.writeFileSync(`${outputStem}-${size}.png`, image);
    if (size <= 256) {
      rendered.push({ size, image });
    }
  }

  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(rendered.length, 4);

  let offset = header.length + rendered.length * 16;
  const entries = rendered.map(({ size, image }) => {
    const entry = icoEntry(size, image, offset);
    offset += image.length;
    return entry;
  });

  fs.writeFileSync(
    `${outputStem}.ico`,
    Buffer.concat([header, ...entries, ...rendered.map(({ image }) => image)]),
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
