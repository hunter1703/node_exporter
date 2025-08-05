#!/bin/bash

set -e

ENV_FILE=".env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH="$SCRIPT_DIR/$ENV_FILE"
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

echo "=== Monitoring Environment Setup ==="

echo "Detected OS: $OS"
echo "Detected Architecture: $ARCH"

case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Check for previous .env config
if [ -f "$ENV_PATH" ]; then
    echo "Found existing config at $ENV_PATH"
    read -p "Reuse existing config? [Y/n]: " reuse
    reuse=${reuse:-Y}
    if [[ "$reuse" =~ ^[Yy]$ ]]; then
        echo "Reusing existing config."
        exit 0
    else
        echo "Overwriting existing config."
    fi
fi

# Ask for base directory
read -p "Enter path to monitoring base directory (relative to \$HOME) [monitoring]: " base_rel
base_rel=${base_rel:-monitoring}
base_dir="$HOME/$base_rel"

if [ ! -d "$base_dir" ]; then
    echo "⚠️  '$base_dir' does not exist. Creating it..."
    mkdir -p "$base_dir" || { echo "❌ Failed to create directory."; exit 1; }
fi

# Ask for log directory
if [[ "$OS" == "darwin" ]]; then
    # macOS: strip $HOME/ prefix manually
    if [[ "$base_dir" == "$HOME" ]]; then
        default_log_rel="monitoring/logs"
    else
        default_log_rel="${base_dir#$HOME/}/logs"
    fi
else
    # Linux: use GNU realpath
    default_log_rel="$(realpath --relative-to="$HOME" "$base_dir")/logs"
fi

# Prompt for log dir
read -p "Enter path to log directory (relative to \$HOME) [${default_log_rel}]: " log_rel
log_rel=${log_rel:-$default_log_rel}
log_dir="$HOME/$log_rel"

mkdir -p "$log_dir" || { echo "❌ Failed to create log directory."; exit 1; }

# Save config
cat > "$ENV_PATH" <<EOF
# Auto-generated environment config
MONITORING_BASE_DIR="$base_dir"
MONITORING_LOG_DIR="$log_dir"
EOF

echo "✅ Saved environment configuration to $ENV_PATH"

