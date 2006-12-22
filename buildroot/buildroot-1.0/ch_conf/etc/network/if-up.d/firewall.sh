# Alle Regeln und selbstdefinierte Chains löschen
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Policies, die ale Pakete abweisen
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# gespoofte Pakete des lokalen Netzes
iptables -A INPUT -i ! eth0 -s 192.168.42.0/24 -j LOG \
--log-prefix "Internes Netz gespooft: "
iptables -A INPUT -i ! eth0 -s 192.168.42.0/24 -j DROP
iptables -A FORWARD -i ! eth0 -s 192.168.42.0/24 -j LOG \
--log-prefix "Internes Netz gespooft: "
iptables -A FORWARD -i ! eth0 -s 192.168.42.0/24 -j DROP

# gespoofte Pakete des lokalen Interfaces
iptables -A INPUT -i ! lo -s 127.0.0.1 -j LOG \
--log-prefix "Loopback gespooft: "
iptables -A INPUT -i ! lo -s 127.0.0.1 -j DROP
iptables -A FORWARD -i ! lo -s 127.0.0.1 -j LOG \
--log-prefix "Loopback gespooft: "
iptables -A FORWARD -i ! lo -s 127.0.0.1 -j DROP

# gespoofte Pakete des externen Interface der Firewall
iptables -A INPUT -i ! lo -s "$EXTIP" -j LOG \
--log-prefix "$EXTIP gespooft: "
iptables -A INPUT -i ! lo -s "$EXTIP" -j DROP
iptables -A FORWARD -i ! lo -s "$EXTIP" -j LOG \
--log-prefix "$EXTIP gespooft: "
iptables -A FORWARD -i ! lo -s "$EXTIP" -j DROP
