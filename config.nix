{
  allowUnfree = true;


  packageOverrides = pkgs_: with pkgs_; {  # pkgs_ is the original set of packages
    all = with pkgs; buildEnv {  # pkgs is your overriden set of packages itself
      name = "all";
      paths = [
         wget
         gitFull
         tig
         firefox
         thunderbird
         chromium
         qjackctl
         samba
         kate
         htop
         vscode
         elixir
         jack2Full
         bitwig-studio
         patchelf
         cairo
         freetype
         arduino
         filezilla
         kdeApplications.kio-extras
         seafile-client
         libreoffice
         gparted
         openvpn
         docker
         docker_compose
         calibre
         kcalc
         redshift-plasma-applet
         mc
         powertop
         unzip
         lmms
         firmwareLinuxNonfree
         gimp
         alsaUtils
         sweethome3d.application
      ];
    };
  };
}
