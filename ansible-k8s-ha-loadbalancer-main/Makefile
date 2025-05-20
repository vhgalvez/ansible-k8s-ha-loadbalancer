INVENTORY ?= inventory/hosts.ini
PLAYBOOK  ?= playbooks/install_haproxy_keepalived.yml
GROUP     ?= haproxy_keepalived

all: deploy

deploy:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

check:
	ansible -i $(INVENTORY) $(GROUP) -a "haproxy -c -f /etc/haproxy/haproxy.cfg"

vip-status:
	ansible -i $(INVENTORY) $(GROUP) -a "ip -4 a | grep -E '10\.17\.5\.(10|30)' || true"

socket-status:
	ansible -i $(INVENTORY) $(GROUP) -a "echo 'show stat' | socat stdio /var/lib/haproxy/admin.sock || true"

status:
	ansible -i $(INVENTORY) $(GROUP) -a "systemctl is-active haproxy keepalived"

restart:
	ansible -i $(INVENTORY) $(GROUP) -m systemd -a "name=haproxy state=restarted"
	ansible -i $(INVENTORY) $(GROUP) -m systemd -a "name=keepalived state=restarted"

clean:
	ansible -i $(INVENTORY) $(GROUP) -m file -a "path=/etc/haproxy/haproxy.cfg state=absent"
	ansible -i $(INVENTORY) $(GROUP) -m file -a "path=/etc/keepalived/keepalived.conf state=absent"
