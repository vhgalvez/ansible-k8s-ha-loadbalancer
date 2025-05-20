# -----------------------------
# VARIABLES
# -----------------------------
INVENTORY ?= inventory/hosts.ini
PLAYBOOK  ?= ansible/playbooks/install_haproxy_keepalived.yml
GROUP     ?= haproxy_keepalived

# -----------------------------
# OBJETIVO POR DEFECTO
# -----------------------------
all: deploy

# -----------------------------
# DESPLIEGUE COMPLETO
# -----------------------------
deploy:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

# -----------------------------
# VALIDAR CONFIGURACIÓN DE HAProxy
# -----------------------------
check:
	ansible -i $(INVENTORY) $(GROUP) -a "haproxy -c -f /etc/haproxy/haproxy.cfg"

# -----------------------------
# MOSTRAR VIPs ACTIVAS EN LOS BALANCEADORES
# -----------------------------
vip-status:
	ansible -i $(INVENTORY) $(GROUP) -a "ip -4 a | grep -E '10\.17\.5\.(10|30)' || true"

# -----------------------------
# VER ESTADÍSTICAS POR SOCKET ADMIN DE HAProxy
# -----------------------------
socket-status:
	ansible -i $(INVENTORY) $(GROUP) -a "echo 'show stat' | socat stdio /var/lib/haproxy/admin.sock || true"

# -----------------------------
# ESTADO DE LOS SERVICIOS
# -----------------------------
status:
	ansible -i $(INVENTORY) $(GROUP) -a "systemctl is-active haproxy keepalived"

# -----------------------------
# REINICIAR SERVICIOS EN NODOS HA
# -----------------------------
restart:
	ansible -i $(INVENTORY) $(GROUP) -m systemd -a "name=haproxy state=restarted"
	ansible -i $(INVENTORY) $(GROUP) -m systemd -a "name=keepalived state=restarted"

# -----------------------------
# LIMPIEZA DE CONFIGURACIONES (solo archivos)
# -----------------------------
clean:
	ansible -i $(INVENTORY) $(GROUP) -m file -a "path=/etc/haproxy/haproxy.cfg state=absent"
	ansible -i $(INVENTORY) $(GROUP) -m file -a "path=/etc/keepalived/keepalived.conf state=absent"