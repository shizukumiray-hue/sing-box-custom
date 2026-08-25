package ssh

import (
	"bytes"
	"context"
	"encoding/base64"
	"math/rand"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/sagernet/sing-box/adapter"
	"github.com/sagernet/sing-box/adapter/outbound"
	"github.com/sagernet/sing-box/common/dialer"
	"github.com/sagernet/sing-box/common/tls"
	C "github.com/sagernet/sing-box/constant"
	"github.com/sagernet/sing-box/log"
	"github.com/sagernet/sing-box/option"
	"github.com/sagernet/sing-box/transport/v2ray"
	"github.com/sagernet/sing/common"
	E "github.com/sagernet/sing/common/exceptions"
	"github.com/sagernet/sing/common/logger"
	M "github.com/sagernet/sing/common/metadata"
	N "github.com/sagernet/sing/common/network"

	"golang.org/x/crypto/ssh"
)

func RegisterOutbound(registry *outbound.Registry) {
	outbound.Register[option.SSHOutboundOptions](registry, C.TypeSSH, NewOutbound)
}

var _ adapter.InterfaceUpdateListener = (*Outbound)(nil)

type Outbound struct {
	outbound.Adapter
	ctx               context.Context
	logger            logger.ContextLogger
	dialer            N.Dialer
	serverAddr        M.Socksaddr
	user              string
	hostKey           []ssh.PublicKey
	hostKeyAlgorithms []string
	clientVersion     string
	authMethod        []ssh.AuthMethod
	tlsConfig         tls.Config
	tlsDialer         tls.Dialer
	transport         adapter.V2RayClientTransport
	clientAccess      sync.Mutex
	clientConn        net.Conn
	client            *ssh.Client
}

func NewOutbound(ctx context.Context, router adapter.Router, logger log.ContextLogger, tag string, options option.SSHOutboundOptions) (adapter.Outbound, error) {
	outboundDialer, err := dialer.New(ctx, options.DialerOptions, options.ServerIsDomain())
	if err != nil {
		return nil, err
	}
	outbound := &Outbound{
		Adapter:           outbound.NewAdapterWithDialerOptions(C.TypeSSH, tag, []string{N.NetworkTCP}, options.DialerOptions),
		ctx:               ctx,
		logger:            logger,
		dialer:            outboundDialer,
		serverAddr:        options.ServerOptions.Build(),
		user:              options.User,
		hostKeyAlgorithms: options.HostKeyAlgorithms,
		clientVersion:     options.ClientVersion,
	}
	if outbound.serverAddr.Port == 0 {
		outbound.serverAddr.Port = 22
	}
	if outbound.user == "" {
		outbound.user = "root"
	}
	if outbound.clientVersion == "" {
		outbound.clientVersion = randomVersion()
	}
	// TLS support
	if options.TLS != nil {
		outbound.tlsConfig, err = tls.NewClient(ctx, logger, options.Server, common.PtrValueOrDefault(options.TLS))
		if err != nil {
			return nil, err
		}
		if outbound.tlsConfig != nil {
			outbound.tlsDialer = tls.NewDialer(outboundDialer, outbound.tlsConfig)
		}
	}
	// Transport support
	if options.Transport != nil {
		outbound.transport, err = v2ray.NewClientTransport(ctx, outbound.dialer, outbound.serverAddr,
			common.PtrValueOrDefault(options.Transport), outbound.tlsConfig)
		if err != nil {
			return nil, E.Cause(err, "create client transport: ", options.Transport.Type)
		}
	}
	if options.Password != "" {
		outbound.authMethod = append(outbound.authMethod, ssh.Password(options.Password))
	}
	if len(options.PrivateKey) > 0 || options.PrivateKeyPath != "" {
		var privateKey []byte
		if len(options.PrivateKey) > 0 {
			privateKey = []byte(strings.Join(options.PrivateKey, "\n"))
		} else {
			var err error
			privateKey, err = os.ReadFile(os.ExpandEnv(options.PrivateKeyPath))
			if err != nil {
				return nil, E.Cause(err, "read private key")
			}
		}
		var signer ssh.Signer
		var err error
		if options.PrivateKeyPassphrase == "" {
			signer, err = ssh.ParsePrivateKey(privateKey)
		} else {
			signer, err = ssh.ParsePrivateKeyWithPassphrase(privateKey, []byte(options.PrivateKeyPassphrase))
		}
		if err != nil {
			return nil, E.Cause(err, "parse private key")
		}
		outbound.authMethod = append(outbound.authMethod, ssh.PublicKeys(signer))
	}
	if len(options.HostKey) > 0 {
		for _, hostKey := range options.HostKey {
			key, _, _, _, err := ssh.ParseAuthorizedKey([]byte(hostKey))
			if err != nil {
				return nil, E.Cause(err, "parse host key: ", hostKey)
			}
			outbound.hostKey = append(outbound.hostKey, key)
		}
	}
	return outbound, nil
}

