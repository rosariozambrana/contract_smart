%% Código para Mermaid Live Editor o herramientas compatibles
deploymentDiagram
actor Cliente
actor Propietario

    node "Dispositivo Cliente" as cliente {
        [Frontend App] as front
    }

    node "Servidor Cloud" as server {
        [Backend Node.js] as backend
        [API REST] as api
    }

    node "Base de Datos" as db {
        [MySQL] as mysql
    }

    node "Casa Inteligente" as iot {
        [Cerradura IoT] as lock
        [Interruptor IoT] as light
    }

    Cliente --> front : Interfaz
    Propietario --> front : Interfaz
    front --> api : HTTP/HTTPS
    api --> backend : Procesamiento
    backend --> mysql : Almacenamiento
    backend --> iot : Control remoto (MQTT/HTTP)
    iot --> lock : Bloqueo/Desbloqueo
    iot --> light : Encender/Apagar