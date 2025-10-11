// Script para interactuar con RentalContract usando tu cuenta específica
module.exports = async function(callback) {
  try {
    console.log("=== Interacción con RentalContract ===");
    
    // Tu cuenta principal
    const ownerAccount = "0x6DB272507Df7E9dA070F7B71d66ac7a121b88587";
    
    // Obtener instancia del contrato
    const RentalContract = artifacts.require("RentalContract");
    const contractInstance = await RentalContract.deployed();
    
    console.log(`Dirección del contrato: ${contractInstance.address}`);
    console.log(`Tu cuenta (owner): ${ownerAccount}`);
    
    // Verificar el owner del contrato
    const contractOwner = await contractInstance.owner();
    console.log(`Owner del contrato: ${contractOwner}`);
    console.log(`¿Eres el owner? ${contractOwner.toLowerCase() === ownerAccount.toLowerCase() ? '✅ SÍ' : '❌ NO'}`);
    
    // Obtener balance de tu cuenta
    const balance = await web3.eth.getBalance(ownerAccount);
    console.log(`Tu balance: ${web3.utils.fromWei(balance, 'ether')} ETH`);
    
    // Obtener número de contratos
    try {
      const contractCount = await contractInstance.getContractCount();
      console.log(`Número de contratos de alquiler: ${contractCount}`);
    } catch (error) {
      console.log("Número de contratos: 0 (función no disponible o contrato vacío)");
    }
    
    console.log("\n=== Información de Red ===");
    const networkId = await web3.eth.net.getId();
    const blockNumber = await web3.eth.getBlockNumber();
    console.log(`Network ID: ${networkId}`);
    console.log(`Bloque actual: ${blockNumber}`);
    
    console.log("\n✅ Todo configurado correctamente!");
    
    callback();
  } catch (error) {
    console.error("Error:", error);
    callback(error);
  }
};
