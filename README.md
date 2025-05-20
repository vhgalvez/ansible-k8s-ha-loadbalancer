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
