---
title: Hoja de ruta
description: Los capítulos de la guía y su estado.
---

:::note[Traducción asistida por IA]
Esta página es una traducción asistida por IA del original en inglés, que es la referencia. Si
ves un error, abre un issue o un PR.
:::

Cada capítulo es un hito que primero se construye de verdad y después se documenta. El estado se
actualiza a medida que avanza la construcción.

| # | Capítulo | Qué obtienes | Estado |
|---|---|---|---|
| 0 | **Plan** | Decisiones de arquitectura, dimensionado de la máquina, plan de DNS y certificados | ✅ Escrito |
| 1 | **La máquina** | Una VM (o equipo físico) con un disco para el sistema y otro aparte para datos, con SSH endurecido | ✅ Probado (camino OpenTofu) |
| 2 | **El clúster** | Un clúster k3s de un solo nodo, con `kubectl` y `k9s` en tu portátil | ✅ Probado |
| 3 | **GitOps** | Un repositorio de configuración y ArgoCD, arrancado con el patrón «app of apps» | ✅ Probado |
| 4 | **Secretos** | Un gestor de secretos externo sincronizado con el clúster (Bitwarden Secrets Manager + External Secrets Operator) | Previsto |
| 5 | **HTTPS y DNS privado** | cert-manager con DNS-01, un certificado comodín, ingress y registros DNS internos | Previsto |
| 6 | **Tu primera aplicación** | Esta misma guía: compilada por CI, publicada como imagen, desplegada por ArgoCD y servida por HTTPS | Previsto |
| 7 | **Una base de datos** | Postgres gestionado por un operador, con copias de seguridad fuera de la máquina | Previsto |
| 8 | **Una aplicación real** | Una aplicación de varios servicios (web, API, proceso en segundo plano, base de datos) con actualización automática de imágenes | Previsto |
| 9 | **Publicar** | Exponer una aplicación a internet a través de un túnel, con una política de acceso delante | Previsto |
| 10 | **Operación diaria** | Actualizaciones, copias y restauraciones, monitorización básica y reconstrucción completa desde cero | Previsto |

## Extras en estudio

- **Tu propio dominio desde cero:** comprar un dominio, llevar su DNS a un proveedor con API y
  conectarlo con el capítulo 5.
- **Caminos alternativos:** por ejemplo, los mismos capítulos con Docker Swarm.
- **Un gestor de secretos autoalojado** (por ejemplo OpenBao) como alternativa al servicio
  alojado del capítulo 4.
- **Una segunda máquina:** añadir un nodo trabajador y decidir qué puede moverse y qué se queda fijo.
