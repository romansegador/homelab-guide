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

### ¿Qué imagen de Ubuntu, y por qué la 26.04?
La **imagen cloud de Ubuntu Server**: Ubuntu Server ya instalado en un disco, sin escritorio, hecha
para VMs que se configuran con cloud-init. Es lo que arrancan los proveedores cloud. Existen
imágenes *minimal* aún más pequeñas, pero quitan herramientas que querrás cuando algo falle.

**26.04 LTS** porque, para una máquina nueva, la LTS más reciente da el soporte más largo
(actualizaciones de seguridad estándar hasta 2031, frente a 2029 de la 24.04). Esperar a la primera
versión de mantenimiento (26.04.1) deja que se corrijan los primeros errores. k3s incluye la 26.04
entre sus sistemas soportados. Elige la 24.04 si algún software del que dependes aún no soporta la
26.04.

El ejemplo **fija una compilación con fecha** (`release-YYYYMMDD`) con su SHA-256, en lugar del
enlace móvil `current`. Así la imagen solo cambia cuando tú la cambias, y Proxmox verifica la
descarga. Las actualizaciones de seguridad siguen llegando: cloud-init actualiza todos los paquetes
en el primer arranque, y las actualizaciones desatendidas lo siguen haciendo.

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

## Capítulo 2 · El clúster

### ¿Por qué k3s?
Es un Kubernetes completo y certificado en un solo programa. Se instala en un minuto, en reposo usa
bastante menos de 1 GB de RAM e incluye lo que necesita un clúster de una máquina (ingress, un
balanceador, volúmenes). Lo que aprendes sirve para cualquier Kubernetes. Alternativas: **k0s** y
**MicroK8s** (idea parecida), **Talos** (un sistema operativo inmutable que solo es Kubernetes:
muy bueno, pero con más que aprender a la vez) o **kubeadm** completo (más piezas que gestionar tú).

### ¿Por qué instalarlo con un script y un fichero de configuración, y no con cloud-init o con una herramienta como k3sup?
El fichero de configuración es la fuente de verdad y vive en tu repositorio. La instalación es un
paso visible que puedes leer, repetir y depurar. Meter k3s en cloud-init reconstruiría el clúster
automáticamente con la VM, pero un fallo quedaría escondido dentro de un primer arranque, y mezcla
«la máquina» con «el clúster». **k3sup** es un instalador práctico, pero es una herramienta más y
esconde la configuración. Cualquiera de las dos es buena opción más adelante, cuando ya sepas qué
hacen los pasos.

### ¿Por qué etcd integrado y no SQLite, que es lo predeterminado?
Para una máquina SQLite es más ligero, pero etcd aporta dos cosas que la guía quiere:
- **instantáneas integradas**, programadas y con subida opcional a un bucket. Con SQLite
  tendrías que montarlo tú;
- **margen para crecer**: más nodos *servidor* pueden unirse después a un clúster etcd. Con SQLite,
  las máquinas extra solo pueden unirse como trabajadoras.

El coste es algo más de RAM (unos cientos de MB) y más escrituras en disco. En un SSD no es
problema.

### ¿Adónde van las instantáneas fuera de la máquina, y por qué no a un bucket?
k3s escribe cada instantánea en el disco de datos. La guía las saca de la máquina con una **copia
de seguridad nocturna de toda la VM** hecha por Proxmox, en un almacenamiento de copias que ya
tienes, como un NAS. Así una sola tarea lo cubre todo: el sistema, los volúmenes de las aplicaciones
en `/data` y las instantáneas, sin cuentas ni claves nuevas. La copia de la VM también copia los
ficheros de etcd en uso, pero solo quedan como tras un corte de luz. Los ficheros de instantánea que
van dentro son copias limpias de un momento concreto, y son los que restauras.

| Opción | Veredicto |
|---|---|
| **Copia nocturna de la VM a un NAS** ✅ | Usa el almacenamiento que ya tienes y cubre toda la máquina. Como mucho se pierde un día de cambios, y la copia se queda en casa hasta que la envíes fuera. |
| **k3s sube a un bucket S3** (R2, AWS S3…) | Fuera de casa cada 6 horas, sin depender de Proxmox. Una cuenta y unas claves más. El capítulo lo muestra como paso opcional. |
| **Un servicio S3 en el NAS** (MinIO, Garage) | Instantáneas fuera de la máquina cada 6 horas, pero un servicio más que mantener. |

k3s solo sube a almacenamiento **compatible con S3**. Un servicio de copias que habla SFTP o rsync
(por ejemplo un Hetzner Storage Box) no puede recibir las instantáneas directamente. Es un buen
sitio para una copia fuera de casa de tu almacenamiento de copias, y el capítulo de operación diaria
lo trata.

Si usas un bucket, sus claves van en un **Secret de Kubernetes**, no en `config.yaml`, para que el
fichero de configuración no contenga credenciales y pueda vivir en git. Para **restaurar** en una
máquina nueva todavía no hay clúster que guarde el Secret, así que pasas los datos del bucket por
la línea de comandos.

### ¿Por qué mantener Traefik, ServiceLB y local-path?
Ya están ahí, funcionan y encajan con una sola máquina. Traefik es además lo que muchos montajes
con Docker ya usan como ingress. Sustituirlos es fácil más adelante (k3s puede desactivar cada uno),
y cada sustituto sería una cosa más que aprender antes de que funcione tu primera aplicación. Los
volúmenes local-path son carpetas normales en una sola máquina. Aquí no es problema, porque todo el
clúster es una máquina. Una segunda máquina traería la elección de un almacenamiento replicado, y
eso está en la hoja de ruta.

### ¿Por qué fijar la versión de k3s?
Para que instalar de nuevo (en una máquina reconstruida) dé el mismo clúster que antes. Las
actualizaciones ocurren cuando tú decides, de una versión menor en una, después de una instantánea.
Se trata en el capítulo de operación diaria.

