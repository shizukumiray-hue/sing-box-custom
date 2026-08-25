# SSH over WebSocket Transport Implementation

## Summary

Successfully implemented V2Ray transport support (WebSocket, HTTP/2, gRPC, etc.) for SSH outbound in sing-box, following the same pattern used by Trojan, VMess, and VLESS outbounds.

## Files Modified

### 1. `/home/daisy/mayumi/Experimen/golang/github/sing-box/option/ssh.go`
- Added `OutboundTLSOptionsContainer` to enable TLS configuration
- Added `Transport *V2RayTransportOptions` field for transport configuration
- Both fields are optional (backward compatible with existing configs)

### 2. `/home/daisy/mayumi/Experimen/golang/github/sing-box/protocol/ssh/outbound.go`
- **Imports added:**
  - `github.com/sagernet/sing-box/common/tls`
  - `github.com/sagernet/sing-box/transport/v2ray`

- **Struct fields added to `Outbound`:**
  - `tlsConfig tls.Config`
  - `tlsDialer tls.Dialer`
  - `transport adapter.V2RayClientTransport`

- **Modified `NewOutbound()` function:**
  - Added TLS configuration initialization (lines 81-90)
  - Added V2Ray transport initialization (lines 91-98)
  - Transport and TLS are initialized before authentication setup

- **Modified `connect()` method:**
  - Replaced direct TCP connection with transport-aware connection logic
  - Connection priority: transport → TLS dialer → direct TCP
  - Maintains backward compatibility with existing direct TCP connections

- **Modified `InterfaceUpdated()` method:**
  - Added transport cleanup on network interface changes
  - Closes transport before closing client connection

- **Modified `Close()` method:**
  - Added transport cleanup alongside client connection cleanup
  - Uses `common.Close()` for both transport and connection

## Implementation Pattern

The implementation follows the exact pattern from Trojan outbound:
1. TLS config is initialized first if specified
2. Transport is initialized with the dialer, server address, transport options, and TLS config
3. Connection logic checks transport availability first, then TLS, then falls back to direct TCP
4. Cleanup methods properly close transport resources

## Verification

✅ Code compiles successfully: `go build ./protocol/ssh`
✅ Option package builds: `go build ./option`
✅ Full project builds: `go build ./cmd/sing-box`
✅ Configuration validation passes: `./sing-box check -c ssh-websocket-example.json`

## Usage Examples

### WebSocket Transport
```json
{
  "type": "ssh",
  "tag": "ssh-ws",
  "server": "example.com",
  "server_port": 443,
  "user": "admin",
  "password": "secret",
  "tls": {
    "enabled": true,
    "server_name": "example.com"
  },
  "transport": {
    "type": "ws",
    "path": "/ssh",
    "headers": {
      "Host": "example.com"
    }
  }
}
```

### HTTP/2 Transport
```json
{
  "type": "ssh",
  "tag": "ssh-http2",
  "server": "example.com",
  "server_port": 443,
  "user": "admin",
  "password": "secret",
  "tls": {
    "enabled": true,
    "server_name": "example.com"
  },
  "transport": {
    "type": "http",
    "path": "/ssh",
    "method": "POST"
  }
}
```

### gRPC Transport
```json
{
  "type": "ssh",
  "tag": "ssh-grpc",
  "server": "example.com",
  "server_port": 443,
  "user": "admin",
  "password": "secret",
  "tls": {
    "enabled": true,
    "server_name": "example.com"
  },
  "transport": {
    "type": "grpc",
    "service_name": "SSHTunnel"
  }
}
```

### Direct TCP (Backward Compatible)
```json
{
  "type": "ssh",
  "tag": "ssh-direct",
  "server": "example.com",
  "server_port": 22,
  "user": "admin",
  "password": "secret"
}
```

## Backward Compatibility

- All new fields (`tls`, `transport`) are optional
- Existing SSH configurations without these fields continue to work as before
- Default behavior remains direct TCP connection on port 22
- No breaking changes to existing functionality

## Technical Notes

1. **Transport Priority:** transport → TLS → direct TCP
2. **Resource Cleanup:** Transport is properly closed in both `InterfaceUpdated()` and `Close()` methods
3. **Error Handling:** Uses `E.Cause()` for proper error wrapping
4. **Thread Safety:** Existing mutex protection for client connection remains intact
5. **Connection Reuse:** SSH client connection reuse logic is preserved

## Testing Recommendations

1. Test WebSocket transport with TLS
2. Test HTTP/2 and gRPC transports
3. Verify backward compatibility with existing direct TCP configs
4. Test interface updates and reconnection scenarios
5. Verify proper resource cleanup on connection close
