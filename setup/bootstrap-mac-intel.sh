#!/bin/bash
# ============================================================
# macOS Intel x86 快速环境初始化脚本
# 目标：复刻 neov 的开发机环境
# 用法：bash bootstrap-mac-intel.sh
# ============================================================

set -e

HOMEBREW_PREFIX="/usr/local"
GOST_RELAY_URL="relay+wss://admin:Passw0rd@kcn-gost.a2d2.dev:443?path=/ws"
GOST_LISTEN_PORT="1069"
GIT_USER_NAME="imneov"
GIT_USER_EMAIL="i@neov.im"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ─── 1. Homebrew ────────────────────────────────────────────
install_homebrew() {
  log "检查 Homebrew..."
  if command -v brew &>/dev/null; then
    log "Homebrew 已安装，跳过"
    return
  fi
  log "安装 Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
}

# ─── 2. 核心 CLI 工具 ─────────────────────────────────────────
install_brew_tools() {
  log "安装核心 CLI 工具..."
  local tools=(
    git git-lfs
    go
    supervisor
    tmux fzf tree wget curl socat watch
    gh yq jq
    aria2 cloc
    zsh
  )
  for tool in "${tools[@]}"; do
    if brew list "$tool" &>/dev/null 2>&1; then
      warn "$tool 已安装，跳过"
    else
      log "安装 $tool ..."
      brew install "$tool" || warn "$tool 安装失败，继续..."
    fi
  done
}

# ─── 3. zsh + oh-my-zsh + powerlevel10k ──────────────────────
install_zsh_env() {
  log "配置 zsh 环境..."

  # 设置 zsh 为默认 shell
  if [ "$SHELL" != "$(which zsh)" ]; then
    log "切换默认 shell 为 zsh..."
    chsh -s "$(which zsh)"
  fi

  # 安装 oh-my-zsh
  if [ -d "$HOME/.oh-my-zsh" ]; then
    warn "oh-my-zsh 已存在，跳过"
  else
    log "安装 oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # 安装 powerlevel10k 主题
  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ -d "$p10k_dir" ]; then
    warn "powerlevel10k 已存在，跳过"
  else
    log "安装 powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
  fi

  # 安装 zsh 插件
  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
  for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-z; do
    if [ -d "$plugin_dir/$plugin" ]; then
      warn "$plugin 已存在，跳过"
    else
      case $plugin in
        zsh-autosuggestions)
          git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/$plugin" ;;
        zsh-syntax-highlighting)
          git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir/$plugin" ;;
        zsh-z)
          git clone https://github.com/agkozak/zsh-z "$plugin_dir/$plugin" ;;
      esac
    fi
  done

  # 写入 .zshrc
  log "写入 ~/.zshrc..."
  cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-z
)

source $ZSH/oh-my-zsh.sh

# Go
export GOPATH=~/go
export PATH="$PATH:$GOPATH/bin"

# Homebrew (Intel)
eval "$(/usr/local/bin/brew shellenv)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node

# p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRC_EOF

  log ".zshrc 写入完成"
  warn "p10k 主题配置 (~/.p10k.zsh) 需要从原机器手动复制，或运行 'p10k configure' 重新配置"
}

# ─── 4. git 配置 ─────────────────────────────────────────────
configure_git() {
  log "配置 git..."
  git config --global user.name  "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  git config --global core.autocrlf input
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  # 代理指向 gost 本地 SOCKS5（等 gost 启动后生效）
  git config --global http.proxy  "socks5://127.0.0.1:${GOST_LISTEN_PORT}"
  git config --global https.proxy "socks5://127.0.0.1:${GOST_LISTEN_PORT}"
  log "git 配置完成"
}

# ─── 5. 安装 gost ─────────────────────────────────────────────
install_gost() {
  log "安装 gost..."
  if command -v gost &>/dev/null; then
    warn "gost 已安装: $(which gost)，跳过"
    return
  fi
  # 确保 go 可用
  export PATH="$PATH:$HOMEBREW_PREFIX/bin"
  go install github.com/go-gost/gost/v3/cmd/gost@latest
  log "gost 安装完成: $(which gost || echo $HOME/go/bin/gost)"
}

