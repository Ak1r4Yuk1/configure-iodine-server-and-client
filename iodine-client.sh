#!/bin/bash

# --- CONFIGURAZIONE ESSENZIALE CLIENT (Verifica che questi valori siano corretti) ---
GATEWAY_LOCALE="[TUO_GATEWAY]"
IFACE_LOCALE="wlo1"
SERVER_IP="[SERVER_VPS]"
IODINE_DOMAIN="[TUN.DOMINIO.COM]"
PASSWORD="[TUA_PASSWORD]"
# --- FINE CONFIGURAZIONE ---

# Nome del file temporaneo per salvare lo stato IPv6
IPV6_STATE_FILE="/tmp/ipv6_routes_backup.txt"

# Funzione per pulire e uscire
cleanup() {
    echo ""
    echo "======================================================="
    echo "❌ Disconnessione e Ripristino del Sistema..."
    
    # 1. Uccide il processo iodine
    sudo pkill iodine 2>/dev/null
    
    # 2. Ripristina le rotte predefinite (IPv4)
    sudo ip route del default via 10.0.0.1 dev dns0 2>/dev/null
    sudo ip route del $SERVER_IP via $GATEWAY_LOCALE dev $IFACE_LOCALE 2>/dev/null
    # Ripristina la rotta originale (per navigare senza tunnel)
    sudo ip route add default via $GATEWAY_LOCALE dev $IFACE_LOCALE 2>/dev/null

    # 3. Ripristina le rotte IPv6
    if [ -f "$IPV6_STATE_FILE" ]; then
        echo "Ripristino delle rotte IPv6..."
        # Elimina le rotte predefinite IPv6 attuali per evitare duplicati
        sudo ip -6 route del default dev $IFACE_LOCALE 2>/dev/null
        # Ripristina la rotta IPv6 salvata
        sudo ip -6 route restore "$IPV6_STATE_FILE"
        rm -f "$IPV6_STATE_FILE"
    fi

    echo "✅ Tunnel chiuso e rotte ripristinate."
    echo "======================================================="
    exit 0
}

# Imposta la funzione cleanup per essere chiamata all'interruzione (Ctrl+C)
trap cleanup INT

## SEZIONE AVVIO E CONFIGURAZIONE ##

echo "======================================================="
echo "Avvio Tunnel Iodine e configurazione Routing Client..."
echo "======================================================="

# 1. Avvio del client iodine in background
echo "1. Avvio del client iodine. Attendi 'Connection setup complete...'."
nohup sudo iodine -P $PASSWORD $IODINE_DOMAIN -f > /dev/null 2>&1 &

# 2. Attendi l'instaurazione della connessione
sleep 7

# Verifica se l'interfaccia dns0 è attiva
if ! ip a show dns0 > /dev/null; then
    echo "Errore: L'interfaccia dns0 non è stata creata. Controlla il server."
    cleanup
fi

# 3. Disabilita IPv6 (Rotta predefinita)
echo "3. Disabilitazione Rotte IPv6..."
# Salva le rotte IPv6 esistenti (in particolare la rotta predefinita)
sudo ip -6 route show > "$IPV6_STATE_FILE"
# Rimuove la rotta predefinita IPv6 (forzando il fallback su IPv4)
sudo ip -6 route del default dev $IFACE_LOCALE 2>/dev/null 

# 4. Configurazione Rotte IPv4

echo "4. Impostazione delle Rotte IPv4 (Tunnel)..."
# Pulizia Rotte IPv4 precedenti
sudo ip route del default via 10.0.0.1 dev dns0 2>/dev/null
sudo ip route del $SERVER_IP via $GATEWAY_LOCALE dev $IFACE_LOCALE 2>/dev/null
sudo ip route del default via $GATEWAY_LOCALE dev $IFACE_LOCALE 2>/dev/null

# A. Rotta Statica per il Server (CRITICA: Il traffico DNS DEVE bypassare il tunnel)
sudo ip route add $SERVER_IP via $GATEWAY_LOCALE dev $IFACE_LOCALE

# B. Rotta Predefinita per il Tunnel (Forza tutto il traffico a uscire da dns0)
sudo ip route add default via 10.0.0.1 dev dns0

echo "======================================================="
echo "✅ Routing Cliente completato. IPv6 disattivato."
echo "   Esegui: curl ifconfig.me/ip per verificare l'IP del VPS."
echo "   Premi Ctrl+C per disconnettere e ripristinare le rotte."
echo "======================================================="

# Il processo rimane attivo in attesa di Ctrl+C
wait
