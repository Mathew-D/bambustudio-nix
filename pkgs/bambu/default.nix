{ pkgs, lib }:

let
  pname = "bambustudio";
  version = "2.9.1";

  src = pkgs.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v02.09.01.70/BambuStudio_ubu24-v02.09.01.70-20261103183404.AppImage";
    hash = "sha256-Zo2rsb5Tx1gYnta8iZNShd6l4K9GIWVGsbr9aILpr/A=";
  };

  appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
  caBundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  appimage = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: with pkgs; [
      webkitgtk_4_1
      glib-networking
      openssl
    ];

    extraInstallCommands = ''
      install -Dm644 ${appimageContents}/BambuStudio.png \
        $out/share/pixmaps/BambuStudio.png
      install -Dm644 ${appimageContents}/BambuStudio.desktop \
        $out/share/applications/BambuStudio.desktop
      substituteInPlace $out/share/applications/BambuStudio.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=bambustudio'
    '';

    meta = with lib; {
      description = "PC Software for BambuLab and other 3D printers";
      homepage = "https://github.com/bambulab/BambuStudio";
      license = licenses.agpl3Only;
      mainProgram = "bambustudio";
      platforms = [ "x86_64-linux" ];
    };
  };
in

pkgs.symlinkJoin {
  name = "${pname}-${version}";
  paths = [ appimage ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/bambustudio \
      --set SSL_CERT_FILE "${caBundle}" \
      --set CURL_CA_BUNDLE "${caBundle}" \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
        --prefix GIO_EXTRA_MODULES : "${pkgs.glib-networking}/lib/gio/modules" \
        --set GDK_PIXBUF_MODULE_FILE "${pkgs.gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
  '';
  meta = appimage.meta;
}
