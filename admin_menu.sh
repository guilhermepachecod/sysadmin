#!/bin/bash

# Caminhos e configurações
SCRIPT_URL="https://github.com/guilhermepachecod/sysadmin/admin_menu.sh" 
SCRIPT_PATH="$(realpath "$0")"
DEPENDENCIAS=(systemctl exim proftpd csf curl)

# Cores
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Este script precisa ser executado como root.${RESET}"
  exit 1
fi

# Verificar dependências
FALTANDO=()
for cmd in "${DEPENDENCIAS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    FALTANDO+=("$cmd")
  fi
done

if [ "${#FALTANDO[@]}" -ne 0 ]; then
  echo -e "${RED}Faltam as seguintes dependências para o script funcionar:${RESET}"
  for item in "${FALTANDO[@]}"; do
    echo "- $item"
  done
  echo -e "\nInstale os pacotes acima e execute o script novamente."
  exit 1
fi

# Caminhos padrão de logs e arquivos
CSF_DENY="/etc/csf/csf.deny"
EXIM_LOG="/var/log/exim_mainlog"
PROFTPD_LOG="/var/log/proftpd/proftpd.log"
CSF_LOG="/var/log/lfd.log"
PROFTPD_CONF="/etc/proftpd.conf"
CPANEL_UPDATE="/scripts/upcp"

# Funções

view_logs() {
  echo -e "${GREEN}1) Exim mainlog\n2) ProFTPD log\n3) CSF LFD log${RESET}"
  read -p "Escolha qual log deseja seguir [1-3]: " opt
  case $opt in
    1) tail -f "$EXIM_LOG" ;;
    2) tail -f "$PROFTPD_LOG" ;;
    3) tail -f "$CSF_LOG" ;;
    *) echo -e "${RED}Opção inválida.${RESET}" ;;
  esac
}

edit_files() {
  echo -e "${GREEN}1) csf.deny\n2) proftpd.conf${RESET}"
  read -p "Qual arquivo deseja editar? [1-2]: " opt
  case $opt in
    1) nano "$CSF_DENY" ;;
    2) nano "$PROFTPD_CONF" ;;
    *) echo -e "${RED}Opção inválida.${RESET}" ;;
  esac
}

restart_services() {
  echo -e "${GREEN}1) Exim\n2) ProFTPD\n3) CSF${RESET}"
  read -p "Qual serviço deseja reiniciar? [1-3]: " opt
  case $opt in
    1) systemctl restart exim ;;
    2) systemctl restart proftpd ;;
    3) csf -r ;;
    *) echo -e "${RED}Opção inválida.${RESET}" ;;
  esac
}

unfreeze_exim_queue() {
  echo -e "${YELLOW}Descongelando mensagens congeladas...${RESET}"
  for msgid in $(exim -bp | awk '/frozen/{print $3}'); do
    exim -M -unfreeze "$msgid"
  done
  echo -e "${GREEN}Mensagens descongeladas.${RESET}"
}

show_exim_queue() {
  echo -e "${GREEN}Fila atual:${RESET}"
  exim -bp
}

check_services_status() {
  echo -e "${GREEN}Status do Exim:${RESET}"
  systemctl status exim --no-pager
  echo -e "\n${GREEN}Status do ProFTPD:${RESET}"
  systemctl status proftpd --no-pager
  echo -e "\n${GREEN}Status do CSF:${RESET}"
  csf -v
}

update_cpanel() {
  echo -e "${YELLOW}Atualizando cPanel...${RESET}"
  $CPANEL_UPDATE --force
}

update_self() {
  echo -e "${YELLOW}Atualizando script a partir de: $SCRIPT_URL${RESET}"
  TMP_FILE=$(mktemp)

  if curl -fsSL "$SCRIPT_URL" -o "$TMP_FILE"; then
    echo "Backup do script atual em $
