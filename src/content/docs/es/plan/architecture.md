---
title: Decisiones de arquitectura
description: Las grandes decisiones detrás de la plataforma y su razonamiento, para que puedas cambiarlas con conocimiento de causa.
---

:::note[Traducción asistida por IA]
Esta página es una traducción asistida por IA del original en inglés, que es la referencia. Si
ves un error, abre un issue o un PR.
:::

:::tip[Hazlo con un agente de IA]
Este capítulo tiene una skill para agentes, `plan`, que te ayuda a tomar y anotar estas
decisiones. Consulta [Usar con un agente de IA](/es/start-here/agents/).
:::

Antes de instalar nada, decide qué vas a construir. Estas son las decisiones que toma esta guía
y sus motivos. Si tu situación es distinta, el razonamiento te dice cuáles revisar.

## La forma

```
                 ┌──────────────────────────── one machine ─────────────────────────────┐
  laptop ──git──▶│  ArgoCD ──syncs──▶ apps (web, API, worker)   Postgres (operator)     │
                 │                     ▲                         │                      │
  secrets        │  External Secrets ──┘                         └─ backups ──▶ off-site │
  manager ──────▶│  cert-manager ──DNS-01──▶ DNS provider API                           │
  (hosted)       │  Ingress (HTTPS) ◀── LAN clients ◀── internal DNS                    │
                 └──────────────────────────────────────────────────────────────────────┘
                              ▲ tunnel (outbound only) for the one public app
```

## Decisiones

### 1. Una máquina, no un clúster simulado
Ejecutar tres VMs en una misma máquina física *parece* un clúster, pero no lo es. Si la máquina
o su disco fallan, todo cae a la vez. El almacenamiento replicado entre VMs que comparten disco
añade piezas (orden de arranque, quórum, procedimientos de recuperación) sin añadir seguridad.

**Así que:** una máquina, bien dimensionada, con copias de seguridad reales fuera de ella.
Cuando llegue una segunda máquina física, se une como nodo trabajador (ver los extras de la hoja
de ruta).

### 2. Kubernetes (k3s) como primer camino
k3s es una distribución certificada de Kubernetes en un único binario. Trae valores por defecto
razonables (un controlador de ingress, almacenamiento local) y funciona con soltura en hardware
modesto.

**Por qué Kubernetes en una sola máquina:** el ecosistema. GitOps (ArgoCD), la automatización de
certificados (cert-manager), la sincronización de secretos (External Secrets) y los operadores de
bases de datos son nativos de Kubernetes. Además aprendes algo que te sirve en otros sitios.

**El coste real:** más conceptos y más YAML que con Docker a secas. La guía los presenta de uno en
uno.

### 3. GitOps: el repositorio es la fuente de verdad
No se cambia nada a mano en el servidor. Haces commit y ArgoCD lo aplica. Eso te da:
- el historial completo de cada cambio, y un botón para deshacerlo,
- nada de desviaciones: lo que se ejecuta es lo que está en git,
- una reconstrucción que consiste, sobre todo, en volver a apuntar ArgoCD al repositorio.

Usa **dos repositorios**: los manifiestos de ejemplo de esta guía son públicos, pero *tu*
repositorio de configuración debe ser **privado**, porque contiene tus nombres de host y tu
estructura.

### 4. Los secretos viven en un gestor de secretos, fuera de la máquina
En este camino, los secretos no van en git, ni siquiera cifrados. Viven en un gestor de secretos
alojado (Bitwarden Secrets Manager tiene un plan gratuito). External Secrets Operator los
sincroniza con el clúster como Secrets normales de Kubernetes.
- Si pierdes la máquina, conservas los secretos.
- Si el gestor no está disponible un rato, las aplicaciones siguen funcionando con la última
  copia sincronizada.
- Se crea a mano **un único** secreto: el token con el que el operador lee los demás.

Un gestor autoalojado (OpenBao, Vault) es una buena alternativa, pero crea un problema del huevo
y la gallina si se ejecuta en la misma máquina que protege. Se trata como un extra.

### 5. HTTPS en todas partes, con validación por DNS
Los servicios internos obtienen certificados reales y de confianza de Let's Encrypt. La
validación usa un registro DNS (DNS-01) creado mediante la API de tu proveedor de DNS, así que
nada tiene que ser accesible desde internet. Un único certificado **comodín** cubre todos los
nombres internos. Además son menos certificados que gestionar, y los nombres de tus servicios no
aparecen en los registros públicos de transparencia de certificados.

### 6. Privado por defecto, público por excepción
Todo es accesible solo desde tu red local (o tu VPN). La única aplicación que decidas publicar
sale por un **túnel saliente** con una política de acceso delante. No se abre ningún puerto en
el router.

### 7. Copias de seguridad que salen de casa
Dos capas:
- instantáneas de la máquina (la copia de seguridad de tu hipervisor, si tienes uno), para volver
  atrás rápido en local;
- copias de seguridad de las aplicaciones (volcados de la base de datos, copias de volúmenes)
  enviadas **fuera**, para recuperarte de un desastre.

Una copia de seguridad solo cuenta cuando has restaurado desde ella. El capítulo 10 hace
justamente eso.

## Lo que esta guía no pretende

- **Alta disponibilidad.** Una máquina es un único punto de fallo. El objetivo es una
  recuperación rápida y ensayada.
- **Endurecimiento multiusuario o empresarial.** Valores razonables para un homelab, no un
  régimen de cumplimiento normativo.
