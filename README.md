# Iodine VPN Tunnel

Questo repository contiene uno script per creare un tunnel VPN DNS usando **Iodine**, con configurazione lato server e client.
Permette di instradare tutto il traffico IPv4 attraverso un server VPS anche in reti con restrizioni firewall.

---

## Contenuto del Repository

* `iodine-server.sh` → Script da eseguire sul server VPS.
* `iodine-client.sh` → Script da eseguire sul client locale.

---

## Requisiti

### Server

* VPS Linux con accesso root.
* `iodined` installato (`sudo apt install iodine` o equivalente).
* `iptables` per configurare NAT e forwarding.
* Interfaccia pubblica funzionante (es. `eth0`, `ens3`).

### Client

* Sistema Linux con `iodine` installato (`sudo apt install iodine`).
* Accesso root per configurare rotte e interfaccia `dns0`.
* Interfaccia di rete locale attiva (es. `wlo1`).

---

## Configurazione DNS

Sul tuo provider DNS o server di zona, crea i seguenti record:

```
tun.dominio.com          NS   ns-tun.dominio.com
ns-tun.dominio.com       A    <IP_PUBBLICO_DEL_SERVER>
```

Sostituisci `<IP_PUBBLICO_DEL_SERVER>` con l’IP pubblico del VPS.

---

## Configurazione Script

### Server (`iodine-server.sh`)

Modifica le variabili all’inizio dello script:

```bash
VPS_IFACE="[INTERFACCIA_PER_INTERNET]"   # es. eth0
TUNNEL_IP="10.0.0.1"
IODINE_DOMAIN="[tun.dominio.com]"
PASSWORD="[TUA_PASSWORD]"
```

Lo script:

1. Pulisce eventuali regole `iptables` precedenti.
2. Riattiva IP forwarding.
3. Avvia `iodined` in background.
4. Inserisce le regole `iptables` con priorità massima (`-I`) per garantire il corretto funzionamento del tunnel.

### Client (`iodine-client.sh`)

Modifica le variabili all’inizio dello script:

```bash
GATEWAY_LOCALE="[TUO_GATEWAY]"          # es. 192.168.1.1
IFACE_LOCALE="wlo1"                      # interfaccia locale
SERVER_IP="[SERVER_VPS]"                 # IP pubblico del VPS
IODINE_DOMAIN="[tun.dominio.com]"
PASSWORD="[TUA_PASSWORD]"
```

Lo script:

1. Avvia il client `iodine` verso il server.
2. Disabilita temporaneamente le rotte IPv6 per forzare IPv4.
3. Imposta le rotte IPv4 per instradare tutto il traffico attraverso il tunnel.
4. Permette di disconnettere e ripristinare le rotte premendo **Ctrl+C**.

---

## Avvio

### Server

```bash
chmod +x iodine-server.sh
sudo ./iodine-server.sh
```

### Client

```bash
chmod +x iodine-client.sh
sudo ./iodine-client.sh
```

Per verificare che il traffico passi attraverso il VPS:

```bash
curl ifconfig.me/ip
```

Dovresti vedere l’IP del tuo VPS.

---

## Disconnessione

Premere **Ctrl+C** sul client per:

* Uccidere il processo `iodine`.
* Ripristinare le rotte IPv4 e IPv6 originali.

---

## Note di Sicurezza

* Assicurati che il firewall del VPS consenta il traffico UDP sulla porta 53.
* Scegli una password complessa per evitare accessi non autorizzati.
* Il tunnel instrada tutto il traffico IPv4, quindi il server deve essere affidabile.

---

## Licenza

MIT License
