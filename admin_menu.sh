#!/bin/bash

SCRIPT_URL="https://raw.githubusercontent.com/guilhermepachecod/sysadmin/main/admin_menu.sh"
SCRIPT_PATH="$(realpath "$0")"
DEPENDENCIAS=(systemctl exim proftpd csf curl)

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Este script precisa ser executado como root.${RESET}"
  exit 1
fi

FALTANDO=()
for cmd in "${DEPENDENCIAS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    FALTANDO+=("$cmd")
  fi
done

if [ "${#FALTANDO[@]}" -ne 0 ]; then
  echo -e "${RED}Faltam as seguintes dependências:${RESET}"
  for item in "${FALTANDO[@]}"; do
    echo "- $item"
  done
  exit 1
fi

CSF_DENY="/etc/csf/csf.deny"
EXIM_LOG="/var/log/exim_mainlog"
PROFTPD_LOG="/var/log/proftpd/proftpd.log"
CSF_LOG="/var/log/lfd.log"
PROFTPD_CONF="/etc/proftpd.conf"
CPANEL_UPDATE="/scripts/upcp"

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
    echo "Backup do script atual em ${SCRIPT_PATH}.bak"
    cp "$SCRIPT_PATH" "${SCRIPT_PATH}.bak"
    mv "$TMP_FILE" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}Atualização concluída! Reinicie o script para aplicar as mudanças.${RESET}"
  else
    echo -e "${RED}Erro ao baixar o script. Verifique o link ou a conexão.${RESET}"
    rm -f "$TMP_FILE"
  fi
}

while true; do
  clear
  echo -e "${GREEN}=== MENU DE ADMINISTRAÇÃO DO SERVIDOR ===${RESET}"
  echo "1) Visualizar logs"
  echo "2) Editar arquivos de configuração"
  echo "3) Reiniciar serviços"
  echo "4) Descongelar fila do Exim"
  echo "5) Ver fila de e-mails do Exim"
  echo "6) Ver status de serviços"
  echo "7) Atualizar cPanel"
  echo "8) Atualizar este script via internet"
  echo "0) Sair"
  echo "---------------------------------------"
  read -p "Escolha uma opção: " CHOICE

  case $CHOICE in
    1) view_logs ;;
    2) edit_files ;;
    3) restart_services ;;
    4) unfreeze_exim_queue ;;
    5) show_exim_queue ;;
    6) check_services_status ;;
    7) update_cpanel ;;
    8) update_self ;;
    0) echo "Saindo..."; break ;;
    *) echo -e "${RED}Opção inválida!${RESET}"; sleep 2 ;;
  esac

  echo -e "\nPressione ENTER para voltar ao menu..."
  read
done
