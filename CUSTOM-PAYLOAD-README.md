# Custom HTTP Payload Injection untuk SSH WebSocket

## Deskripsi

Fitur ini menambahkan kemampuan custom HTTP payload injection ke sing-box fork reF1nd untuk SSH WebSocket transport, mirip dengan HiddifySSH dan HTTP Injector. Fitur ini memungkinkan SNI/Host header spoofing untuk bypass DPI (Deep Packet Inspection).

## Fitur

### Placeholder yang Didukung

- `[crlf]` → Carriage Return + Line Feed (`\r\n`)
- `[lf]` → Line Feed (`\n`)
- `[cr]` → Carriage Return (`\r`)
- `[split]` → Kirim paket, tunggu 100ms, lalu lanjutkan (packet splitting)
- `[host]` → Real SSH server host/IP
- `[port]` → Real SSH server port
- `[proxy]` → Bug host (SNI/Host header untuk spoofing)
- `[ua]` → User-Agent (default: Chrome Mobile)

### Cara Kerja

1. **Standard Mode** (tanpa `custom_payload`): 
   - WebSocket handshake normal sesuai RFC 6455

2. **Custom Payload Mode** (dengan `custom_payload`):
   - Kirim raw HTTP request dengan placeholder yang sudah diganti
   - Support packet splitting dengan marker `[split]`
   - Bypass DPI dengan SNI/Host header spoofing

## Konfigurasi

### Format Config

```json
{
  "type": "ssh",
  "server": "real-server.com",
  "server_port": 443,
  "user": "tunnel",
  "password": "your-password",
  "tls": {
    "enabled": true,
    "server_name": "bug-host.com"
  },
  "transport": {
    "type": "ws",
    "path": "/",
    "custom_payload": "PAYLOAD_TEMPLATE",
    "bug_host": "bug-host.com"
  }
}
```

### Parameter Baru di `transport`

| Parameter | Type | Required | Deskripsi |
|-----------|------|----------|-----------|
| `custom_payload` | string | No | Template HTTP payload dengan placeholder |
| `bug_host` | string | No | Host untuk SNI/Host header spoofing (default: server address) |

### Contoh Payload Template

#### 1. Simple GET Request
```
GET / HTTP/1.1[crlf]Host: [proxy][crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]
```

#### 2. Split Packet (Bypass DPI)
```
GET / HTTP/1.1[crlf]Host: [proxy][crlf][crlf][split]MKCOL /? HTTP/1.1[crlf]Host: [host][crlf]Connection: upgrade[crlf]Upgrade: websocket[crlf][crlf]
```

#### 3. Advanced dengan User-Agent
```
GET /ssh HTTP/1.1[crlf]Host: [proxy][crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]
```

#### 4. Multi-Split (Aggressive DPI Bypass)
```
GET / HTTP/1.1[crlf]Host: [proxy][crlf][crlf][split]CONNECT [host]:[port] HTTP/1.1[crlf]Host: [host][crlf][crlf][split]GET /ssh HTTP/1.1[crlf]Upgrade: websocket[crlf][crlf]
```

## Contoh Konfigurasi Lengkap

### Config 1: Axis/XL Opok (Ruangguru EDU)

```json
{
  "type": "ssh",
  "tag": "ssh-axis-edu",
  "server": "id-ssh.example.com",
  "server_port": 443,
  "user": "tunnel",
  "password": "password123",
  "tls": {
    "enabled": true,
    "server_name": "edu.ruangguru.com",
    "insecure": false
  },
  "transport": {
    "type": "ws",
    "path": "/",
    "custom_payload": "GET / HTTP/1.1[crlf]Host: [proxy][crlf][crlf][split]MKCOL /? HTTP/1.1[crlf]Host: [host][crlf]Connection: upgrade[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]",
    "bug_host": "edu.ruangguru.com"
  }
}
```

### Config 2: Telkomsel (Cloudflare)

```json
{
  "type": "ssh",
  "tag": "ssh-tsel-cf",
  "server": "sg-ssh.example.com",
  "server_port": 80,
  "user": "tunnel",
  "password": "password123",
  "transport": {
    "type": "ws",
    "path": "/ssh",
    "custom_payload": "GET /ssh HTTP/1.1[crlf]Host: [proxy][crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]",
    "bug_host": "cdn.cloudflare.net"
  }
}
```

