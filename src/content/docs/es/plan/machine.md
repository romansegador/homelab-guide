---
title: Dimensionar la máquina
description: Cuánta CPU, memoria y disco necesitas, y por qué los datos van en su propio disco.
---

:::note[Traducción asistida por IA]
Esta página es una traducción asistida por IA del original en inglés, que es la referencia. Si
ves un error, abre un issue o un PR.
:::

## Especificación recomendada

| Recurso | Recomendado | Mínimo | Notas |
|---|---|---|---|
| CPU | 6 vCPU | 4 vCPU | Casi siempre en reposo. Picos al descargar imágenes, compilar y hacer copias |
| Memoria | 16 GB | 8 GB | La plataforma ocupa ~1,5–2 GB. Las actualizaciones progresivas ejecutan dos copias de una aplicación durante un momento |
| Disco del sistema | 40 GB | 30 GB | Solo el sistema operativo y los binarios de k3s |
| Disco de datos | 100 GB | 50 GB | Imágenes de contenedores, volúmenes persistentes, logs. **Un disco aparte** |
| Red | IP estática en tu red local | — | Por ejemplo `192.168.10.50` |
| Sistema operativo | Ubuntu Server 24.04 LTS o Debian 13 | — | Sirve cualquier distribución moderna con systemd |

### De dónde salen estas cifras
Se basan en un homelab pequeño real: un proveedor de identidad, un proxy inverso, una base de
datos Postgres, un planificador de tareas y una aplicación web de tres servicios. Todo eso usaba
unos **3 GB de RAM** en contenedores, con la CPU casi en reposo. Con 16 GB queda margen para:
- los componentes de la plataforma (k3s, ArgoCD, cert-manager, External Secrets),
- las actualizaciones progresivas, que arrancan la versión nueva antes de parar la antigua,
- crecer.

Si vas a migrar, mide tus propias cargas (`docker stats`, `free -m`, `df -h`) y ajusta.

## Por qué un disco de datos aparte

Las imágenes de contenedores y los logs crecen hasta que algo los limpia. Si comparten disco con
el sistema operativo, un disco lleno puede tumbar toda la máquina, incluido tu acceso SSH. Un
disco de datos aparte (montado, por ejemplo, en `/var/lib/rancher`) significa que:
- si se llena, las aplicaciones se resienten, pero el sistema operativo sigue sano y accesible;
- puedes ampliarlo, hacerle instantáneas o sustituirlo por separado.

## ¿Máquina física o VM?

Cualquiera de las dos sirve.
- **Una VM en un hipervisor** (Proxmox, por ejemplo) te da instantáneas antes de cambios
  arriesgados, copias de la máquina completa y sitio para ejecutar otras cosas al lado.
- **Un equipo físico** es más sencillo, con una capa menos.

Al resto de la guía le da igual. El capítulo 1 sigue el camino de la VM, con notas para equipo
físico.

## Antes del capítulo 1, decide

- [ ] El nombre de la máquina (por ejemplo `lab-1`).
- [ ] Su IP estática (por ejemplo `192.168.10.50`), reservada en tu router.
- [ ] VM o equipo físico, y adónde irán sus copias de seguridad.
