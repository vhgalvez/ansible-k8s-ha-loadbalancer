# 🧰 HAProxy + Keepalived Deployment (Ansible)

Este repositorio despliega un balanceador de carga con alta disponibilidad usando **HAProxy** y **Keepalived** para clústeres Kubernetes (K3s o Kubernetes tradicionales). Proporciona balanceo de tráfico en las capas TCP/HTTP y maneja múltiples VIPs para separar tráfico del API y del Ingress.

---

## 🧱 Visión General: ¿Qué estás construyendo?

Estás construyendo un entorno Kubernetes de alta disponibilidad sobre máquinas virtuales KVM en un servidor físico HP ProLiant, utilizando K3s, HAProxy + Keepalived, Traefik como Ingress interno, y almacenamiento distribuido con Longhorn + NFS, todo asegurado mediante VPN WireGuard y nftables.

---

## 🌐 Arquitectura de Red y Accesos Externos

```
[Usuarios Públicos]
       │
       ▼
+-------------------+
| Cloudflare CDN    | ◄── Proxy + HTTPS + WAF
| (example.com)     |
+-------------------+
       │
       ▼
+----------------------------+
| VPS con IP pública         |
| WireGuard Gateway          |
| Túnel: 10.17.0.1           |
+----------------------------+
       │
       ▼
+-----------------------------+
| WireGuard Server LAN       |
| NAT + VPN (192.168.0.19)   |
+-----------------------------+
       │
       ▼
Tráfico Interno Redirigido Según Tipo
```

### 🎯 Separación de Tráfico en Producción

| Tipo de Tráfico       | VIP Asignada | Función                                                |
| --------------------- | ------------ | ------------------------------------------------------ |
| Kubernetes API (6443) | 10.17.5.10   | Requiere estabilidad para kubectl, etcd, control-plane |
| Ingress HTTP/HTTPS    | 10.17.5.30   | Redirige tráfico a servicios internos vía Traefik      |

Estas IPs virtuales (VIP) son gestionadas por HAProxy + Keepalived y conmutan entre nodos automáticamente.

### 🧠 Balanceadores HA

| Nodo          | IP         | Función                |
| ------------- | ---------- | ---------------------- |
| k8s-api-lb    | 10.17.5.20 | Nodo principal de VIPs |
| loadbalancer1 | 10.17.3.12 | Respaldo HAProxy       |
| loadbalancer2 | 10.17.3.13 | Respaldo HAProxy       |

Los tres tienen HAProxy + Keepalived instalados.

Las VIPs 10.17.5.10 (API) y 10.17.5.30 (Ingress) son flotantes. Solo un nodo las mantiene activas al mismo tiempo (por prioridad).

---

## ☸️ Clúster Kubernetes (K3s HA)

| Hostname | IP         | Rol                  |
| -------- | ---------- | -------------------- |
| master1  | 10.17.4.21 | etcd + API           |
| master2  | 10.17.4.22 | etcd                 |
| master3  | 10.17.4.23 | etcd                 |
| worker1  | 10.17.4.24 | Nodo de aplicaciones |
| worker2  | 10.17.4.25 | Nodo de aplicaciones |
| worker3  | 10.17.4.26 | Nodo de aplicaciones |

Todos los nodos usan Flatcar Container Linux. Clúster K3s en modo etcd HA.

Se instala con `--tls-san 10.17.5.10` para que `kubectl` acceda vía la VIP.

---

## 🚪 Ingress Controller (Traefik)

| Tipo    | Despliegue                       |
| ------- | -------------------------------- |
| Traefik | Deployment interno en Kubernetes |

El acceso es a través de la VIP `10.17.5.30` gestionada por HAProxy. Traefik se comunica con los pods vía ClusterIP. No se expone directamente.

---

## 💾 Almacenamiento Persistente

| Nodo     | IP         | Rol            |
| -------- | ---------- | -------------- |
| storage1 | 10.17.4.27 | NFS + Longhorn |

**Longhorn (RWO):**

* Microservicios
* Prometheus
* Grafana
* ELK

**NFS (RWX):**

* PostgreSQL → `/srv/nfs/postgresql`
* Datos compartidos → `/srv/nfs/shared`

---

## 🔐 Seguridad