### Config 3: Standard WebSocket (Backward Compatible)

```json
{
  "type": "ssh",
  "tag": "ssh-standard",
  "server": "server.example.com",
  "server_port": 443,
  "user": "tunnel",
  "password": "password123",
  "tls": {
    "enabled": true,
    "server_name": "server.example.com"
  },
  "transport": {
    "type": "ws",
    "path": "/ssh"
  }
}
```

## Implementasi Teknis

### File yang Dimodifikasi

1. **`option/v2ray_transport.go`**
   - Tambah field `CustomPayload` dan `BugHost` ke `V2RayWebsocketOptions`

2. **`transport/v2raywebsocket/payload.go`** (NEW)
   - Parser untuk placeholder payload
   - Logic untuk packet splitting
   - Function `ParseCustomPayload()` dan `SendCustomPayload()`

3. **`transport/v2raywebsocket/client.go`**
   - Simpan `customPayload` dan `bugHost` di struct `Client`
   - Modify `dialContext()` untuk cek dan gunakan custom payload
   - Fallback ke standard handshake jika `customPayload` kosong

### Flow Diagram

```
┌─────────────────────────────────────────┐
│ Config Load                             │
│ - custom_payload: "..."                 │
│ - bug_host: "edu.ruangguru.com"         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ NewClient()                             │
│ - Store customPayload & bugHost         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ dialContext()                           │
│ - Check if customPayload != ""          │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴───────┐
       │               │
   YES │               │ NO
       ▼               ▼
┌─────────────┐  ┌──────────────┐
│Custom Payload│  │Standard WS   │
│Mode          │  │Handshake     │
└──────┬───────┘  └──────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ ParseCustomPayload()                    │
│ - Replace [proxy] → bug_host            │
│ - Replace [host] → real_host            │
│ - Replace [port] → real_port            │
│ - Replace [ua] → User-Agent             │
│ - Replace [crlf] → \r\n                 │
│ - Split by [split]                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ SendCustomPayload()                     │
│ - Send part 1                           │
│ - Sleep 100ms                           │
│ - Send part 2                           │
│ - ...                                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Create WebsocketConn                    │
│ - Skip standard WS handshake            │
│ - Return raw connection                 │
└─────────────────────────────────────────┘
```

## Testing

### Build

```bash
cd /home/daisy/mayumi/Experimen/golang/github/sing-box
go build ./cmd/sing-box
```

### Run Test

```bash
./sing-box run -c example-ssh-custom-payload.json
```

### Verify Custom Payload

Gunakan `tcpdump` atau Wireshark untuk capture traffic:

```bash
sudo tcpdump -i any -A 'tcp port 443' | grep -A 20 "GET"
```

Expected output (dengan custom payload):
```
GET / HTTP/1.1
Host: edu.ruangguru.com

MKCOL /? HTTP/1.1
Host: real-server.example.com
Connection: upgrade
User-Agent: Mozilla/5.0...
Upgrade: websocket
```

## Troubleshooting

### Error: Connection timeout
- Pastikan `bug_host` sesuai dengan yang didukung ISP
- Coba ganti payload template

### Error: Bad handshake
- Custom payload format salah
- Cek placeholder diganti dengan benar
- Test dengan standard WS dulu (tanpa `custom_payload`)

### Tidak bisa connect
- Pastikan server SSH support WebSocket
- Cek firewall/iptables
- Verify TLS settings

## Backward Compatibility

✅ **100% Backward Compatible**

Jika `custom_payload` kosong atau tidak ada, sing-box akan otomatis menggunakan standard WebSocket handshake sesuai RFC 6455. Tidak ada breaking changes untuk konfigurasi existing.

## References

- HiddifySSH: https://github.com/hiddify/HiddifySSH
- HTTP Injector payload format
- RFC 6455: The WebSocket Protocol

## Credits

Implementasi oleh: reF1nd fork maintainer
Based on: sing-box by SagerNet
Inspired by: HiddifySSH, HTTP Injector
