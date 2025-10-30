# Sistema de Alquiler de Inmuebles con Blockchain

Aplicación móvil para gestión de alquileres que utiliza blockchain de Ethereum para garantizar transparencia en contratos y pagos. Conecta propietarios y clientes en un ecosistema descentralizado con notificaciones en tiempo real.

## Sobre el Proyecto

Este proyecto nació como parte de la materia Software II. La idea principal es registrar cada contrato de alquiler y pago en la blockchain de Ethereum, haciéndolos inmutables y verificables. Los usuarios pueden buscar propiedades, solicitar alquileres y gestionar todo desde una app móvil, mientras el backend se encarga de la lógica de negocio y la comunicación en tiempo real.

## Arquitectura

El proyecto está dividido en frontend y backend, ambos implementando una arquitectura en capas:

**Frontend (Flutter) - Repositorio: [contract_smart](https://github.com/rosariozambrana/contract_smart)**
- Capa de Datos: servicios de API, blockchain y almacenamiento local
- Capa de Negocio: lógica de negocio y modelos de dominio
- Capa de Presentación: UI, manejo de estado con Provider

**Backend (Laravel 12) - Repositorio: [backend_smartcontract](https://github.com/rosariozambrana/backend_smartcontract)**
- Controladores REST para gestionar recursos
- Eventos de broadcast con Laravel Reverb para WebSockets
- Integración con blockchain usando web3.php

## Stack Tecnológico

**Frontend**
- Flutter 3.7+ para desarrollo móvil multiplataforma
- Provider para manejo de estado
- web3dart para interactuar con Ethereum
- web_socket_channel para comunicación en tiempo real con Reverb
- Google Maps para geolocalización de propiedades

**Backend**
- Laravel 12 como framework principal
- Laravel Reverb para WebSockets nativos (reemplazó Socket.io)
- PostgreSQL como base de datos
- web3.php para integración con blockchain

**Blockchain**
- Ethereum como red blockchain
- Smart Contracts escritos en Solidity
- Ganache para pruebas locales

## Smart Contract

El contrato `RentalContract` maneja la lógica principal en blockchain:

- `createContract()`: registra un nuevo contrato de alquiler
- `approveContract()`: aprueba el contrato entre ambas partes
- `makePayment()`: registra pagos en la blockchain
- `getContractDetails()`: consulta información del contrato

Cada contrato almacena direcciones de propietario e inquilino, montos, fechas y estado actual. Los pagos quedan registrados de forma inmutable.

## Comunicación en Tiempo Real

Usamos Laravel Reverb para WebSockets nativos. Los eventos principales son:

- `request-status-changed`: notifica cambios en solicitudes de alquiler
- `contract-generated`: avisa cuando se crea un contrato nuevo
- `payment-received`: confirma pagos recibidos
- `device-status-changed`: actualiza estado de dispositivos IoT

Los canales incluyen uno global (`rentals`) y canales privados por usuario (`user.{userId}`).

## Instalación

**Requisitos previos:**
- Flutter SDK 3.7+
- PHP 8.2+
- Composer
- PostgreSQL
- Node.js
- Ganache o conexión a red Ethereum

**Frontend:**

```bash
cd rentals
flutter pub get
cp .env.example .env
# Configurar variables en .env (API_URL, REVERB_HOST, BLOCKCHAIN_RPC_URL, etc.)
flutter run
```

**Backend:**

```bash
cd rentalsApi
composer install
npm install
cp .env.example .env
php artisan key:generate
# Configurar base de datos y Reverb en .env
php artisan migrate
php artisan serve --host=0.0.0.0 --port=8000

# En terminales separadas:
php artisan reverb:start
php artisan queue:work
```

## Funcionalidades Principales

**Propietarios:**
- Publicar propiedades con ubicación en mapa
- Gestionar solicitudes de alquiler
- Crear contratos registrados en blockchain
- Recibir notificaciones de pagos en tiempo real

**Clientes:**
- Buscar propiedades disponibles
- Enviar solicitudes de alquiler
- Firmar contratos digitales
- Realizar pagos que se registran en blockchain

## Configuración de Variables de Entorno

**Frontend (.env):**
```
API_URL=http://tu-backend:8000
REVERB_HOST=tu-backend
REVERB_PORT=8080
REVERB_APP_KEY=tu-clave
BLOCKCHAIN_RPC_URL=http://localhost:7545
CONTRACT_ADDRESS=0x...
PRIVATE_KEY=tu-clave-privada
```

**Backend (.env):**
```
DB_CONNECTION=pgsql
DB_DATABASE=rentals
REVERB_APP_ID=tu-id
REVERB_APP_KEY=tu-clave
REVERB_APP_SECRET=tu-secreto
BROADCAST_DRIVER=reverb
QUEUE_CONNECTION=database
```

## Licencia

MIT
