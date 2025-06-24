# admin_menu.sh

**admin_menu.sh** é um script interativo em Bash que fornece um menu simples e eficiente para auxiliar na administração de servidores Linux com serviços como **Exim**, **ProFTPD**, **CSF/LFD** e **cPanel/WHM**.

Ideal para sysadmins que querem economizar tempo com tarefas repetitivas e aumentar a produtividade em ambientes de hospedagem web.

---

## 🧰 Funcionalidades incluídas

- 📄 Visualização rápida de logs:
  - Exim (`exim_mainlog`)
  - ProFTPD
  - CSF (LFD)

- ⚙️ Reinício de serviços:
  - Exim
  - ProFTPD
  - CSF

- 📝 Edição de arquivos críticos:
  - `/etc/csf/csf.deny`
  - `/etc/proftpd.conf`

- 📬 Fila de e-mails:
  - Listagem da fila do Exim
  - Descongelamento automático de mensagens frozen

- 📊 Status de serviços

- ⬆️ Atualização automática do próprio script via `curl` (você define a URL no topo do script)

---

## 📦 Instalação

```bash
curl -o admin_menu.sh https://raw.githubusercontent.com/guilhermepachecod/sysadmin/main/admin_menu.sh
chmod +x admin_menu.sh
./admin_menu.sh
