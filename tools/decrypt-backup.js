// Script giải mã và giải nén file backup .sql.gz.enc
// Node.js >= 16, cần cài: npm install zlib

const fs = require('fs');
const zlib = require('zlib');
const { createDecipheriv } = require('crypto');

if (process.argv.length < 5) {
  console.log('Usage: node decrypt-backup.js <input.enc> <output.sql> <32-char-key>');
  process.exit(1);
}

const [inputFile, outputFile, key] = process.argv.slice(2);
if (!key || key.length !== 32) {
  console.error('Encryption key must be 32 characters!');
  process.exit(1);
}

const encrypted = fs.readFileSync(inputFile);
const iv = encrypted.slice(0, 16);
const data = encrypted.slice(16);

const decipher = createDecipheriv('aes-256-gcm', Buffer.from(key, 'utf8'), iv);
let decrypted;
try {
  decrypted = Buffer.concat([decipher.update(data), decipher.final()]);
} catch (e) {
  console.error('Decryption failed:', e.message);
  process.exit(1);
}

zlib.gunzip(decrypted, (err, sql) => {
  if (err) {
    console.error('Gzip decompress failed:', err.message);
    process.exit(1);
  }
  fs.writeFileSync(outputFile, sql);
  console.log('✅ Decrypt & decompress done:', outputFile);
});