| Componente    | Detalles                                |
| ------------- | --------------------------------------- |
| WireGuard     | Acceso remoto seguro desde el VPS       |
| nftables      | Firewall estricto en el servidor físico |
| Cloudflare    | HTTPS, WAF, Protección contra DDoS      |
| Autenticación | basicAuth en dashboards internos        |
| DNS/NTP       | infra-cluster (`10.17.3.11`)            |

---

## 🧠 Automatización y CI/CD

| Herramienta      | Función                                |
| ---------------- | -------------------------------------- |
| Terraform        | Provisión de VMs y redes               |
| Ansible          | Instalación y configuración (100% IaC) |
| Jenkins + ArgoCD | CI/CD interno                          |

---

## 🖥 Tabla de Máquinas

| Hostname      | IP         | Función                     |
| ------------- | ---------- | --------------------------- |
| master1       | 10.17.4.21 | K3s Master + etcd           |
| master2       | 10.17.4.22 | K3s Master + etcd           |
| master3       | 10.17.4.23 | K3s Master + etcd           |
| worker1       | 10.17.4.24 | Nodo de aplicaciones        |
| worker2       | 10.17.4.25 | Nodo de aplicaciones        |
| worker3       | 10.17.4.26 | Nodo de aplicaciones        |
| storage1      | 10.17.4.27 | Longhorn + NFS              |
| k8s-api-lb    | 10.17.5.20 | HAProxy + Keepalived (VIPs) |
| loadbalancer1 | 10.17.3.12 | HAProxy (respaldo)          |
| loadbalancer2 | 10.17.3.13 | HAProxy (respaldo)          |
| postgresql1   | 10.17.3.14 | PostgreSQL centralizado     |
| infra-cluster | 10.17.3.11 | CoreDNS + Chrony            |

---

## ✅ Ventajas de esta Arquitectura

* 🔁 Alta disponibilidad real con múltiples VIPs separadas.
* 🚪 Ingress controlado internamente con Traefik.
* 🛡️ Seguridad robusta por VPN, nftables y HTTPS.
* 🧰 Automatización total (Terraform + Ansible).
* 📦 Almacenamiento distribuido y tolerante a fallos.
* 🧱 Modularidad para crecer sin rediseñar.

sudo ansible-playbook -i inventory/hosts.ini ansible/playbooks/install_haproxy_keepalived.yml


sudo ansible-playbook -i inventory/hosts.ini ansible/playbooks/uninstall_haproxy_keepalived.yml


# 🧰 Documentación: Bootstrap de Clúster K3s con HAProxy + Keepalived + VIPs

## 📄 Objetivo

Permitir que el nodo `master1` pueda iniciar el clúster K3s sin depender previamente de que HAProxy o Keepalived estén activos y funcionales. Esto resuelve el clásico problema de dependencia cíclica ("el huevo o la gallina") al usar una VIP (IP virtual) como punto de entrada al clúster.

---

## 🏛️ Arquitectura

* **VIP del API Server**: `10.17.5.10`
* **VIP del Ingress**: `10.17.5.30`
* **Masters**:

  * `10.17.4.21` (bootstrap)
  * `10.17.4.22`
  * `10.17.4.23`
* **Workers**:

  * `10.17.4.24`, `10.17.4.25`, `10.17.4.26`, `10.17.4.27`
* **Load Balancers**:

  * `10.17.3.12`, `10.17.3.13`, `10.17.5.20`

---

## 🔄 Orden de inicio esperado

1. El nodo `master1` se inicializa con su IP real (`10.17.4.21`).
2. Se levanta el `k3s-server` y el `etcd` en `master1`.
3. Los otros masters se unen usando `https://10.17.4.21:6443` (no la VIP).
4. Una vez el clúster está operativo:

   * Se configura la VIP (`10.17.5.10`) con Keepalived.
   * Se habilita HAProxy en los nodos `haproxy_keepalived`.
5. HAProxy redirige el tráfico de `10.17.5.10:6443` hacia los masters disponibles.
6. El `kubeconfig` puede comenzar a usar la VIP como endpoint oficial.

---

## ✅ Configuración correcta para romper el ciclo

### 1. **`master1` usa su IP real para bootstrap**

* El script de Ansible no apunta a la VIP (`10.17.5.10`) para levantar el nodo inicial.
* Esto permite iniciar el API Server antes que HAProxy.

### 2. **HAProxy permite `bind` en IPs no locales**

