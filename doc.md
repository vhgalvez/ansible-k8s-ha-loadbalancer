# Diseño de Red para VIPs en el Clúster Kubernetes HA

## ✅ Objetivo

Gestionar múltiples direcciones IP flotantes (VIPs) de alta disponibilidad en Kubernetes mediante `Keepalived` y un único bridge virtual compartido.

---

## 🌐 VIPs Definidas

- `10.17.5.10`: VIP para la API de Kubernetes (`6443`)
- `10.17.5.30`: VIP para el tráfico Ingress (`80` y `443`)

---

## 🧱 Topología de Red (Resumen)

| Nodo             | Interfaz | Bridge Virtual | VIPs que puede asumir             |
|------------------|----------|----------------|----------------------------------|
| `k8s-api-lb`      | `eth1`   | `br-vip`       | `10.17.5.10`, `10.17.5.30`       |
| `loadbalancer1`  | `eth1`   | `br-vip`       | `10.17.5.10`, `10.17.5.30`       |
| `loadbalancer2`  | `eth1`   | `br-vip`       | `10.17.5.10`, `10.17.5.30`       |

- Todos los nodos de balanceo tienen conectividad por el mismo bridge.
- No se asignan las VIPs manualmente. `Keepalived` se encarga de anunciarlas dinámicamente según el nodo que esté en estado `MASTER`.

---

## 🛑 ¿Se requieren dos bridges separados?

**No.**
- Ambas VIPs pertenecen a la misma red (`10.17.5.0/24`)
- Se pueden gestionar en una única interfaz de red (`eth1`)
- Basta un único `bridge` (ej. `br-vip`)

---

## 🧠 Configuración de Keepalived (Ejemplo)

```conf
vrrp_instance VI_API {
  state BACKUP
  interface eth1
  virtual_router_id 51
  priority 100
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass 1234
  }
  virtual_ipaddress {
    10.17.5.10
  }
}

vrrp_instance VI_INGRESS {
  state BACKUP
  interface eth1
  virtual_router_id 52
  priority 100
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass 1234
  }
  virtual_ipaddress {
    10.17.5.30
  }
}
```