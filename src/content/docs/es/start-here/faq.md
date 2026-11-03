---
title: Preguntas frecuentes
description: Por qué la guía eligió cada herramienta y enfoque, qué alternativas se valoraron y cuándo podrías elegir otra cosa.
---

:::note[Traducción asistida por IA]
Esta página es una traducción asistida por IA del original en inglés, que es la referencia. Si
ves un error, abre un issue o un PR.
:::

Cada capítulo toma decisiones: una herramienta en lugar de otra, o una forma de hacer algo. Esta
página guarda el razonamiento, las alternativas que se valoraron y cuándo podrías elegir otra
cosa. Las grandes decisiones de arquitectura están en
[Decisiones de arquitectura](/es/plan/architecture/).

## General

### ¿Por qué una máquina en lugar de varias VMs?
Varias VMs en una misma máquina física parecen un clúster, pero fallan juntas. Consulta la
[decisión 1](/es/plan/architecture/#1-una-máquina-no-un-clúster-simulado).

### ¿Puedo seguir la guía con Terraform, Ansible o Docker Swarm?
Los capítulos describen *qué* construyes. Los pasos específicos de cada herramienta van en
pestañas etiquetadas. Cuando una alternativa habitual funciona con los mismos ficheros, el capítulo
lo dice. Terraform es un ejemplo. Otros caminos (por ejemplo, Docker Swarm) aparecen como extras en
la [hoja de ruta](/es/start-here/roadmap/).

## Capítulo 1 · La máquina

### ¿Por qué OpenTofu y no Terraform?
Son casi la misma herramienta. En agosto de 2023, HashiCorp cambió la licencia de Terraform de una
de código abierto (MPL) a una de «código disponible» (la Business Source License). La comunidad
bifurcó la última versión abierta como **OpenTofu**, que ahora acoge la Linux Foundation. Después,
IBM compró HashiCorp.

- **En un homelab, las dos son gratuitas.** La BSL restringe a empresas que crean productos de la
  competencia, no a ti.
- **Los ejemplos de la guía funcionan con las dos.** El mismo lenguaje y los mismos proveedores.
  Cambia `tofu` por `terraform`.
- **Por qué la guía elige OpenTofu:**
  - **Código abierto.** Una guía de código abierto no debería depender de una licencia que su
    dueño puede volver a cambiar.
  - **Cifrado del estado.** OpenTofu puede cifrar él mismo su fichero de estado, y Terraform no
    (ver más abajo). El estado describe tu infraestructura, y en esta guía se guarda fuera de tu
    red.
- **Cuándo elegir Terraform:** tu equipo o tu empresa ya lo usan, o quieres su servicio alojado
  (HCP Terraform). Hay más tutoriales y respuestas en internet para Terraform, y la mayoría sirven
  tal cual para OpenTofu.

### ¿Por qué OpenTofu necesita SSH a Proxmox si usa la API?
OpenTofu se ejecuta en tu portátil y hace casi todo a través de la API de Proxmox por HTTPS: crear
la VM, sus discos, la descarga de la imagen. La única excepción es el **fichero de cloud-init**.
Proxmox guarda los ficheros de cloud-init propios como «snippets», y su API no permite subir
snippets. Así que el proveedor copia ese único fichero por SSH.

### ¿Por qué un usuario SSH restringido y no root?
Con SSH como root al hipervisor, una clave robada de tu portátil o un trabajo de CI comprometido
controlan todas las VMs del host. El usuario `tofu` de la guía puede ejecutar como root exactamente
dos comandos: una comprobación de versión (`pvesm apiinfo`) y `tee` en la carpeta de snippets, con
un patrón estricto de nombre de fichero. Es un paso más de preparación y elimina por completo el SSH
como root.

Alternativas valoradas:

| Opción | Por qué no (aquí) |
|---|---|
| **SSH como root** | Lo más sencillo, pero da a OpenTofu, y a todo lo que lo ejecute, control total del host. |
| **Sin snippet, solo API.** Usa los campos de cloud-init integrados en Proxmox: usuario, clave, IP, DNS. | Esos campos no pueden instalar paquetes, endurecer SSH ni formatear el disco de datos. Ese trabajo pasaría a un segundo paso y a una segunda herramienta. |
| **Copiar el snippet a mano una vez** | Sin SSH desde OpenTofu, pero con un paso manual cada vez que cambia el fichero, así que el repositorio deja de contar toda la historia. |

### ¿Puedo ejecutar OpenTofu desde CI en vez de desde mi portátil?
Sí. Nada de la preparación depende de tu portátil: el estado es remoto y los secretos son variables
de entorno. Antes hay que resolver dos cosas:
- **La red.** Un runner alojado en la nube (por ejemplo, el de GitHub) no llega a un host de Proxmox
  en tu red de casa. Necesitarías un runner autoalojado en casa, o una VPN.
- **Los secretos.** Los cuatro valores (token de API, claves del bucket, frase de paso) pasan a ser
  secretos de CI.

Para una sola máquina que se crea una vez y casi no cambia, la guía ejecuta OpenTofu desde el
portátil. La automatización continua ocurre dentro del clúster con GitOps, a partir del capítulo 3.

### ¿Dónde está el estado de OpenTofu, y por qué remoto y cifrado?
El **estado** es el registro de OpenTofu de lo que ha creado: «esta VM, con este id, es mía». Si se
pierde, OpenTofu cree que no existe nada. El siguiente `apply` intenta crear una segunda VM, y
recuperarse supone volver a importarlo todo a mano. Así que el estado debe sobrevivir a tu portátil.

| Opción | Veredicto |
|---|---|
| **Fichero local en el portátil** | Se pierde con el portátil, y nadie más, ni siquiera CI, puede usarlo. |
| **En el repositorio git privado (cifrado)** | Sin servicios extra, y tienes historial. Pero no hay bloqueo, y tienes que acordarte de hacer commit tras cada `apply`. Viable para una sola persona. |
| **Un bucket en el homelab** (MinIO, Garage) | El huevo y la gallina: el estado de la máquina viviría en esa misma máquina. |
| **Cloudflare R2 (o cualquier almacenamiento compatible con S3), cifrado** ✅ | Fuera de casa, gratis a este tamaño, y con bloqueo, así que dos ejecuciones no pueden pisarse. |

**OpenTofu lo cifra antes de subirlo** (AES-GCM, con una clave derivada de tu frase de paso). El
proveedor de almacenamiento solo guarda texto cifrado, y una clave del bucket filtrada no revela
nada. El coste es un secreto más que guardar: la frase de paso.

La guía usa R2 porque una cuenta de Cloudflare ya forma parte del plan (el DNS del capítulo 5, el
túnel del capítulo 9). Cualquier bucket compatible con S3 funciona igual.

### ¿Por qué cloud-init y no Ansible para preparar el sistema?
La máquina se configura **una vez, en el primer arranque**, a partir de un único fichero que vive
junto a la definición de la VM. Así el capítulo 1 se queda en una herramienta y un comando. Todo lo
que corre en la máquina después lo gestionan el clúster y GitOps. Ansible brilla cuando configuras
muchas máquinas una y otra vez a lo largo de su vida. Con una sola máquina, que prefieres reconstruir
antes que parchear a mano, sería una segunda herramienta para poca ganancia.
