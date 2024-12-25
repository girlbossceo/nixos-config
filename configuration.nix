# vim:tabstop=2:shiftwidth=2

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# To rebuild/apply changes, run `sudo nixos-rebuild switch --flake .`
# To update, run `nix flake update`

{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "strawberry"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # none of the nixos default NTP servers support NTS, so overriding them all is intended
  # also this list is pretty arbitrary, but it's from a random selection of servers at
  # <https://github.com/jauderho/nts-servers>
  #
  # also i use minsources 3 to validate the time using 3 servers/sources, so i'd like at
  # least double the servers just in case i have 2 bad ones.
  networking.timeServers = [
    "ntppool1.time.nl"
    "nts.netnod.se"
    "ptbtime1.ptb.de"
    "ohio.time.system76.com"
    "time.txryan.com"
    "time.dfm.dk"
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  # services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.tailscale.enable = true;
  # disable MagicDNS
  services.tailscale.extraUpFlags = [ "--accept-dns=false" ];

  services.nextdns.enable = true;
  services.nextdns.arguments = [
    "-cache-size=20MB"
    "-profile=6ae877"
  ];
  services.fwupd.enable = true;
  services.fstrim.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # use chronyd for time instead of systemd-timesyncd because of NTS support for
  # fully authenticated and encrypted time synchronisation, unlike NTP.
  services.chrony = {
    enable = true;
    enableNTS = true;
    # reduces latency caused by memory fragmentation
    enableMemoryLocking = true;

    extraFlags = [
      # enables the highest level of the built-in syscall filter on chronyd for security
      "-F1"
    ];

    extraConfig = ''
      # <https://www.cisco.com/c/en/us/td/docs/switches/datacenter/nexus1000/sw/4_0/qos/configuration/guide/nexus1000v_qos/qos_6dscp_val.pdf>
      # <https://wikipedia.org/wiki/Differentiated_services>
      #
      # Service class: 46 == EF (Expedited Forwarding / High Priority, Low Latency)
      dscp 46

      # disables listening on a control/cmd port for chronyc, because i dont use it
      cmdport 0

      # disables bypassing certificate time checks. requires having a functioning RTC.
      nocerttimecheck 0

      # enforce/require time requests to be authenticated aka use NTS only and disallow plaintext NTP,
      # and disallow all fallback to plaintext NTP.
      authselectmode require

      # requires at least 3 servers/sources provide us with a valid time before trusting/applying it
      #
      # when using NTS; this greatly reduces risk of malicious time-based attacks such as being
      # fed wrong/bad timestamps to bypass certificate expiry, clock skew fingerprinting, etc
      minsources 3
    '';
  };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  # bluetooth audio improvements; i have sony xm4s
  services.pipewire.wireplumber.extraConfig.bluetoothEnhancements = {
    "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
    };
  };


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.adm-clementine = {
    isNormalUser = true;
    description = "June Clementine Strawberry";
    extraGroups = [ "networkmanager" "wheel" "audio" "adbusers" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
    shell = pkgs.zsh;
  };

  environment.sessionVariables = rec {
    RUSTC_WRAPPER = "sccache";
    SCCACHE_BUCKET = "sccache";
    SCCACHE_REGION = "garage";
    SCCACHE_ENDPOINT = "https://sccache.s3.garage.kennel.girlcock.ceo";
    SCCACHE_ALLOW_CORE_DUMPS = "true";
    SCCACHE_S3_USE_SSL = "true";
    SCCACHE_CACHE_MULTIARCH = "true";
    SCCACHE_LOG = "warn";
    AWS_DEFAULT_REGION = "garage";
    AWS_ENDPOINT_URL = "https://s3.garage.kennel.girlcock.ceo";
    ATTIC_ENDPOINT = "https://attic.kennel.juneis.dog/conduwuit";

    # TODO: how to add these in here safely for committing to git
    #AWS_ACCESS_KEY_ID = "";
    #AWS_SECRET_ACCESS_KEY= "";
    #ATTIC_TOKEN = "";

    GOPATH = "$HOME/go";
    LIBCLANG_PATH = "${pkgs.llvmPackages_19.libclang.lib}/lib";

    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    # not official
    XDG_BIN_HOME = "$HOME/.local/bin";
    PATH = [
      "${GOPATH}/bin"
      "${XDG_BIN_HOME}"
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # fuck
  programs.thefuck.enable = true;

  programs.kdeconnect.enable = true;

  programs.git.enable = true;
  programs.git.lfs.enable = true;
  programs.git.prompt.enable = true;
  programs.git.config = [
    {
      init = { defaultBranch = "main"; };
      url = {
        "https://github.com/" = {
          insteadOf = [ "gh:" "github:" ];
        };
      };
      global = { gpgsign = true; };
      user = {
        name = "June Clementine Strawberry";
        email = "strawberry@puppygock.gay";
        signingkey = "~/.ssh/id_ed25519";
      };
      core = { compression = 9; };
      alias = {
        # i use this for conduwuit so i can push to all my mirrors easily
        pushall = "!git remote | grep -E 'origin' | xargs -L1 -P 0 git push";
        fetchall = "!git remote | grep -E 'origin' | xargs -L1 -P 0 git fetch";
      };

      # no meme gpg pls
      gpg.format = "ssh";
    }
  ];

  programs.adb.enable = true;

  # appimage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow insecure libolm, used by gomuks
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      twitter-color-emoji
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      corefonts

      # woozy
      monocraft
    ];
  };

  nix = {
    # awa
    package = pkgs.lix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = [
        "https://attic.kennel.juneis.dog/conduwuit"
        "https://nix-community.cachix.org"
        "https://aseipp-nix-cache.freetls.fastly.net"
        "https://conduwuit.cachix.org"
        "https://cache.lix.systems/"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        "conduwuit:BbycGUgTISsltcmH0qNjFR9dbrQNYgdIAcmViSGoVTE="
        "conduwuit.cachix.org-1:MFRm6jcnfTf0jSAbmvLfhO3KBMt4px+1xaereWXp8Xg="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    p7zip
    moreutils
    git
    pv
    htop
    nvme-cli
    smartmontools
    vscode
    go
    neovim
    wget
    curl
    zip
    unzip
    signal-desktop
    spotify
    kitty
    kitty-img
    bitwarden-desktop
    bitwarden-cli
    ktailctl
    nodejs_22
    corepack_22
    thunderbird
    vesktop
    hyfetch
    fastfetch
    nextdns
    microcode-amd
    nix-output-monitor
    nix-fast-build
    real_time_config_quick_scan
    sccache
    qbittorrent-enhanced
    cargo-mommy # awoozy
    bison
    flex
    fontforge
    makeWrapper
    pkg-config
    pkgconf
    libpkgconf
    liburing
    gcc14
    gcc14Stdenv
    libgcc
    libiconv
    clang_19
    binutils
    llvmPackages_19.libcxxClang
    llvmPackages_19.libllvm
    llvmPackages_19.stdenv
    llvmPackages_19.libcxx
    llvmPackages_19.libcxxStdenv
    llvmPackages_19.compiler-rt
    llvmPackages_19.clangUseLLVM
    autoconf
    automake
    libtool
    gnumake
    awscli2
    slack
    slackdump
    killall
    jq
    bitwarden-cli
    ffmpeg-full
    olm
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    vteIntegration = true;
    histSize = 10000;

    shellAliases = {
      lix = "nix";
      grep = "grep --color=auto";
      ssh = "kitten ssh";
      neofetch = "hyfetch";
      cargo = "cargo-mommy"; # awoozy
    };

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "thefuck" "command-not-found" ];
      theme = "alanpeabody";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # enable nix-ld so random binaries are more likely to work
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # put libraries needed by random binaries you download here
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon. because sometimes i like to ssh from my mac/desktop.
  services.openssh = {
    enable = true;

    # we only accept ed25519 connections, so only make ed25519 hostkey
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    settings = {
      # <https://wiki.osuosl.org/howtos/ssh_ip_qos_fix.html>
      # <https://wikipedia.org/wiki/Differentiated_services>
      #
      # Service class: af21 Low-latency data , af11 High-throughput data
      IPQoS = "af21 af11";

      # we only accept modern, ed25519 key, and ChaCha20/AES-256-GCM connections
      # also AES-GCM and ChaCha20 are already inherently authenticated
      Macs = [ "-*" ];
      KexAlgorithms = [ "sntrup761x25519-sha512@openssh.com" "curve25519-sha256" ];
      PubkeyAcceptedKeyTypes = "ssh-ed25519,sk-ssh-ed25519@openssh.com";
      Ciphers = [ "chacha20-poly1305@openssh.com" "aes256-gcm@openssh.com" ];

      PasswordAuthentication = false;
      PermitEmptyPasswords = false;
      AllowUsers = [ "adm-clementine" ];
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  nix.settings.allowed-users = [ "@wheel" ];
  security.sudo.execWheelOnly = true;

  services.udev.packages = [ pkgs.android-udev-rules ];

  # when can we get a realtime-privileges package in nixos so i aint gotta do allat
  security.pam.loginLimits = [
    { domain = "@users"; item = "rtprio" ; type = "-"   ; value = "1"        ; }
    { domain = "@audio"; item = "memlock"; type = "-"   ; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio" ; type = "-"   ; value = "99"       ; }
    { domain = "@audio"; item = "nofile" ; type = "soft"; value = "99999999" ; }
    { domain = "@audio"; item = "nofile" ; type = "hard"; value = "99999999" ; }
  ];
  services.udev.extraRules = ''
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