# ─── 6. supervisord 配置 ──────────────────────────────────────
configure_supervisor() {
  log "配置 supervisord + gost 启动项..."

  local supervisor_conf="$HOMEBREW_PREFIX/etc/supervisord.conf"
  local supervisor_d="$HOMEBREW_PREFIX/etc/supervisor.d"
  local gost_bin="$HOME/go/bin/gost"

  # 创建 supervisor.d 目录
  mkdir -p "$supervisor_d"

  # 写入主配置（如果不存在）
  if [ ! -f "$supervisor_conf" ]; then
    log "写入 supervisord.conf..."
    cat > "$supervisor_conf" << SUPCONF_EOF
[unix_http_server]
file=$HOMEBREW_PREFIX/var/run/supervisor.sock

[supervisord]
logfile=$HOMEBREW_PREFIX/var/log/supervisord.log
logfile_maxbytes=50MB
logfile_backups=10
loglevel=info
pidfile=$HOMEBREW_PREFIX/var/run/supervisord.pid
nodaemon=false
minfds=1024
minprocs=200

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix://$HOMEBREW_PREFIX/var/run/supervisor.sock

[include]
files = $HOMEBREW_PREFIX/etc/supervisor.d/*.ini
SUPCONF_EOF
  else
    warn "supervisord.conf 已存在，跳过覆盖"
  fi

  # 写入 gost 启动配置
  log "写入 gost supervisor 配置..."
  cat > "$supervisor_d/gost.ini" << GOST_INI_EOF
[program:proxy-kcn005]
command=$gost_bin -L=:${GOST_LISTEN_PORT} -F='${GOST_RELAY_URL}'
user=$(whoami)
autostart=true
startsecs=5
autorestart=true
startretries=3
redirect_stderr=true
stdout_logfile=$HOMEBREW_PREFIX/var/log/gost.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=20
stderr_logfile=$HOMEBREW_PREFIX/var/log/gost-err.log
stderr_logfile_maxbytes=10MB
GOST_INI_EOF

  log "gost supervisor 配置写入: $supervisor_d/gost.ini"

  # 设置 supervisor 开机自启（brew services）
  log "设置 supervisor 开机自启..."
  brew services start supervisor || warn "supervisor 启动失败，可手动运行: brew services start supervisor"
}

# ─── 7. 启动 gost ─────────────────────────────────────────────
start_gost() {
  log "重载 supervisor 并启动 gost..."
  sleep 2
  supervisorctl reread  2>/dev/null || warn "supervisorctl reread 失败，supervisor 可能还未完全启动"
  supervisorctl update  2>/dev/null || true
  supervisorctl start proxy-kcn005 2>/dev/null || warn "gost 启动失败，请手动执行: supervisorctl start proxy-kcn005"
  supervisorctl status  2>/dev/null || true
}

# ─── 主流程 ──────────────────────────────────────────────────
main() {
  log "=========================================="
  log "  macOS Intel 环境初始化脚本"
  log "  目标：复刻 neov 开发机环境"
  log "=========================================="

  install_homebrew
  install_brew_tools
  install_zsh_env
  configure_git
  install_gost
  configure_supervisor
  start_gost

  log "=========================================="
  log "安装完成！后续手动步骤："
  log ""
  log "1. 复制 p10k 主题配置（在原机上执行）："
  log "   scp ~/.p10k.zsh <新机IP>:~/.p10k.zsh"
  log ""
  log "2. 复制 SSH 密钥（在原机上执行）："
  log "   scp ~/.ssh/id_rsa ~/.ssh/id_rsa.pub <新机IP>:~/.ssh/"
  log "   scp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub <新机IP>:~/.ssh/"
  log "   scp ~/.ssh/config <新机IP>:~/.ssh/"
  log ""
  log "3. 重新打开终端或执行：source ~/.zshrc"
  log ""
  log "4. 验证 gost 状态："
  log "   supervisorctl status"
  log "   curl -x socks5://127.0.0.1:1069 https://www.google.com -I"
  log "=========================================="
}

main "$@"