```yaml
- name: Habilitar net.ipv4.ip_nonlocal_bind
  ansible.posix.sysctl:
    name: net.ipv4.ip_nonlocal_bind
    value: "1"
    sysctl_file: /etc/sysctl.d/99-haproxy-nonlocal-bind.conf
    reload: yes
    state: present
```

Esto evita errores de HAProxy como `Cannot bind to VIP`, ya que permite iniciar el proceso sin que la IP esté asignada localmente a la interfaz.

### 3. **Keepalived no requiere HAProxy para iniciar**

```ini
# override.conf
[Unit]
After=haproxy.service
# NO incluye Requires=haproxy.service
```

Esto asegura que Keepalived pueda arrancar independientemente de HAProxy. La relación es suave, no bloqueante.

### 4. **VIP solo se usa después de la estabilización**

* El uso de la VIP para el `kubeconfig` solo se hace después de validar que el balanceador HAProxy esté activo.

### 5. **Configuración de HAProxy**

El `haproxy.cfg` está correctamente estructurado para enrutar tráfico TCP en el puerto 6443 hacia los masters:

```haproxy
frontend kubernetes_api
    bind 10.17.5.10:6443
    mode tcp
    option tcplog
    default_backend kubernetes_masters

backend kubernetes_masters
    mode tcp
    balance roundrobin
    option tcp-check
    tcp-check connect port 6443
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server master-1 10.17.4.21:6443 check
    server master-2 10.17.4.22:6443 check
    server master-3 10.17.4.23:6443 check
```

---

## 🔧 Validaciones adicionales

* Comando para verificar si HAProxy permite bind:

```bash
sysctl net.ipv4.ip_nonlocal_bind
```

