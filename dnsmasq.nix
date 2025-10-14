{ pkgs, ... }:

{
  # Configure dnsmasq using launchd with dynamic Tailscale IP
  launchd.daemons.dnsmasq = {
    path = [ pkgs.dnsmasq pkgs.tailscale pkgs.coreutils ];
    script = ''
      # Create directory for hosts file
      mkdir -p /var/run/dnsmasq

      # Get current Tailscale IP dynamically
      TAILSCALE_IP=$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null | head -n1)

      # Fall back to localhost if Tailscale isn't running
      if [ -z "$TAILSCALE_IP" ]; then
        TAILSCALE_IP="127.0.0.1"
      fi

      # Generate hosts file with current IP
      cat > /var/run/dnsmasq/skippo.hosts <<EOF
      $TAILSCALE_IP skippo.test
      $TAILSCALE_IP www.skippo.test
      $TAILSCALE_IP cms.skippo.test
      EOF

      # Start dnsmasq
      exec ${pkgs.dnsmasq}/bin/dnsmasq \
        --keep-in-foreground \
        --port=53 \
        --no-daemon \
        --addn-hosts=/var/run/dnsmasq/skippo.hosts \
        --listen-address=0.0.0.0 \
        --server=100.100.100.100 \
        --server=8.8.8.8 \
        --cache-size=1000
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      UserName = "root";
    };
  };

  # Create /etc/resolver/test for .test domains
  system.activationScripts.postActivation.text = ''
    echo "Setting up dnsmasq resolver for .test domains..."
    if [ ! -d /etc/resolver ]; then
      echo "Creating /etc/resolver directory (requires sudo)..."
      sudo mkdir -p /etc/resolver
    fi
    echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null
  '';

  # Add dnsmasq to system packages
  environment.systemPackages = [ pkgs.dnsmasq ];
}