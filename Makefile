# Variables
INVENTORY ?= inventory/hosts.ini
PLAYBOOK  ?= ansible/playbooks/install_haproxy_keepalived.yml

# Objetivo por defecto
all: deploy

# Despliegue completo de HAProxy + Keepalived
deploy:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

# Validación de configuración de HAProxy en todos los nodos
check:
	ansible -i $(INVENTORY) haproxy_keepalived -a "haproxy -c -f /etc/haproxy/haproxy.cfg"

# Mostrar las VIPs activas en cada nodo
vip-status:
	ansible -i $(INVENTORY) haproxy_keepalived -a "ip a | grep 10.17.5"

# Ver sockets de administración HAProxy
socket-status:
	ansible -i $(INVENTORY) haproxy_keepalived -a "echo 'show stat' | socat stdio /var/lib/haproxy/admin.sock"

# Mostrar estado de los servicios
status:
	ansible -i $(INVENTORY) haproxy_keepalived -a "systemctl status haproxy keepalived"

# Reiniciar servicios en todos los balanceadores
restart:
	ansible -i $(INVENTORY) haproxy_keepalived -m systemd -a "name=haproxy state=restarted"
	ansible -i $(INVENTORY) haproxy_keepalived -m systemd -a "name=keepalived state=restarted"

# Limpieza de configuraciones anteriores
clean:
	ansible -i $(INVENTORY) haproxy_keepalived -m file -a "path=/etc/haproxy/haproxy.cfg state=absent"
	ansible -i $(INVENTORY) haproxy_keepalived -m file -a "path=/etc/keepalived/keepalived.conf state=absent"