package v2raywebsocket

import (
	"fmt"
	"strings"
	"time"
)

// ParseCustomPayload memproses template custom payload dan mengganti placeholder
// dengan nilai sebenarnya, lalu memecahnya berdasarkan marker [split]
func ParseCustomPayload(template, bugHost, realHost string, realPort int, userAgent string) [][]byte {
	if template == "" {
		return nil
	}

	// Replace placeholders
	processed := template
	processed = strings.ReplaceAll(processed, "[proxy]", bugHost)
	processed = strings.ReplaceAll(processed, "[host]", realHost)
	processed = strings.ReplaceAll(processed, "[port]", fmt.Sprintf("%d", realPort))
	processed = strings.ReplaceAll(processed, "[ua]", userAgent)
	
	// Replace line endings
	processed = strings.ReplaceAll(processed, "[crlf]", "\r\n")
	processed = strings.ReplaceAll(processed, "[lf]", "\n")
	processed = strings.ReplaceAll(processed, "[cr]", "\r")

	// Split by [split] marker
	parts := strings.Split(processed, "[split]")
	
	result := make([][]byte, 0, len(parts))
	for _, part := range parts {
		if len(part) > 0 {
			result = append(result, []byte(part))
		}
	}

	return result
}

// SendCustomPayload mengirim custom payload dengan delay antara split packets
func SendCustomPayload(conn interface{ Write([]byte) (int, error) }, payloadParts [][]byte, splitDelay time.Duration) error {
	if len(payloadParts) == 0 {
		return nil
	}

	for i, part := range payloadParts {
		_, err := conn.Write(part)
		if err != nil {
			return fmt.Errorf("failed to send payload part %d: %w", i+1, err)
		}
		
		// Add delay between splits (except after last part)
		if i < len(payloadParts)-1 && splitDelay > 0 {
			time.Sleep(splitDelay)
		}
	}

	return nil
}

// BuildDefaultUserAgent returns default User-Agent if not provided
func BuildDefaultUserAgent() string {
	return "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
}
