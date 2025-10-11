// Script para probar conexión a Infura Sepolia
module.exports = async function(callback) {
  try {
    console.log("=== Probando conexión a Infura Sepolia ===");
    
    const Web3 = require('web3');
    const infuraUrl = `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`;
    
    console.log(`URL de conexión: ${infuraUrl}`);
    console.log(`API Key: ${process.env.INFURA_API_KEY}`);
    
    // Crear instancia de Web3
    const web3 = new Web3(infuraUrl);
    
    // Probar conexión
    const networkId = await web3.eth.net.getId();
    console.log(`✅ Network ID: ${networkId} (Sepolia = 11155111)`);
    
    const blockNumber = await web3.eth.getBlockNumber();
    console.log(`✅ Último bloque: ${blockNumber}`);
    
    // Verificar tu cuenta en Sepolia
    const accounts = web3.eth.accounts.wallet.add(process.env.MNEMONIC);
    console.log(`✅ Cuenta derivada del mnemonic: ${accounts[0].address}`);
    
    // Verificar balance (si tiene ETH de testnet)
    const balance = await web3.eth.getBalance(accounts[0].address);
    console.log(`Balance en Sepolia: ${web3.utils.fromWei(balance, 'ether')} ETH`);
    
    console.log("\n🎉 ¡Conexión a Infura Sepolia exitosa!");
    
    callback();
  } catch (error) {
    console.error("❌ Error de conexión:", error.message);
    
    if (error.message.includes('Invalid API Key')) {
      console.log("\n🔑 Problema con API Key. Pasos para solucionarlo:");
      console.log("1. Ve a https://infura.io/dashboard");
      console.log("2. Inicia sesión o crea una cuenta");
      console.log("3. Crea un nuevo proyecto");
      console.log("4. Copia el API Key y actualiza tu .env");
    }
    
    callback(error);
  }
};
