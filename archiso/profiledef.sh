#!/usr/bin/env bash

iso_name="robinos"
iso_label="ROBINOS_$(date +%Y%m)"
iso_publisher="RobinOS <https://example.invalid/robinos>"
iso_application="RobinOS Security Learning Live ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="robinos"
buildmodes=("iso")
bootmodes=("bios.syslinux.mbr" "bios.syslinux.eltorito" "uefi-ia32.grub.esp" "uefi-x64.grub.esp")
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=("-comp" "xz" "-Xbcj" "x86" "-b" "1M" "-Xdict-size" "1M")
file_permissions=(
  ["/root"]="0:0:750"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/robinctl"]="0:0:755"
  ["/usr/local/bin/robin-install"]="0:0:755"
  ["/opt/robinos/bin/robinctl"]="0:0:755"
  ["/opt/robinos/scripts/build-iso.sh"]="0:0:755"
  ["/opt/robinos/scripts/check-arch-packages.sh"]="0:0:755"
  ["/opt/robinos/scripts/clean-build.sh"]="0:0:755"
  ["/opt/robinos/scripts/customize-iso-boot.sh"]="0:0:755"
  ["/opt/robinos/scripts/install-branding.sh"]="0:0:755"
  ["/opt/robinos/scripts/install-robinctl.sh"]="0:0:755"
  ["/opt/robinos/scripts/post-install.sh"]="0:0:755"
  ["/opt/robinos/scripts/prepare-archiso.sh"]="0:0:755"
  ["/opt/robinos/scripts/sync-archiso-files.sh"]="0:0:755"
)
