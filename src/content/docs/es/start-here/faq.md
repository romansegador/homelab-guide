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
Es un Kubernetes completo y certificado en un solo programa. Se instala en un minuto, un clúster nuevo
en reposo usa alrededor de 1 GB de RAM (1,2 GB toda la máquina, sistema incluido) e incluye lo que necesita un clúster de una máquina (ingress, un
balanceador, volúmenes). Lo que aprendes sirve para cualquier Kubernetes. Alternativas: **k0s** y
**MicroK8s** (idea parecida), **Talos** (un sistema operativo inmutable que solo es Kubernetes:
muy bueno, pero con más que aprender a la vez) o **kubeadm** completo (más piezas que gestionar tú).

### ¿Por qué instalarlo con un script y un fichero de configuración, y no con cloud-init o con una herramienta como k3sup?
El fichero de configuración es la fuente de verdad y vive en tu repositorio. La instalación es un
script corto, ejecutado desde tu portátil por SSH, que puedes leer, repetir y depurar. Envuelve el
script oficial de instalación de k3s y hace, en pasos que se ven, lo mismo que k3sup. Meter k3s en cloud-init reconstruiría el clúster
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

### ¿Por qué el script de instalación cambia un ajuste de AppArmor?
Ubuntu 26.04 activa `kernel.apparmor_restrict_unprivileged_unconfined` por defecto. Con él
activado, cada contenedor se ejecuta con una etiqueta de AppArmor «apilada»
(`cri-containerd.apparmor.d//&unconfined`) que el perfil del propio runtime de contenedores no
espera. El resultado: **los procesos de un mismo contenedor no pueden enviarse señales.** La
mayoría de aplicaciones no lo notan. Postgres sí: sus procesos se despiertan unos a otros con
señales, así que la primera conexión espera para siempre y la base de datos nunca termina de
arrancar (capítulo 7). El registro del kernel lo muestra como `apparmor="DENIED" operation="signal"`.