# Download helper function
download_and_extract() {
    local name=$1
    local url=$2
    local dest_dir="$base_dir/$name"

    echo "📦 Downloading $name from:"
    echo "$url"

    tmp_file=$(mktemp)
    curl -sL "$url" -o "$tmp_file"
    mkdir -p "$dest_dir"
    tar -xzf "$tmp_file" -C "$base_dir"
    extracted_dir=$(tar -tzf "$tmp_file" | head -1 | cut -f1 -d"/")
    mv "$base_dir/$extracted_dir"/* "$dest_dir"
    rm -rf "$base_dir/$extracted_dir" "$tmp_file"

    echo "✅ Installed $name to $dest_dir"
}

default_exporter_rel="../build/$OS"
default_exporter_path="$(realpath "$default_exporter_rel")"

read -p "Enter path to node_exporter binary folder (relative to \$HOME) [${default_exporter_path#$HOME}]: " exporter_rel
exporter_rel=${exporter_rel:-$default_exporter_rel}
exporter_dir="./$exporter_rel"
cp $exporter_dir/node_exporter $base_dir/
echo "✅ Copied node_exporter binary from $exporter_dir to $base_dir"

if [ -d "$base_dir/prometheus" ]; then
  echo "⚠️  Prometheus already exists at $base_dir/prometheus — skipping download."
else
  read -p "Download and install latest Prometheus? [Y/n]: " prom_choice
  prom_choice=${prom_choice:-Y}
  if [[ "$prom_choice" =~ ^[Yy]$ ]]; then
    prom_version=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep tag_name | cut -d '"' -f4)
    prom_url="https://github.com/prometheus/prometheus/releases/download/${prom_version}/prometheus-${prom_version:1}.${OS}-${ARCH}.tar.gz"
    download_and_extract "prometheus" "$prom_url"
  fi
fi

# === Copy prometheus.yml template if it doesn't exist ===
PROMETHEUS_CONF_SRC="$SCRIPT_DIR/prometheus.yml"
PROMETHEUS_CONF_DEST="$base_dir/prometheus/prometheus.yml"

if [ -f "$PROMETHEUS_CONF_SRC" ]; then
    mkdir -p "$base_dir/prometheus"
    cp "$PROMETHEUS_CONF_SRC" "$PROMETHEUS_CONF_DEST"
    echo "✅ Copied prometheus.yml to $PROMETHEUS_CONF_DEST"
else
    echo "⚠️  prometheus.yml template not found at $PROMETHEUS_CONF_SRC — skipping."
fi

# Only install Grafana via brew if on macOS and not already installed
if [[ "$OS" == "darwin" ]]; then
    if ! command -v grafana-server >/dev/null 2>&1; then
        echo "📦 Installing Grafana using Homebrew..."
        if command -v brew >/dev/null 2>&1; then
            brew install grafana
            echo "✅ Grafana installed via Homebrew."
        else
            echo "❌ Homebrew is not installed. Please install Homebrew first."
            exit 1
        fi
    else
        echo "ℹ️  Grafana already installed via Homebrew — skipping."
    fi
else
  if [ -d "$base_dir/grafana" ]; then
    echo "⚠️  Grafana already exists at $base_dir/grafana — skipping download."
  else
    read -p "Download and install latest Grafana OSS? [Y/n]: " graf_choice
    graf_choice=${graf_choice:-Y}
    if [[ "$graf_choice" =~ ^[Yy]$ ]]; then
        graf_url="https://dl.grafana.com/oss/release/grafana-latest.linux-${ARCH}.tar.gz"
        download_and_extract "grafana" "$graf_url"
    fi
  fi
fi

echo "📁 Copying startup scripts to $base_dir/scripts..."

mkdir -p "$base_dir/scripts"

for script_name in start.sh stop.sh prometheus_start.sh grafana_start.sh node_exporter_start.sh; do
    src_path="$SCRIPT_DIR/$script_name"
    dest_path="$base_dir/scripts/$script_name"

    if [ -f "$src_path" ]; then
        cp "$src_path" "$dest_path"
        chmod +x "$dest_path"
        echo "✅ Copied $script_name"
    else
        echo "⚠️  $script_name not found in $SCRIPT_DIR — skipped."
    fi
done

# Determine shell config file
if [[ "$SHELL" =~ "zsh" ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

ENV_LINE="source \"$ENV_PATH\""

# Append only if not already present (anywhere in the file)
if ! grep -Fq "$ENV_LINE" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# Monitoring setup environment" >> "$SHELL_RC"
    echo "$ENV_LINE" >> "$SHELL_RC"
    echo "✅ Added '$ENV_LINE' to $SHELL_RC"
else
    echo "ℹ️  '$ENV_LINE' already present in $SHELL_RC — skipping."
fi

ALIAS_START="alias start_monitoring=\"$base_dir/scripts/start.sh\""
ALIAS_STOP="alias stop_monitoring=\"$base_dir/scripts/stop.sh\""

# Check and add start_monitoring alias
if ! grep -Fq "$ALIAS_START" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# Monitoring aliases" >> "$SHELL_RC"
    echo "$ALIAS_START" >> "$SHELL_RC"
    echo "✅ Added start_monitoring alias to $SHELL_RC"
else
    echo "ℹ️  start_monitoring alias already present in $SHELL_RC"
fi

# Check and add stop_monitoring alias
if ! grep -Fq "$ALIAS_STOP" "$SHELL_RC"; then
    echo "$ALIAS_STOP" >> "$SHELL_RC"
    echo "✅ Added stop_monitoring alias to $SHELL_RC"
else
    echo "ℹ️  stop_monitoring alias already present in $SHELL_RC"
fi

cp "$ENV_PATH" "$base_dir/.env"
echo "✅ Copied .env to $base_dir/.env"
echo "🎉 Setup complete. You can now run your monitoring scripts."