* Verificar configuración de HAProxy:

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
```

* Verificar si está corriendo:

```bash
sudo systemctl status haproxy
```

---

## 🧪 Estado de los Balanceadores tras el Playbook `install_haproxy_keepalived.yml`

Este es el estado esperado de los nodos balanceadores una vez finaliza la instalación automática con Ansible. Todos los nodos tienen HAProxy + Keepalived configurados, y las VIPs se asignan automáticamente por prioridad.

| Hostname        | IP           | Rol                                 | Keepalived         | HAProxy             | VIPs Activas                      |
|-----------------|--------------|--------------------------------------|--------------------|---------------------|------------------------------------|
| `k8s-api-lb`    | `10.17.5.20` | Nodo principal de VIPs (`priority=100`) | ✅ Activo (MASTER)  | ✅ Activo y corriendo | ✅ `10.17.5.10` y `10.17.5.30`      |
| `loadbalancer1` | `10.17.3.12` | Respaldo 1 (`priority=120`)         | ✅ Activo (BACKUP)  | ✅ Activo (en espera) | ❌ (asumirá VIPs si el principal cae) |
| `loadbalancer2` | `10.17.3.13` | Respaldo 2 (`priority=110`)         | ✅ Activo (BACKUP)  | ✅ Activo (en espera) | ❌ (asumirá VIPs si los anteriores caen) |

---

### ⚙️ Detalles técnicos

- Todos los nodos tienen `HAProxy` habilitado y en ejecución (`enabled + running`).
- Todos usan `ip_nonlocal_bind=1` para permitir el arranque sin poseer la VIP localmente.
- Keepalived gestiona la flotación de las siguientes IPs virtuales:
  - `10.17.5.10` → Kubernetes API (`6443`)
  - `10.17.5.30` → Ingress HTTP/HTTPS (`80` y `443`)
- El nodo que obtiene las VIPs es determinado por el archivo `host_vars/<ip>.yml` con sus prioridades:
  - `keepalived_priority_api`
  - `keepalived_priority_ingress`
- Si el nodo principal falla, el siguiente en prioridad **asume automáticamente las VIPs** y el tráfico continúa sin interrupciones.

---


## 🎯 Conclusión

Con esta configuración:

* El nodo `master1` puede iniciar el clúster sin la VIP.
* Los nodos balanceadores y Keepalived pueden arrancar sin romper dependencias.
* HAProxy puede arrancar incluso si no posee la VIP.

👍 Estás aplicando correctamente un patrón de alta disponibilidad tolerante a fallos y circularidades de dependencia.



ansible-galaxy collection install community.general

🧰 Resumen del Proyecto: HAProxy + Keepalived para K3s HA
Este proyecto implementa una solución de balanceo de carga altamente disponible para el acceso al clúster Kubernetes mediante HAProxy y Keepalived, gestionando múltiples VIPs (IP Virtuales) para separar tráfico crítico del API y del Ingress HTTP/HTTPS.

🎯 Objetivo
Garantizar:

Acceso ininterrumpido al API de Kubernetes (puerto 6443).

Disponibilidad continua para tráfico HTTP/HTTPS hacia los servicios internos (Ingress).

Failover automático de las IPs virtuales entre múltiples nodos balanceadores.

🔧 Componentes Clave
Componente	Descripción
HAProxy	Balanceador de carga TCP/HTTP para API y tráfico web
Keepalived	Gestor de alta disponibilidad mediante VRRP para mover VIPs entre nodos
VIPs	IPs flotantes que garantizan un único punto de entrada para el tráfico
Ansible	Automatización completa del despliegue y configuración
K3s	Clúster Kubernetes ligero y altamente disponible

🌐 Arquitectura General de Red
bash
Copiar
Editar
                    ┌────────────────────────────┐
                    │        Clientes externos    │
                    └────────────┬───────────────┘
                                 │
                           ┌─────▼─────┐
                           │ Cloudflare│
                           └─────┬─────┘
                                 │
                       VPN / NAT / WireGuard
                                 │
                    ┌────────────▼────────────┐
                    │  Load Balancer Principal│  <- VIPs: 10.17.5.10 / 10.17.5.30
                    │   (HAProxy + Keepalived)│
                    └────────────┬────────────┘
              ┌─────────────────┴─────────────────┐
              │                                   │
     ┌────────▼────────┐               ┌──────────▼─────────┐
     │  K3s Master #1  │               │  K3s Master #2-3    │
     │ API + etcd      │◄─────────────► API + etcd           │
     └─────────────────┘               └─────────────────────┘

              │ Ingress tráfico HTTP/HTTPS via Traefik
              ▼
         ┌────────────┐
         │  Workers   │
         └────────────┘
📦 VIPs y Tráfico
Tipo de Tráfico	Puerto(s)	VIP	Destino final
API de Kubernetes	6443	10.17.5.10	Nodos master de K3s (HA)
Servicios Ingress	80 / 443	10.17.5.30	Nodos worker vía Traefik (interno)

Las VIPs son asignadas dinámicamente al nodo con mayor prioridad activa.

Si un nodo falla, Keepalived transfiere la VIP al siguiente disponible.

🛠️ Mecanismo de Alta Disponibilidad
HAProxy:

Actúa como proxy TCP para 6443 y como proxy HTTP para 80/443.

Verifica salud de los nodos K3s y trabajadores.

Permite configuración nonlocal_bind para bindear IPs no locales.

Keepalived:

Ejecuta VRRP y scripts de tracking (estado de HAProxy).

Usa prioridad para determinar nodo MASTER de las VIPs.

Ejecuta vip_master.sh, vip_backup.sh, vip_fault.sh según evento.

Ansible:

Automatiza instalación en nodos HA.

Configura todos los archivos .cfg, .service, .conf necesarios.

Detecta Flatcar y aplica configuraciones especiales si es necesario.

📑 Flujo de Implementación con Ansible
Detecta distribución (Flatcar o no).

Instala HAProxy, Keepalived y dependencias.

Configura sysctl para permitir nonlocal_bind.

Aplica configuraciones plantilladas (haproxy.cfg.j2, keepalived.conf.j2).

Configura override de systemd para evitar dependencias circulares.

Reinicia servicios y valida salud.

✅ Ventajas Clave
Alta disponibilidad real (failover automático).

Separación de tráfico crítico.

Escalabilidad horizontal simple.

Configuración 100% automatizada y auditable (IaC).

Seguridad de acceso por VPN y Cloudflare (si aplica).
---
ansible-k8s-ha-loadbalancer/
├── ansible.cfg
├── inventory/
│   └── hosts.ini
├── host_vars/
│   ├── 10.17.3.12.yml        # loadbalancer1
│   ├── 10.17.3.13.yml        # loadbalancer2
│   └── 10.17.5.20.yml        # k8s-api-lb (nodo principal)
├── playbooks/
│   └── install_haproxy_keepalived.yml
├── templates/
│   ├── haproxy/
│   │   └── haproxy.cfg.j2
│   └── keepalived/
│       └── keepalived.conf.j2
├── Makefile
└── README.md
---


