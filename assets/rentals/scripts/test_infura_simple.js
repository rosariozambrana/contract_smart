// Script para probar conexión a Infura usando web3 de Truffle
module.exports = async function(callback) {
  try {
    console.log("=== Probando conexión a Infura Sepolia ===");
    
    const infuraUrl = `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`;
    console.log(`URL: https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`);
    console.log(`API Key: ${process.env.INFURA_API_KEY}`);
    
    // Usar el web3 de Truffle
    const HDWalletProvider = require('@truffle/hdwallet-provider');
    const provider = new HDWalletProvider(
      process.env.MNEMONIC,
      infuraUrl
    );
    
    // Configurar web3 con el provider
    const Web3 = require('web3');
    const web3Instance = new Web3(provider);
    
    // Probar conexión
    const networkId = await web3Instance.eth.net.getId();
    console.log(`✅ Network ID: ${networkId} (Sepolia = 11155111)`);
    
    const blockNumber = await web3Instance.eth.getBlockNumber();
    console.log(`✅ Último bloque: ${blockNumber}`);
    
    // Obtener cuentas
    const accounts = await web3Instance.eth.getAccounts();
    console.log(`✅ Cuenta principal: ${accounts[0]}`);
    
    // Verificar balance
    const balance = await web3Instance.eth.getBalance(accounts[0]);
    console.log(`Balance en Sepolia: ${web3Instance.utils.fromWei(balance, 'ether')} ETH`);
    
    console.log("\n🎉 ¡Conexión a Infura Sepolia exitosa!");
    console.log("\n📋 Para obtener ETH de testnet:");
    console.log("Ve a: https://sepoliafaucet.com/");
    console.log(`Envía ETH a: ${accounts[0]}`);
    
    provider.engine.stop();
    callback();
  } catch (error) {
    console.error("❌ Error de conexión:", error.message);
    
    if (error.message.includes('invalid project id')) {
      console.log("\n🔑 Tu API Key de Infura no es válido:");
      console.log("1. Ve a https://infura.io/dashboard");
      console.log("2. Inicia sesión o crea una cuenta gratuita");
      console.log("3. Crea un nuevo proyecto");
      console.log("4. Copia el API Key y actualiza tu .env");
      console.log("5. Asegúrate de habilitar Ethereum en el proyecto");
    }
    
    callback(error);
  }
};