El script desactiva solo ese ajuste en `/etc/sysctl.d/20-apparmor.conf`, el fichero de sobrescritura
que indica la propia configuración de Ubuntu. Los contenedores siguen con su perfil de AppArmor,
solo que sin la etiqueta apilada. La solución corresponde al runtime de contenedores
([containerd#14485](https://github.com/containerd/containerd/issues/14485)). Cuando una versión de
k3s la incluya, el ajuste puede volver a activarse. Si instalaste k3s antes de que el script lo
hiciera, añade el fichero y reinicia la máquina, porque los contenedores en marcha conservan su
etiqueta antigua.


## Capítulo 3 · GitOps

### ¿Por qué ArgoCD y no Flux?
Los dos son herramientas GitOps maduras, de código abierto y de la CNCF, y cualquiera serviría. La
guía elige **ArgoCD** por su **interfaz web**: ves cada app, su estado de sincronización y la
diferencia entre git y el clúster, y eso ayuda mucho mientras aprendes. **Flux** no trae interfaz y
se maneja con su CLI y con objetos de Kubernetes. Es más ligero, y una gran elección si prefieres
trabajar en la terminal.

### ¿Qué versión de ArgoCD, y por qué?
La más reciente **probada con tu versión de Kubernetes**. ArgoCD publica con qué versiones se prueba
cada release, y al escribir esto solo la 3.6 incluye Kubernetes 1.37, la versión que instala k3s en
el capítulo 2. La guía fija su primera versión de parches (3.6.1), a través de la versión del chart
de Helm que la trae. Revisa la tabla de la documentación de ArgoCD («Tested Kubernetes versions»)
cuando actualices cualquiera de los dos.

### ¿Por qué instalarlo con Helm y después dejar que ArgoCD se gestione a sí mismo?
Algo tiene que instalar ArgoCD antes de que ArgoCD pueda instalar nada, así que la primera
instalación es a mano. Helm la reduce a un comando, con tus ajustes en un fichero de valores en
git. Después `apps/argocd.yaml` le da a ArgoCD el mismo chart, versión y valores, y ArgoCD se hace
cargo.

| Opción | Por qué no (aquí) |
|---|---|
| **Helm, y actualizaciones a mano** | Funciona, pero ArgoCD queda fuera de GitOps: su versión y sus ajustes viven en el historial de tu terminal, no en un commit. |
| **El manifiesto de instalación** (`kubectl apply -f install.yaml`) | Sin Helm, pero cada ajuste se convierte en un parche sobre un YAML grande, y eso es más difícil que un fichero de valores. |

La pega: cuando ArgoCD se gestiona a sí mismo, un cambio malo en sus propios ajustes puede romper
la herramienta con la que lo arreglarías. Si pasa, `helm upgrade` con el último fichero de valores
bueno lo recupera.

### ¿Por qué una deploy key para leer el repositorio?
Una **deploy key** es una clave SSH que llega a **un solo repositorio** y, salvo que lo permitas,
**solo puede leer**. Es justo lo que necesita ArgoCD. Una clave filtrada expone tu configuración,
y nada más de tu cuenta de GitHub.

| Opción | Por qué no (aquí) |
|---|---|
| **Una GitHub App** | Tokens de corta duración y permisos finos, y una app puede cubrir muchos repositorios. Merece la pena con varios repositorios, pero es más preparación para uno. |
| **Un token personal de acceso con permisos finos** | Va ligado a tu cuenta de usuario y caduca, así que hay que renovarlo a mano. |
| **Un repositorio público** | Sin credenciales, pero tu configuración nombra tus máquinas y tu estructura. |

La clave privada no se guarda en ningún sitio aparte del clúster. Si la pierdes, creas otra: una
deploy key es fácil de sustituir.

### ¿Por qué «app of apps» y no un ApplicationSet?
Un **ApplicationSet** genera Applications a partir de un patrón, por ejemplo una por cada carpeta de
`apps/`. Es menos YAML cuando tienes muchas apps parecidas, pero es un concepto más, y los ajustes
por app se complican. Con **app of apps**, cada app es un fichero de Application sencillo y legible.
Es fácil ver por qué algo está funcionando: hay un fichero para ello. Puedes pasar a ApplicationSets
más adelante sin cambiar las apps.

### ¿Por qué port-forward para llegar a la interfaz?
Porque así no se expone nada en la red y no hay nada que deshacer después. Abrir la interfaz en tu
red local ahora supondría HTTP sin cifrar, así que tu contraseña de admin cruzaría la red en claro.
El capítulo 5 le da a ArgoCD una dirección `https://` con un certificado de verdad.

## Capítulo 4 · Secretos

### ¿Por qué un gestor de secretos, y no secretos cifrados en git (SOPS, Sealed Secrets)?
Los secretos cifrados en git funcionan bien y no necesitan ningún servicio externo. Pero los
ficheros cifrados se quedan en tu historial para siempre, así que una clave que se filtre más tarde
también abre todas las versiones antiguas. Cambiar un secreto supone volver a cifrar y hacer commit.
Un gestor de secretos mantiene los valores totalmente fuera de git, te deja cambiar un secreto sin
commit y es donde buscarías una contraseña de todos modos. Consulta la
[decisión 4](/es/plan/architecture/#4-los-secretos-viven-en-un-gestor-de-secretos-fuera-de-la-máquina).

### ¿Por qué Bitwarden Secrets Manager?
Está alojado (nada más que mantener ni copiar en casa), su plan gratuito cubre un homelab (3
proyectos, 3 cuentas de máquina, secretos ilimitados) y mucha gente ya usa Bitwarden para sus
contraseñas.

Dos advertencias sinceras:
- External Secrets marca su soporte de Bitwarden como **alpha**: funciona, pero tiene menos usuarios
  que los grandes proveedores cloud, y sus ajustes pueden cambiar entre versiones. La guía fija la
  versión y se probó con ella. La misma etiqueta está en Infisical, Doppler, 1Password y OpenBao,
  así que cambiar a otro gestor alojado no la evita.
- Necesita un servicio auxiliar dentro del clúster, el Bitwarden SDK server, con su propio
  certificado.

| Alternativa | Cuándo elegirla |
|---|---|
| **Infisical** o **Doppler** | Gestores alojados parecidos a los que External Secrets llega directamente, sin servicio auxiliar ni certificado. Elige uno si no usas Bitwarden. |
| **1Password** | Si ya pagas por él. |
| **El gestor de un proveedor cloud** (AWS, Google Cloud, Azure) | Si ya tienes cuenta allí. Están entre los proveedores estables de External Secrets, pero se pagan por secreto y por petición. |
| **Autoalojado** (OpenBao, Vault) | Si nada puede salir de tu casa. Es un servicio crítico más que mantener y copiar, y está entre los extras de la hoja de ruta. |

### ¿Por qué instalar cert-manager en este capítulo?
El Bitwarden SDK server solo habla HTTPS, así que necesita un certificado, y crear certificados es
el trabajo de cert-manager. La alternativa, un certificado hecho a mano con `openssl`, es una cosa
más creada fuera de git, y tendrías que acordarte de renovarlo. El capítulo 5 necesitaba
cert-manager de todos modos.

El certificado es **autofirmado y de larga duración** (10 años) a propósito. Solo se usa dentro del
clúster, entre dos componentes, y el store confía exactamente en ese certificado. El SDK server lee
su certificado solo al arrancar, así que un certificado corto renovado no se usaría hasta que el pod
se reiniciara.

### ¿Qué versiones, y por qué?
Las más recientes, comprobadas con la tabla de versiones de Kubernetes soportadas de cada proyecto.
External Secrets 2.14 está probado con Kubernetes 1.37. cert-manager 1.21 llega hasta Kubernetes
1.36: su siguiente versión (1.22) se espera hacia noviembre de 2026, y aún no ha anunciado sus
versiones de Kubernetes. Pasar a ella será un cambio de una línea en `apps/cert-manager.yaml`. cert-manager solo usa APIs estables de Kubernetes, así que una versión un
paso por detrás es un riesgo pequeño.

### ¿Por qué un solo ClusterSecretStore y un solo proyecto?
Un proyecto y una cuenta de máquina suponen un token que crear a mano y un store que puede usar
cualquier namespace. El coste: el ExternalSecret de cualquier aplicación podría pedir cualquier
secreto del proyecto. Con un solo administrador, no es problema. Con varios equipos, o aplicaciones
en las que confías menos, da a cada uno su propio proyecto, cuenta de máquina y SecretStore (por
namespace), para que un token filtrado llegue a menos.

### ¿Por qué referirse a los secretos por nombre y no por id?
Un nombre como `demo-message` se lee bien en git y en las revisiones. Ves qué usa una aplicación sin
abrir Bitwarden. Los nombres deben ser únicos dentro del proyecto, y External Secrets da un error si
dos secretos comparten uno. Un id sobrevive a un cambio de nombre, pero git solo muestra ids opacos.

## Capítulo 5 · HTTPS y DNS privado

### ¿Por qué un certificado comodín, y no uno por aplicación?
Cada certificado que emite Let's Encrypt se publica en los **registros públicos de transparencia de
certificados**, sea cual sea la forma en que demostraste que el dominio es tuyo. Un certificado por
aplicación pondría ahí el nombre de cada una, y cualquiera podría buscarlos (por ejemplo en crt.sh).
Los nombres no dejan entrar a nadie, porque solo se resuelven en tu LAN, pero sí le dicen a un
atacante qué software ejecutas. Un certificado comodín solo muestra `*.lab.home.example.com`.

El argumento habitual a favor de un certificado por aplicación es un radio de daño menor: una clave
filtrada afecta a una sola aplicación. Aquí eso casi desaparece. Un único Traefik gestiona HTTPS para
todas las aplicaciones, así que guarda todas las claves en cualquier caso, y quien lo comprometa se
las lleva todas. Un comodín, además, es una sola renovación que vigilar en vez de muchas.

Un certificado por aplicación tiene sentido cuando distintos equipos o distintos controladores de
ingress gestionan distintas aplicaciones. Entonces cada Ingress puede pedir el suyo a cert-manager.

### ¿El reto DNS no mantiene los nombres en privado?
No. DNS-01 es solo la forma de demostrar que el dominio es tuyo: un registro temporal en el DNS
público, en vez de que Let's Encrypt se conecte a tu servidor. Mantiene tus servicios
**inalcanzables** desde internet. No los mantiene **fuera de las listas**: el certificado en sí
sigue yendo a los registros públicos.

### ¿Por qué cert-manager comprueba el reto en servidores DNS públicos?
Antes de pedir a Let's Encrypt que compruebe, cert-manager consulta él mismo el registro del reto.
Por defecto pregunta al DNS del clúster, que reenvía a tu DNS interno. Tu DNS interno responde él
mismo por `home.example.com`, así que dice que el registro no existe, y cert-manager espera para
siempre. Las dos líneas de `extraArgs` hacen que cert-manager pregunte a servidores públicos (aquí,
`1.1.1.1` de Cloudflare), que ven lo mismo que Let's Encrypt.

Si tu DNS interno no responde por tu dominio (por ejemplo, solo reenvía), no las necesitas, pero no
hacen daño.

### ¿Por qué un token de API nuevo, y no reutilizar uno?
Un token para cada usuario te permite revocar o rotar uno sin romper otro. El token solo puede
editar el DNS de una zona, así que si se filtra no puede tocar el resto de tu cuenta. Aun así puede
cambiar cualquier registro de esa zona, y por eso vive en el gestor de secretos y en ningún otro
sitio.

### ¿Por qué un registro DNS a mano, y no external-dns?
external-dns escribe automáticamente un registro DNS para cada Ingress. Con un registro comodín no
le queda nada que hacer: todo nombre bajo el subdominio ya llega al clúster. Añadiría un componente,
y una clave capaz de escribir en tu DNS interno, para ahorrarte un registro que añades una vez.

external-dns tiene sentido cuando las aplicaciones viven en máquinas distintas, o cuando no puedes
usar un comodín.

### ¿Por qué cambiar el Traefik de k3s, y no instalar otro controlador de ingress?
k3s ya ejecuta Traefik, y te deja cambiar sus ajustes con un fichero `HelmChartConfig`, que k3s
une con su propia instalación. Ese fichero vive en git como todo lo demás. Instalar un segundo
controlador obligaría a desactivar el de k3s, y después a mantener el tuyo al día.

### ¿Por qué un Ingress estándar, y no Gateway API o el IngressRoute de Traefik?
El Ingress estándar es la forma más sencilla de dirigir un nombre a una aplicación, todos los
controladores lo entienden, y la mayoría de ejemplos en internet lo usan. Gateway API es su sucesor,
más nuevo y más capaz, y Traefik lo soporta. Merece la pena cuando necesites lo que añade, como
repartir el tráfico entre versiones. IngressRoute es el formato propio de Traefik: potente, pero
ata cada aplicación a Traefik.

### ¿Por qué empezar con el servicio de pruebas de Let's Encrypt?
El servicio real tiene límites estrictos. Por ejemplo, emite como mucho cinco certificados idénticos
por semana. Un error mientras preparas todo puede gastarlos y bloquearte durante días. El servicio de
pruebas tiene límites generosos, así que corriges los errores ahí y cambias al real una sola vez.

### ¿Por qué los emisores no llevan dirección de correo?
Let's Encrypt usaba la dirección para avisar de certificados a punto de caducar, y dejó de enviar
esos avisos en 2025. cert-manager renueva el certificado solo, y la dirección no hace falta.

### ¿Por qué ArgoCD sirve HTTP sin cifrar ahora?
Traefik gestiona HTTPS para todas las aplicaciones con el mismo certificado, y pasa las peticiones a
la aplicación dentro del clúster. Si ArgoCD mantuviera también su propio HTTPS autofirmado, habría
que decirle a Traefik que confiara en él. La herramienta de línea de comandos `argocd` también
funciona a través de Traefik, con su opción `--grpc-web`.

## Capítulo 6 · Tu primera aplicación

### ¿Por qué GitHub Container Registry?
Está junto al código: GitHub Actions publica en él con el token propio del workflow, así que no hay
contraseña de registro que crear ni guardar. Las imágenes públicas son gratis, y cualquiera puede
descargarlas sin iniciar sesión, también tu clúster.

| Alternativa | Cuándo elegirla |
|---|---|
| **Docker Hub** | Si tus imágenes ya viven ahí. Necesita un token de acceso guardado en GitHub, y limita cuántas veces pueden descargar los usuarios anónimos. |
| **Un registro en tu clúster** (Zot, Harbor) | Si las imágenes no pueden salir de casa. Es un servicio más que mantener, copiar y proteger, y tu clúster pasa a depender de sí mismo para arrancar sus aplicaciones. |
| **El registro de tu proveedor cloud** | Si ya despliegas allí. |

### ¿Por qué publicar con una etiqueta de git, y no en cada merge?
Una etiqueta es una decisión: «esto es una versión». Cada versión recibe un número legible, y su
imagen no cambia nunca. Publicar en cada merge da una imagen por commit, con nombres como
`sha-1a2b3c4` que dicen poco, y muchas imágenes que limpiar. Los pull requests siguen construyendo
la imagen, sin publicarla, así que un `Dockerfile` roto aparece antes del merge.

### ¿Por qué la etiqueta de la imagen pierde la `v`?
`v0.1.0` es la convención de git, y `0.1.0` la de las imágenes. La regla `type=semver` del workflow
convierte una en otra, e ignora las etiquetas que no son versiones.

### ¿Por qué cambiar la versión a mano en el repositorio de configuración?
Así cada despliegue es un commit tuyo: ves qué cambió, cuándo, y lo deshaces con `git revert`.
Automatizarlo supone dar a alguna herramienta acceso de escritura a tu repositorio de configuración,
o ejecutar un componente más en el clúster. El capítulo 8 lo hace, cuando una aplicación real
publique lo bastante a menudo como para necesitarlo.

### ¿Por qué YAML sin más, y no Kustomize o un chart de Helm?
Una aplicación, un entorno: un Deployment, un Service y un Ingress lo dicen todo, y la versión es una
línea. **Helm** es la forma estándar de *empaquetar* software para que otros lo instalen, y por eso
las herramientas de los capítulos 3 a 5 vienen como charts. Para tus *propias* aplicaciones, los
equipos usan tanto Helm como **Kustomize**. Kustomize viene integrado en `kubectl` y ArgoCD, y
encaja con «la misma aplicación con pequeños cambios para dev y prod». Un chart compensa cuando
necesitas lógica de plantillas, o instalas la misma aplicación muchas veces. El capítulo 8 vuelve a
esto con una aplicación de varios servicios.

### ¿Por qué un nginx sin privilegios, con el sistema de ficheros de solo lectura?
Un sitio estático no necesita más. El contenedor funciona como un usuario normal, no puede ganar
privilegios, no puede cambiar sus propios ficheros, y solo escribe en una carpeta temporal. Si
alguien encontrara un fallo en nginx, poco podría hacer con él. Cuesta unas pocas líneas de YAML.

### ¿Por qué construir para amd64 y arm64?
Para que la misma imagen funcione en un mini PC y en una Raspberry Pi. El sitio es HTML, CSS y JS,
igual en todas las plataformas, así que se construye una sola vez, de forma nativa, y solo cambia
la pequeña capa de nginx. Así se evita emular arm64, que haría CI mucho más lento.

### ¿Qué es el registro de construcción (attestation)?
Una declaración firmada, guardada con la imagen, que dice qué repositorio, commit y workflow la
construyeron. `gh attestation verify` la comprueba. Te permite demostrar que una imagen salió de tu
CI y no del portátil de alguien, y cuesta un paso en el workflow.

### ¿Por qué las GitHub Actions se fijan por versión mayor, y no por commit?
`actions/checkout@v7` recibe correcciones automáticamente, y las actions que se usan aquí son de
GitHub y de Docker. Fijar cada action a un commit protege mejor ante una action comprometida, pero
cada actualización pasa a ser un cambio manual. Herramientas como Dependabot o Renovate lo
facilitan, y merece la pena añadirlas cuando tengas varios repositorios.

### ¿Y si mi imagen es privada?
Entonces el clúster necesita credenciales para descargarla: un token del registro, guardado en el
gestor de secretos, copiado al namespace de la aplicación con un ExternalSecret de tipo
`kubernetes.io/dockerconfigjson`, y nombrado en el `imagePullSecrets` del Deployment. El capítulo 8
lo hace para una aplicación privada.

## Capítulo 7 · Una base de datos

### ¿Por qué un operador, y no un contenedor de Postgres sin más?
Un contenedor de Postgres con un volumen funciona bien, hasta que necesitas una copia de seguridad
fiable, una restauración, o una actualización de versión mayor. Entonces escribes scripts para cada
una. Un operador ya sabe hacerlo: hace copias coherentes, archiva el WAL de forma continua, restaura
en un clúster nuevo con un fichero YAML, y hace las actualizaciones en el orden correcto. Un
contenedor sin más con un `pg_dump` nocturno es más sencillo, pero solo te da los datos de anoche,
y la restauración la pruebas a mano.

### ¿Por qué CloudNativePG?
Es el operador de Postgres más usado, un proyecto de la CNCF, y hecho para Kubernetes desde el
principio. Las copias de seguridad, la recuperación a un punto en el tiempo y las restauraciones
forman parte del fichero Cluster.

| Alternativa | Cuándo elegirla |
|---|---|
| **Crunchy PGO** | Si quieres pgBackRest, una herramienta de copias muy madura. Es más pesado, y aun así necesita almacenamiento de objetos para las copias fuera de casa. |
| **Zalando postgres-operator** | Si ya lo conoces. Es más antiguo, y sus copias (WAL-G) necesitan más preparación. |
| **Un contenedor sin más + `pg_dump`** | Para una base de datos de usar y tirar, o si tus copias solo pueden ir a un sitio que no es almacenamiento de objetos (por ejemplo SFTP). |

### ¿Qué versiones, y por qué?
CloudNativePG 1.30, la más reciente. Soporta oficialmente Kubernetes 1.34 a 1.36, y la 1.37, la que
usa esta guía, aparece como «probada, pero no soportada»: el proyecto ejecuta sus pruebas en
ella, pero no promete arreglar los problemas que solo aparezcan ahí. Postgres 18 es la versión más
reciente que soporta.

### ¿Por qué el plugin Barman Cloud, y no las copias integradas del operador?
CloudNativePG hacía antes las copias a almacenamiento de objetos él mismo (`barmanObjectStore` en el
Cluster). Eso está obsoleto en favor del plugin, que saca el código de copias del operador y de la
imagen de Postgres. Las instalaciones nuevas deben usar el plugin. Necesita cert-manager, que ya
tienes.

### ¿Por qué una sola instancia?
En una sola máquina, una segunda instancia estaría en el mismo disco, en la misma caja: si la
máquina falla, fallan las dos. Doblaría la memoria y no protegería nada. Con una segunda máquina,
pon `instances: 2`, y el operador añade una réplica y gestiona el relevo.

### ¿Por qué Cloudflare R2 para las copias?
CloudNativePG hace las copias en almacenamiento de objetos compatible con S3, y R2 es compatible con
S3, está fuera de casa, y tiene un plan gratuito en el que cabe de sobra la base de datos de un
homelab: 10 GB de almacenamiento, un millón de escrituras y diez millones de lecturas al mes, por
cuenta (no por bucket). Una base de datos pequeña con 14 días de copias y WAL usa una fracción de
eso. R2 tampoco cobra las descargas, así que restaurar no cuesta nada.

Si prefieres guardar las copias en casa, ejecuta almacenamiento compatible con S3 en tu NAS (por
ejemplo Garage), y cópialo fuera de casa por separado. Un servicio de almacenamiento que solo habla
SFTP (como una Hetzner Storage Box) no funciona directamente con el plugin.

### ¿Las copias están cifradas?
R2 cifra todo lo que guarda, y la conexión usa HTTPS. El plugin no puede cifrar las copias él
mismo antes de que salgan del clúster. Por eso la clave de acceso solo llega a un bucket, y solo
vive en el gestor de secretos.

### ¿Por qué dejar que el operador cree las contraseñas?
Crea una contraseña fuerte para el usuario de la aplicación, la guarda en un Secret junto a la base
de datos, y la aplicación la lee de ahí. Nadie la teclea, y nunca toca git ni tu portátil. Una
contraseña del gestor de secretos sería un valor más que crear y mantener sincronizado, sin ganar
nada, porque solo la usa la aplicación dentro del clúster. El superusuario de Postgres no tiene
contraseña ni acceso por red: `kubectl exec` es la forma de abrir una consola de administración.

### ¿Por qué restaurar en este capítulo, y no más adelante?
Una copia que nunca has restaurado es una esperanza. Restaurar en un segundo clúster demuestra que
el bucket basta por sí solo, sin tocar el original. Repítelo cada vez que cambies cómo se hacen las
copias.

### ¿Por qué 14 días de retención?
Lo bastante para notar un problema, como una migración mala o filas borradas, y restaurar a antes
de que pasara. Lo bastante poco para que ocupe poco. Cambia `retentionPolicy` si necesitas más.

### ¿Por qué un port-forward para conectar una herramienta de bases de datos, y no abrir la base de datos a la red?
`kubectl port-forward` no abre nada nuevo. La base de datos sigue siendo accesible solo dentro del
clúster, el túnel solo existe mientras el comando está en marcha, y solo quien tiene tu kubeconfig
puede abrirlo. Funciona igual para cada base de datos que añadas después.

Las alternativas son una apertura permanente:
- **Exponer el puerto 5432** a través de Traefik (como ruta TCP) o de un servicio LoadBalancer.
  Entonces cualquier máquina de la red puede intentar iniciar sesión, así que querrías TLS
  comprobado de extremo a extremo y también reglas de red. Merece la pena cuando otras máquinas
  necesitan acceso constante, por ejemplo una herramienta de informes en otro servidor.
- **Una herramienta web de bases de datos en el clúster** (pgAdmin, DbGate). Cómoda desde cualquier
  navegador, pero es una aplicación más en la que iniciar sesión, que proteger y que mantener al
  día, con las contraseñas de todas las bases de datos dentro.

### ¿Por qué la demostración declara su propio namespace?
La opción `CreateNamespace=true` de ArgoCD crea un namespace si falta, pero ArgoCD nunca borra un
namespace creado así. Declarado como fichero en la carpeta de la aplicación, el namespace se
gestiona como todo lo demás, así que quitar la aplicación también lo quita. Las aplicaciones de
charts de Helm (cert-manager, el operador) mantienen la opción: se quedan instaladas.
