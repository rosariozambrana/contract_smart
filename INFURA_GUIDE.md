# 🔑 Configuración de Infura - Guía Completa

## ❓ **¿Dónde están mis credenciales de Infura?**

### 🎯 **Infura NO usa usuario/contraseña tradicional**

Infura utiliza **API Keys** en lugar de credenciales tradicionales.

### 📋 **Tu configuración actual:**

```bash
# En tu archivo .env
INFURA_API_KEY=3e0e10f3f4b94720b96f61e2ab6d16de
MNEMONIC="window health permit venture valid edge bridge example correct kite panda vacuum"
```

### 🌐 **URLs que se generan:**

- **Sepolia Testnet:** `https://sepolia.infura.io/v3/3e0e10f3f4b94720b96f61e2ab6d16de`
- **Mainnet:** `https://mainnet.infura.io/v3/3e0e10f3f4b94720b96f61e2ab6d16de`

---

## 🔍 **¿Cómo encontrar/verificar tu cuenta Infura?**

### **Opción 1: Ya tienes cuenta**
1. Ve a: **https://infura.io/dashboard**
2. **Inicia sesión** con tu email/contraseña
3. Busca un proyecto que tenga el API Key: `3e0e10f3f4b94720b96f61e2ab6d16de`
4. Verifica que **Ethereum esté habilitado**

### **Opción 2: Crear nueva cuenta (si no recuerdas)**
1. Ve a: **https://infura.io/**
2. Haz clic en **"Get started for free"**
3. Crea una cuenta nueva
4. Crea un nuevo proyecto
5. **Copia el nuevo API Key** y actualiza tu `.env`

---

## 🧪 **¿Cómo probar que funciona?**

### **Método 1: Deploy de prueba**
```bash
# Simular deploy en Sepolia (no gasta ETH)
npx truffle migrate --network sepolia --dry-run
```

### **Método 2: Desde navegador**
Ve a: `https://sepolia.infura.io/v3/3e0e10f3f4b94720b96f61e2ab6d16de`

**Deberías ver:**
```json
{"jsonrpc":"2.0","id":1,"error":{"code":-32700,"message":"Parse error"}}
```
*(Esto es normal, significa que la conexión funciona)*

---

## 💰 **Obtener ETH de testnet para Sepolia**

Para hacer deploy en Sepolia necesitas ETH de testnet:

### **Faucets recomendados:**
- **Sepolia Faucet:** https://sepoliafaucet.com/
- **Chainlink Faucet:** https://faucets.chain.link/
- **Alchemy Faucet:** https://sepoliafaucet.com/

### **Tu dirección para recibir ETH:**
```
0x6DB272507Df7E9dA070F7B71d66ac7a121b88587
```

---

## 🚀 **Comandos listos para usar**

### **Deploy local (ya funciona):**
```bash
npx truffle migrate --network development
```

### **Deploy Sepolia (cuando tengas ETH de testnet):**
```bash
npx truffle migrate --network sepolia
```

### **Verificar redes:**
```bash
npx truffle networks
```

---

## ⚠️ **Posibles problemas y soluciones**

### **Error: "invalid project id"**
- Tu API Key no es válido
- Crea un nuevo proyecto en Infura
- Actualiza el `INFURA_API_KEY` en tu `.env`

### **Error: "insufficient funds"**
- No tienes ETH de testnet en Sepolia
- Ve a un faucet y envía ETH a tu dirección

### **Error: "network error"**
- Problema de conexión a internet
- Verifica que Infura esté funcionando: https://status.infura.io/

---

## 📱 **Para usar en Flutter**

Una vez que tengas el contrato desplegado en Sepolia, actualiza tu `.env`:

```dart
// Configuración para Sepolia
const String rpcUrl = "https://sepolia.infura.io/v3/3e0e10f3f4b94720b96f61e2ab6d16de";
const int chainId = 11155111;
const String contractAddress = "0x..."; // Se obtiene después del deploy
```

---

**✅ ESTADO ACTUAL:** Tu configuración local está perfecta. Solo necesitas ETH de testnet para hacer deploy en Sepolia.
