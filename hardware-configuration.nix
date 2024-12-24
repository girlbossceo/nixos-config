# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "ehci_pci"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
    # just in case, but my lsmod said these were loaded anyways
    "aesni_intel"
    "cryptd"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a24c5ca6-aa90-4985-b598-28dd07b5f12e";
      fsType = "ext4";
      options = [
        # asynchronously flushes commit blocks to disk without waiting for descriptor block to be written.
	# improves i/o perf
	#
 	# must use data=writeback or data=journal
	#
	# this will prevent this drive being mounted on ancient kernels.
	"journal_async_commit"
	# highest safety guarantees, and theoretically higher throughput
	"data=writeback"
	# im on a laptop so 5 -> 15 second commit is fine
	"commit=15"
	# forcefully fsync()'s file replacements if not done by the bad application
	"auto_da_alloc"
	# 64-bit inode version support
	"i_version"
	# journal checksumming for e2fsck recovery support
	# internally enabled if using journal_async_commit
	"journal_checksum"
      ];
    };

  fileSystems."/nix/store" =
    { device = "/dev/disk/by-uuid/a24c5ca6-aa90-4985-b598-28dd07b5f12e";
      fsType = "ext4";
      options = [
        # bind mount because this is under / already
        "bind"
	# /nix/store is I/O heavy and doesn't need access times
	"noatime"
	# nix default
	"ro"
        # asynchronously flushes commit blocks to disk without waiting for descriptor block to be written.
	# improves i/o perf
	#
 	# must use data=writeback or data=journal
	#
	# this will prevent this drive being mounted on ancient kernels.
	"journal_async_commit"
	# highest safety guarantees, and theoretically higher throughput
	"data=writeback"
	# im on a laptop so 5 -> 15 second commit is fine
	"commit=15"
	# forcefully fsync()'s file replacements if not done by the bad application
	"auto_da_alloc"
	# 64-bit inode version support
	"i_version"
	# journal checksumming for e2fsck recovery support
	# internally enabled if using journal_async_commit
	"journal_checksum"
      ];
    };

  boot.initrd.luks.devices."luks-9cff8e4d-0e9e-48a4-8dd4-1b48f68c2e19" = {
    device = "/dev/disk/by-uuid/9cff8e4d-0e9e-48a4-8dd4-1b48f68c2e19";

    # work queues dont make sense for fast hardware like SSDs, plus these
    # are sync/blocking ops in linux which introduces kernel-thread deadlocks
    # under extreme I/O load.
    #
    # check if this applies using luksDump after reboot. idk why this config option didnt work for me.
    # sudo cryptsetup --perf-no_read_workqueue --perf-no_write_workqueue --allow-discards --persistent refresh luks-9cff8e4d-0e9e-48a4-8dd4-1b48f68c2e19
    bypassWorkqueues = true;

    # allow SSD TRIM ops; warning that this leaks metadata. this *may* expose FS-level ops
    # on the physical SSD controller such as formatted FS type, amount of space used, etc.
    # which *can* be of concern regarding forensics
    allowDiscards = true;
  };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/24C8-CDA5";
      fsType = "vfat";
      options = [
        # /boot doesn't need any of this
        "noexec"
	"nosuid"
	"nodev"

        # /boot doesnt need access times
	"noatime"

        # /boot is just used by root
	"umask=0077"
	"fmask=0077"
	"dmask=0077"
      ];
    };

  swapDevices = [{
    device = "/dev/disk/by-partuuid/fc7bf131-5531-4673-a033-43bc892234e5";
    # on modern linux >=5.6; urandom and random both use CSPRNGs, but random will wait/block
    # for CSPRNG init. urandom will try to init at the time of use.
    # beyond that, they both behave the same and just better atp to use random. ancient
    # advice to use urandom for everything.
    #
    # <https://lore.kernel.org/lkml/20200131204924.GA455123@mit.edu/>
    randomEncryption.source = "/dev/random";

    randomEncryption.enable = true; 

    # nvme id-ns -H /dev/nvme0n1 | grep 'LBA Format'
    #
    # if you support more than 512 sector size and are currently not using it,
    # then reinstall nixos and go through: <https://wiki.archlinux.org/title/Advanced_Format#NVMe_solid_state_drives>
    # then change this to your new sector size
    randomEncryption.sectorSize = 512;

    # 512 instead of 256 default key size (for aes-xts-plain64) can't hurt
    randomEncryption.keySize = 512;

    # allow SSD TRIM ops; warning that this leaks metadata. this *may* expose FS-level ops
    # on the physical SSD controller such as formatted FS type, amount of space used, etc.
    # which *can* be of concern regarding forensics
    randomEncryption.allowDiscards = true;
  }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0f0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp4s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  # i want all my firmware and microcode pls
  hardware.enableAllFirmware = true;

  # i kinda question if this works because i don't see amd-ucode in /boot, but
  # even nixos-hardware uses this so........
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
