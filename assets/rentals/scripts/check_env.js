// Script simple para verificar variables de entorno
require('dotenv').config();

console.log("=== Verificación de Variables de Entorno ===");
console.log(`INFURA_API_KEY: ${process.env.INFURA_API_KEY || 'NO ENCONTRADO'}`);
console.log(`MNEMONIC: ${process.env.MNEMONIC ? 'CONFIGURADO ✅' : 'NO ENCONTRADO ❌'}`);

console.log("\n=== Archivo .env cargado desde ===");
console.log(__dirname);

if (!process.env.INFURA_API_KEY) {
    console.log("\n❌ PROBLEMA: INFURA_API_KEY no está definido");
    console.log("Soluciones:");
    console.log("1. Verifica que el archivo .env esté en el directorio correcto");
    console.log("2. Verifica que no haya espacios en la línea INFURA_API_KEY=...");
    console.log("3. Reinicia la terminal después de modificar .env");
}
