#!/bin/bash

# --- CONFIGURAZIONE ESSENZIALE ---
# Sostituisci con il nome della TUA interfaccia pubblica (es. eth0)
VPS_IFACE="[INTERFACCIA_PER_INTERNET]"
TUNNEL_IP="10.0.0.1"
IODINE_DOMAIN="[tun.dominio.com]"
PASSWORD="[TUA_PASSWORD]"
# ---------------------------------

echo "======================================================="
echo "CONFIGURAZIONE FORZATA IPTABLES (USO -I)"
echo "======================================================="

# 1. Pulizia delle regole Iodine aggiunte in precedenza (per evitare duplicati)
echo "1. Tentativo di rimozione delle regole Iodine precedenti (non critico se fallisce)..."
# Rimuove le regole con -D (Delete), cercando quelle aggiunte in fondo.
sudo iptables -D INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
sudo iptables -t nat -D POSTROUTING -o $VPS_IFACE -j MASQUERADE 2>/dev/null
sudo iptables -D FORWARD -i dns0 -o $VPS_IFACE -j ACCEPT 2>/dev/null
sudo iptables -D FORWARD -i $VPS_IFACE -o dns0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null


# 2. Riattivazione IP Forwarding e riavvio di iodined
echo "2. Abilitazione IP Forwarding e riavvio iodined..."
sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
# Riavvia il servizio per ricaricare dns0
sudo killall iodined 2>/dev/null
nohup sudo iodined -P $PASSWORD -c $TUNNEL_IP $IODINE_DOMAIN > /dev/null 2>&1 &
sleep 2

# 3. Inserimento Forzato delle Regole (Flag -I)
echo "3. Inserimento forzato delle regole all'inizio delle catene..."

# A. INPUT: La regola per la porta 53 deve essere la prima
sudo iptables -I INPUT 1 -p udp --dport 53 -j ACCEPT

# B. FORWARD: Le regole di inoltro devono essere le prime per avere priorità
sudo iptables -I FORWARD 1 -i dns0 -o $VPS_IFACE -j ACCEPT
sudo iptables -I FORWARD 2 -i $VPS_IFACE -o dns0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# C. NAT/POSTROUTING: La regola di mascheramento deve essere la prima nella catena POSTROUTING
sudo iptables -t nat -I POSTROUTING 1 -o $VPS_IFACE -j MASQUERADE

echo "======================================================="
echo "✅ Regole Iptables inserite. Hanno la massima priorità."
echo "======================================================="