func randomVersion() string {
	version := "SSH-2.0-OpenSSH_"
	if rand.Intn(2) == 0 {
		version += "7." + strconv.Itoa(rand.Intn(10))
	} else {
		version += "8." + strconv.Itoa(rand.Intn(9))
	}
	return version
}

func (s *Outbound) connect(ctx context.Context) (*ssh.Client, error) {
	if s.client != nil {
		return s.client, nil
	}

	s.clientAccess.Lock()
	defer s.clientAccess.Unlock()

	if s.client != nil {
		return s.client, nil
	}

	// Connection with transport support
	var conn net.Conn
	var err error

	if s.transport != nil {
		// Use WebSocket or other V2Ray transport
		conn, err = s.transport.DialContext(ctx)
	} else if s.tlsDialer != nil {
		// Use TLS without transport
		conn, err = s.tlsDialer.DialTLSContext(ctx, s.serverAddr)
	} else {
		// Direct TCP connection (existing behavior)
		conn, err = s.dialer.DialContext(ctx, N.NetworkTCP, s.serverAddr)
	}

	if err != nil {
		return nil, err
	}

	config := &ssh.ClientConfig{
		User:              s.user,
		Auth:              s.authMethod,
		ClientVersion:     s.clientVersion,
		HostKeyAlgorithms: s.hostKeyAlgorithms,
		HostKeyCallback: func(hostname string, remote net.Addr, key ssh.PublicKey) error {
			if len(s.hostKey) == 0 {
				return nil
			}
			serverKeyRaw := key.Marshal()
			for _, hostKey := range s.hostKey {
				if bytes.Equal(serverKeyRaw, hostKey.Marshal()) {
					return nil
				}
			}
			return E.New("host key mismatch, server send ", key.Type(), " ", base64.StdEncoding.EncodeToString(serverKeyRaw))
		},
	}

	clientConn, chans, reqs, err := ssh.NewClientConn(conn, s.serverAddr.Addr.String(), config)
	if err != nil {
		conn.Close()
		return nil, E.Cause(err, "connect to ssh server")
	}

	client := ssh.NewClient(clientConn, chans, reqs)

	s.clientConn = conn
	s.client = client

	go func() {
		client.Wait()
		conn.Close()
		s.clientAccess.Lock()
		s.client = nil
		s.clientConn = nil
		s.clientAccess.Unlock()
	}()

	return client, nil
}

func (s *Outbound) InterfaceUpdated() {
	s.clientAccess.Lock()
	transport := s.transport
	conn := s.clientConn
	s.client = nil
	s.clientConn = nil
	s.clientAccess.Unlock()
	
	if transport != nil {
		transport.Close()
	}
	common.Close(conn)
}

func (s *Outbound) Close() error {
	s.clientAccess.Lock()
	transport := s.transport
	conn := s.clientConn
	s.client = nil
	s.clientConn = nil
	s.clientAccess.Unlock()
	
	return common.Close(transport, conn)
}

func (s *Outbound) DialContext(ctx context.Context, network string, destination M.Socksaddr) (net.Conn, error) {
	ctx, metadata := adapter.ExtendContext(ctx)
	metadata.Outbound = s.Tag()
	metadata.Destination = destination
	
	switch N.NetworkName(network) {
	case N.NetworkTCP:
		s.logger.InfoContext(ctx, "outbound connection to ", destination)
	}
	
	client, err := s.connect(ctx)
	if err != nil {
		return nil, err
	}
	conn, err := client.Dial(network, destination.String())
	if err != nil {
		return nil, E.Cause(err, "dial through ssh")
	}
	return &chanConnWrapper{Conn: conn}, nil
}

func (s *Outbound) ListenPacket(ctx context.Context, destination M.Socksaddr) (net.PacketConn, error) {
	_, metadata := adapter.ExtendContext(ctx)
	metadata.Outbound = s.Tag()
	metadata.Destination = destination
	return nil, os.ErrInvalid
}

type chanConnWrapper struct {
	net.Conn
}

func (c *chanConnWrapper) SetDeadline(t time.Time) error {
	return os.ErrInvalid
}

func (c *chanConnWrapper) SetReadDeadline(t time.Time) error {
	return os.ErrInvalid
}

func (c *chanConnWrapper) SetWriteDeadline(t time.Time) error {
	return os.ErrInvalid
}
