// Script para verificar cuentas en Ganache
module.exports = async function(callback) {
  try {
    console.log("=== Verificación de Ganache ===");
    
    // Obtener cuentas
    const accounts = await web3.eth.getAccounts();
    console.log("Cuentas disponibles:");
    accounts.forEach((account, index) => {
      console.log(`${index}: ${account}`);
    });
    
    // Verificar la cuenta principal que mencionaste
    const expectedAccount = "0x6DB272507Df7E9dA070F7B71d66ac7a121b88587";
    const accountExists = accounts.includes(expectedAccount);
    console.log(`\nCuenta principal (${expectedAccount}): ${accountExists ? '✅ ENCONTRADA' : '❌ NO ENCONTRADA'}`);
    
    // Obtener balance de la cuenta principal
    if (accountExists) {
      const balance = await web3.eth.getBalance(expectedAccount);
      console.log(`Balance: ${web3.utils.fromWei(balance, 'ether')} ETH`);
    }
    
    // Verificar información de red
    const networkId = await web3.eth.net.getId();
    console.log(`\nNetwork ID: ${networkId}`);
    
    const blockNumber = await web3.eth.getBlockNumber();
    console.log(`Último bloque: ${blockNumber}`);
    
    callback();
  } catch (error) {
    console.error("Error:", error);
    callback(error);
  }
};
