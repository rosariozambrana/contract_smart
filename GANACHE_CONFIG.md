# 🎉 Configuración Completa de Ganache + Truffle

## ✅ Estado Actual: FUNCIONANDO PERFECTAMENTE

### 📊 Información de Ganache Desktop
- **URL:** `http://192.168.1.17:7545`
- **Network ID:** `5777`
- **Directorio del proyecto:** `C:\Users\Angela\Documents\msterias_2025\software_mesa\proygrupalsw\rentals\assets\rentals`

### 👤 Tu Cuenta Principal (Owner)
- **Dirección:** `0x6DB272507Df7E9dA070F7B71d66ac7a121b88587`
- **Private Key:** `0x5f6bdf716abc0fd3ba85dbafc4ce9d7fdba21a92770707f203064b1c54d907ac`
- **Mnemonic:** `window health permit venture valid edge bridge example correct kite panda vacuum`
- **Balance actual:** `99.936 ETH`
- **Posición:** Cuenta #0 (primera cuenta)

### 🏠 Contrato RentalContract
- **Dirección:** `0xf337f5f0Df9aBe725650b448237e253dFefe6b60`
- **Owner verificado:** ✅ Eres el propietario del contrato
- **Estado:** Desplegado y funcionando
- **Bloque de deploy:** 10

### 🔧 Configuración en .env
```bash
# Ganache Local
BLOCKCHAIN_RPC_URL_LOCAL=http://192.168.1.17:7545
BLOCKCHAIN_CHAIN_ID_LOCAL=5777
BLOCKCHAIN_CONTRACT_ADDRESS_LOCAL=0xf337f5f0Df9aBe725650b448237e253dFefe6b60
BLOCKCHAIN_ACCOUNT_ADDRESS=0x6DB272507Df7E9dA070F7B71d66ac7a121b88587
BLOCKCHAIN_PRIVATE_KEY=0x5f6bdf716abc0fd3ba85dbafc4ce9d7fdba21a92770707f203064b1c54d907ac
MNEMONIC="window health permit venture valid edge bridge example correct kite panda vacuum"
```

### 🚀 Comandos Útiles

#### Verificar estado
```bash
npx truffle exec scripts/verify_ganache.js --network development
npx truffle exec scripts/interact_contract.js --network development
```

#### Deploy y compilación
```bash
npx truffle compile
npx truffle migrate --network development --reset
```

#### Interacción
```bash
npx truffle console --network development
```

### 📱 Para usar en Flutter/Dart

```dart
// Configuración Web3
const String rpcUrl = "http://192.168.1.17:7545";
const int chainId = 5777;
const String contractAddress = "0xf337f5f0Df9aBe725650b448237e253dFefe6b60";
const String ownerAddress = "0x6DB272507Df7E9dA070F7B71d66ac7a121b88587";
const String privateKey = "0x5f6bdf716abc0fd3ba85dbafc4ce9d7fdba21a92770707f203064b1c54d907ac";
```

### 🎯 Próximos Pasos

1. **Crear contratos de alquiler** usando las funciones del smart contract
2. **Integrar con Flutter** usando web3dart
3. **Probar todas las funciones** del contrato (crear, aprobar, activar, pagar)
4. **Deploy en testnet** cuando esté listo para producción

### 🔐 Seguridad

⚠️ **IMPORTANTE:** 
- El private key y mnemonic son para desarrollo local únicamente
- NUNCA uses estos datos en producción o redes principales
- Para producción, genera nuevas claves y usa variables de entorno seguras

---
**Última verificación:** $(Get-Date)  
**Estado:** ✅ COMPLETAMENTE FUNCIONAL
