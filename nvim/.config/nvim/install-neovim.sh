#!/bin/bash

# Neovim Installation Script
# This script sets up Neovim with all necessary dependencies for your configuration
# Uses pyenv for Python management and nvm for Node.js management
# Compatible with macOS (tested) and Linux
#
# Step 1: chmod x+ install-neovim.sh
# Step 2: ./install-neovim.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Python version to install
PYTHON_VERSION="3.10.12"

# Node.js version to install
NODE_VERSION="lts/*"

# Optional components flags
INSTALL_JAVA=false

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_info "Detected Linux"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ask user about optional components
ask_optional_components() {
    echo
    log_info "Optional components:"
    echo
    read -p "Install Java JDK 17? (required for Java development with JDTLS) [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_JAVA=true
        log_info "Java will be installed"
    else
        log_info "Java installation skipped"
    fi
    echo
}

# Install package managers
install_package_managers() {
    log_info "Setting up package managers..."
    
    if [[ "$OS" == "macos" ]]; then
        # Install Homebrew if not present
        if ! command_exists brew; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for Apple Silicon Macs
            if [[ $(uname -m) == "arm64" ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        else
            log_success "Homebrew already installed"
        fi
        
        # Update Homebrew
        brew update
        
    elif [[ "$OS" == "linux" ]]; then
        # Update package list
        if command_exists apt; then
            sudo apt update
        elif command_exists yum; then
            sudo yum update -y
        elif command_exists dnf; then
            sudo dnf update -y
        elif command_exists pacman; then
            sudo pacman -Sy
        else
            log_error "No supported package manager found (apt, yum, dnf, pacman)"
            exit 1
        fi
    fi
}

# Install build dependencies for Neovim
install_neovim_build_deps() {
    log_info "Installing Neovim build dependencies..."
    
    if [[ "$OS" == "macos" ]]; then
        # Install build dependencies via Homebrew
        brew install ninja cmake gettext curl
    elif [[ "$OS" == "linux" ]]; then
        if command_exists apt; then
            sudo apt install -y ninja-build gettext cmake unzip curl build-essential
        elif command_exists yum; then
            sudo yum install -y ninja-build gettext cmake unzip curl gcc gcc-c++ make
        elif command_exists dnf; then
            sudo dnf install -y ninja-build gettext cmake unzip curl gcc gcc-c++ make
        elif command_exists pacman; then
            sudo pacman -S --noconfirm base-devel cmake unzip ninja curl gettext
        fi
    fi
    
    log_success "Build dependencies installed"
}

# Install Neovim from GitHub source
install_neovim() {
    log_info "Installing Neovim from GitHub source..."
    
    # Create build directory
    mkdir -p ~/build-from-source
    cd ~/build-from-source
    
    # Check if neovim directory already exists
    if [[ -d "neovim" ]]; then
        log_info "Neovim source directory exists, updating..."
        cd neovim
        git fetch --all
        git reset --hard origin/master
        git clean -fd
    else
        log_info "Cloning Neovim from GitHub..."
        git clone https://github.com/neovim/neovim.git
        cd neovim
    fi
    
    # Checkout the latest stable release or master
    log_info "Checking out latest stable release..."
    LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "master")
    if [[ "$LATEST_TAG" != "master" ]]; then
        git checkout "$LATEST_TAG"
        log_info "Building Neovim $LATEST_TAG"
    else
        log_info "Building Neovim from master branch"
    fi
    
    # Clean previous build
    make distclean 2>/dev/null || true
    
    # Build Neovim
    log_info "Building Neovim (this may take a few minutes)..."
    make CMAKE_BUILD_TYPE=Release
    
    # Install Neovim
    log_info "Installing Neovim..."
    if [[ "$OS" == "macos" ]]; then
        # Install to /usr/local for macOS
        sudo make install
    elif [[ "$OS" == "linux" ]]; then
        # Install to /usr/local for Linux
        sudo make install
    fi
    
    # Return to original directory
    cd - > /dev/null
    
    # Verify installation
    if command_exists nvim; then
        local nvim_version=$(nvim --version | head -n1)
        log_success "Neovim installed: $nvim_version"
    else
        log_error "Neovim installation failed"
        exit 1
    fi
}

# Install pyenv
install_pyenv() {
    log_info "Installing pyenv..."
    
    if ! command_exists pyenv; then
        if [[ "$OS" == "macos" ]]; then
            brew install pyenv
            
            # Add pyenv to shell profile
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zprofile
            echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zprofile
            echo 'eval "$(pyenv init --path)"' >> ~/.zprofile
            echo 'eval "$(pyenv init -)"' >> ~/.zshrc
            
            # Install dependencies for building Python
            brew install openssl readline sqlite3 xz zlib tcl-tk
            
        elif [[ "$OS" == "linux" ]]; then
            # Install dependencies
            if command_exists apt; then
                sudo apt install -y make build-essential libssl-dev zlib1g-dev \
                    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
                    libffi-dev liblzma-dev
            elif command_exists yum; then
                sudo yum install -y gcc zlib-devel bzip2 bzip2-devel readline-devel \
                    sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
            elif command_exists dnf; then
                sudo dnf install -y make gcc zlib-devel bzip2 bzip2-devel readline-devel \
                    sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
            elif command_exists pacman; then
                sudo pacman -S --noconfirm base-devel openssl zlib xz tk
            fi
            
            # Install pyenv
            curl https://pyenv.run | bash
            
            # Add pyenv to shell profile
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
            echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
            echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
            echo 'eval "$(pyenv init -)"' >> ~/.bashrc
            
            # Also add to .profile for login shells
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
            echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
            echo 'eval "$(pyenv init --path)"' >> ~/.profile
        fi
        
        # Source the profile to get pyenv in current shell
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
        
        log_success "pyenv installed"
    else
        log_success "pyenv already installed"
    fi
}

# Install Python with pyenv
install_python() {
    log_info "Installing Python $PYTHON_VERSION with pyenv..."
    
    # Check if Python version is already installed
    if ! pyenv versions --bare | grep -q "^$PYTHON_VERSION$"; then
        pyenv install $PYTHON_VERSION
    else
        log_success "Python $PYTHON_VERSION already installed"
    fi
    
    # Set it as global Python version
    pyenv global $PYTHON_VERSION
    
    # Create symlink for python3.10 to match your config
    if [[ ! -f /usr/local/bin/python3.10 ]]; then
        log_info "Creating symlink for python3.10 to match your config..."
        sudo mkdir -p /usr/local/bin
        sudo ln -sf "$HOME/.pyenv/versions/$PYTHON_VERSION/bin/python3" /usr/local/bin/python3.10
    fi
    
    # Ensure pip is up to date
    python -m pip install --upgrade pip
    
    log_success "Python $PYTHON_VERSION installed and set as global"
}

# Install nvm
install_nvm() {
    log_info "Installing nvm (Node Version Manager)..."
    
    if [[ ! -d "$HOME/.nvm" ]]; then
        # Install nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        
        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        log_success "nvm installed"
    else
        log_success "nvm already installed"
        
        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
}

# Install Node.js with nvm
install_nodejs() {
    log_info "Installing Node.js $NODE_VERSION with nvm..."
    
    # Install Node.js LTS
    nvm install $NODE_VERSION
    nvm use $NODE_VERSION
    nvm alias default $NODE_VERSION
    
    log_success "Node.js $(node -v) installed and set as default"
}

# Install Java (optional - required for your Java LSP setup)
install_java() {
    if [[ "$INSTALL_JAVA" == true ]]; then
        log_info "Installing Java JDK..."
        
        if [[ "$OS" == "macos" ]]; then
            brew install openjdk@17
            # Add Java to PATH
            echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zprofile
        elif [[ "$OS" == "linux" ]]; then
            if command_exists apt; then
                sudo apt install -y openjdk-17-jdk
            elif command_exists yum; then
                sudo yum install -y java-17-openjdk-devel
            elif command_exists dnf; then
                sudo dnf install -y java-17-openjdk-devel
            elif command_exists pacman; then
                sudo pacman -S --noconfirm jdk17-openjdk
            fi
        fi
        
        log_success "Java JDK installed"
    else
        log_info "Skipping Java installation"
    fi
}

# Install essential tools
install_essential_tools() {
    log_info "Installing essential development tools..."
    
    if [[ "$OS" == "macos" ]]; then
        brew install git curl wget ripgrep fd tree-sitter
        
        # Install GNU tools (needed for some plugins)
        brew install coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt grep
        
    elif [[ "$OS" == "linux" ]]; then
        if command_exists apt; then
            sudo apt install -y git curl wget ripgrep fd-find build-essential
        elif command_exists yum; then
            sudo yum install -y git curl wget ripgrep fd-find gcc gcc-c++ make
        elif command_exists dnf; then
            sudo dnf install -y git curl wget ripgrep fd-find gcc gcc-c++ make
        elif command_exists pacman; then
            sudo pacman -S --noconfirm git curl wget ripgrep fd base-devel
        fi
    fi
    
    log_success "Essential tools installed"
}

# Install Python Language Server (pylsp)
install_python_lsp() {
    log_info "Installing Python Language Server and related tools..."
    
    # Install python-lsp-server with all optional dependencies
    python -m pip install --user python-lsp-server[all]
    
    # Install additional Python tools mentioned in your config
    python -m pip install --user \
        python-lsp-black \
        python-lsp-isort \
        python-lsp-ruff \
        pylsp-mypy \
        black \
        isort \
        mypy \
        flake8 \
        autopep8 \
        yapf
    
    log_success "Python LSP and tools installed"
}

# Install TypeScript/JavaScript tools
install_js_tools() {
    log_info "Installing TypeScript/JavaScript language server and tools..."
    
    # Install TypeScript Language Server
    npm install -g typescript-language-server typescript
    
    # Install Prettier and ESLint
    npm install -g prettier eslint eslint_d
    
    # Install additional JS/TS tools
    npm install -g @types/node
    
    log_success "JavaScript/TypeScript tools installed"
}

# Install Lua tools
install_lua_tools() {
    log_info "Installing Lua language server and formatter..."
    
    if [[ "$OS" == "macos" ]]; then
        brew install lua-language-server stylua
    elif [[ "$OS" == "linux" ]]; then
        # Install via cargo if available, otherwise manual installation
        if command_exists cargo; then
            cargo install stylua
            # Install lua-language-server manually
            log_warning "lua-language-server needs manual installation on Linux"
            log_info "Download from: https://github.com/LuaLS/lua-language-server/releases"
        else
            log_warning "Please install Rust/Cargo first for Lua tools, or install manually"
        fi
    fi
    
    log_success "Lua tools installation attempted"
}

# Install vim-plug (plugin manager)
install_vim_plug() {
    log_info "Installing vim-plug..."
    
    # Create neovim config directories
    mkdir -p ~/.config/nvim/autoload
    mkdir -p ~/.local/share/nvim/plugged
    
    # Download vim-plug
    curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    
    log_success "vim-plug installed"
}

# Setup dotfiles linking (optional)
setup_dotfiles() {
    log_info "Setting up Neovim configuration..."
    
    DOTFILES_NVIM_PATH="$HOME/dotfiles/nvim/.config/nvim"
    NVIM_CONFIG_PATH="$HOME/.config/nvim"
    
    if [[ -d "$DOTFILES_NVIM_PATH" ]]; then
        log_info "Found dotfiles at $DOTFILES_NVIM_PATH"
        
        # Backup existing config if it exists
        if [[ -d "$NVIM_CONFIG_PATH" ]] && [[ ! -L "$NVIM_CONFIG_PATH" ]]; then
            log_warning "Backing up existing Neovim config to ~/.config/nvim.backup"
            mv "$NVIM_CONFIG_PATH" "$NVIM_CONFIG_PATH.backup"
        fi
        
        # Remove existing symlink if present
        if [[ -L "$NVIM_CONFIG_PATH" ]]; then
            rm "$NVIM_CONFIG_PATH"
        fi
        
        # Create symlink to dotfiles
        ln -sf "$DOTFILES_NVIM_PATH" "$NVIM_CONFIG_PATH"
        log_success "Linked dotfiles to ~/.config/nvim"
    else
        log_warning "Dotfiles not found at expected path: $DOTFILES_NVIM_PATH"
        log_info "You'll need to manually copy your configuration files"
    fi
}

# Install Neovim plugins
install_neovim_plugins() {
    log_info "Installing Neovim plugins..."
    
    # Run PlugInstall in headless mode
    nvim --headless +PlugInstall +qall
    
    # Install TreeSitter parsers
    nvim --headless +'TSInstallSync all' +qall
    
    log_success "Neovim plugins installed"
}

# Configure git to use neovim
configure_git() {
    log_info "Configuring git to use Neovim as editor..."
    git config --global core.editor "nvim"
    log_success "Git configured to use Neovim"
}

# Create Java LSP shell script (only if Java is installed)
create_java_lsp_script() {
    if [[ "$INSTALL_JAVA" == true ]]; then
        log_info "Creating Java Language Server script..."
        
        # Create directory for script
        mkdir -p ~/bin
        
        # Create the script
        cat > ~/bin/java-lsp.sh << 'EOF'
#!/usr/bin/env bash

# java-lsp.sh
# Script to start the Java Language Server (JDTLS)
# This should be referenced in your JDTLS config

# Determine OS
OS=$(uname -s)

# Determine architecture
ARCH=$(uname -m)

# Set the jar name based on OS and architecture
case "$OS" in
    Linux)
        PLATFORM="linux"
        ;;
    Darwin)
        PLATFORM="mac"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        PLATFORM="win"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        ARCH_SUFFIX=""  # Default for x86_64
        ;;
    arm64|aarch64)
        ARCH_SUFFIX="-arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Define the workspace directory from arguments
WORKSPACE="$1"
[ -z "$WORKSPACE" ] && WORKSPACE="$HOME/.workspace"

# Default JDTLS path - adjust this based on your installation
JDTLS_HOME="$HOME/.local/share/eclipse/jdtls"

# Check if JDTLS exists, warn if not
if [ ! -d "$JDTLS_HOME" ]; then
    echo "JDTLS not found at $JDTLS_HOME. Please install it first."
    echo "You can download it from: https://download.eclipse.org/jdtls/snapshots/?d"
    exit 1
fi

# Java executable
JAVA=${JAVA_HOME}/bin/java

# If JAVA_HOME is not set, try to find java
if [ -z "$JAVA" ] || [ ! -x "$JAVA" ]; then
    JAVA=$(which java)
fi

# Config directory
CONFIG="$JDTLS_HOME/config_$PLATFORM"

# Plugin directory
PLUGINS="$JDTLS_HOME/plugins"

# Get the JAR file
JAR=$(find "$PLUGINS" -name "org.eclipse.equinox.launcher_*.jar" | sort | tail -1)

# Set up the JDTLS command
JDTLS_CMD="$JAVA \
  -Declipse.application=org.eclipse.jdt.ls.core.id1 \
  -Dosgi.bundles.defaultStartLevel=4 \
  -Declipse.product=org.eclipse.jdt.ls.core.product \
  -Dlog.protocol=true \
  -Dlog.level=ALL \
  -Xms1g \
  -Xmx2g \
  --add-modules=ALL-SYSTEM \
  --add-opens java.base/java.util=ALL-UNNAMED \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  -jar \"$JAR\" \
  -configuration \"$CONFIG\" \
  -data \"$WORKSPACE\""

# Execute the command
eval "$JDTLS_CMD"
EOF

        # Make it executable
        chmod +x ~/bin/java-lsp.sh
        
        # Add bin directory to PATH if not already there
        if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" ~/.zprofile; then
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zprofile
        fi
        
        log_success "Java LSP script created at ~/bin/java-lsp.sh"
    else
        log_info "Skipping Java LSP script creation (Java not installed)"
    fi
}

# Additional language servers and tools
install_additional_tools() {
    log_info "Installing additional development tools..."
    
    # C/C++ Language Server (ccls - mentioned in your config)
    if [[ "$OS" == "macos" ]]; then
        brew install ccls
    elif [[ "$OS" == "linux" ]]; then
        if command_exists apt; then
            sudo apt install -y ccls
        elif command_exists dnf; then
            sudo dnf install -y ccls
        elif command_exists pacman; then
            sudo pacman -S --noconfirm ccls
        else
            log_warning "ccls installation may need manual setup on your system"
        fi
    fi
    
    # Rust tools (if needed)
    if ! command_exists cargo; then
        log_info "Installing Rust and Cargo..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
    fi
    
    log_success "Additional tools installed"
}

# Check installation
verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    
    # Check Neovim
    if command_exists nvim; then
        log_success "Neovim: $(nvim --version | head -n1)"
    else
        log_error "Neovim not found"
        ((errors++))
    fi
    
    # Check pyenv
    if command_exists pyenv; then
        log_success "pyenv: $(pyenv --version)"
        log_success "Python: $(python --version)"
    else
        log_error "pyenv not found"
        ((errors++))
    fi
    
    # Check nvm
    if [ -d "$HOME/.nvm" ]; then
        log_success "nvm installed at ~/.nvm"
        if command_exists node; then
            log_success "Node.js: $(node --version)"
        else
            log_warning "Node.js not available in current shell"
        fi
    else
        log_error "nvm not found"
        ((errors++))
    fi
    
    # Check Java (if installed)
    if [[ "$INSTALL_JAVA" == true ]]; then
        if command_exists java; then
            log_success "Java: $(java -version 2>&1 | head -n1)"
        else
            log_warning "Java not found in PATH - may need to restart shell"
        fi
    fi
    
    # Check pylsp
    if command_exists pylsp; then
        log_success "Python LSP Server found"
    else
        log_warning "pylsp not found in PATH - may need to restart shell"
    fi
    
    # Check TypeScript Language Server
    if command_exists typescript-language-server; then
        log_success "TypeScript Language Server found"
    else
        log_warning "typescript-language-server not found in PATH - may need to restart shell"
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Installation verification completed successfully!"
    else
        log_warning "Installation completed with $errors warnings/errors"
        log_info "You may need to restart your shell for all changes to take effect"
    fi
}

# Main installation function
main() {
    echo "=========================================="
    echo "       Neovim Setup Script"
    echo "=========================================="
    echo
    
    detect_os
    ask_optional_components
    
    log_info "This script will install:"
    echo "  • Neovim (built from GitHub source)"
    echo "  • pyenv & Python $PYTHON_VERSION"
    echo "  • nvm & Node.js $NODE_VERSION"
    if [[ "$INSTALL_JAVA" == true ]]; then
        echo "  • Java JDK 17"
    fi
    echo "  • Python Language Server (pylsp)"
    echo "  • TypeScript Language Server"
    echo "  • Lua Language Server & Stylua"
    echo "  • C/C++ Language Server (ccls)"
    echo "  • Essential development tools"
    echo "  • All required formatters and linters"
    echo "  • Neovim plugins via vim-plug"
    echo
    
    read -p "Continue with installation? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    # Run installation steps
    install_package_managers
    install_essential_tools
    install_neovim_build_deps
    install_neovim
    
    # Version managers and languages
    install_pyenv
    install_python
    install_nvm
    install_nodejs
    install_java  # This will check the flag internally
    
    # LSP and tools
    install_python_lsp
    install_js_tools
    install_lua_tools
    install_additional_tools
    create_java_lsp_script  # This will check the flag internally
    
    # Neovim setup
    install_vim_plug
    setup_dotfiles
    configure_git
    
    # Install plugins (only if config is available)
    if [[ -f "$HOME/.config/nvim/init.vim" ]]; then
        install_neovim_plugins
    else
        log_warning "Neovim config not found - skipping plugin installation"
        log_info "Run ':PlugInstall' manually after setting up your config"
    fi
    
    verify_installation
    
    echo
    echo "=========================================="
    log_success "Installation completed!"
    echo "=========================================="
    echo
    log_info "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zprofile && source ~/.zshrc"
    echo "2. If you haven't already, copy your Neovim config to ~/.config/nvim/"
    echo "3. Open Neovim and run ':PlugInstall' to install plugins"
    echo "4. Run ':checkhealth' in Neovim to verify everything is working"
    echo "5. Neovim source code is available in ~/build-from-source/neovim for future updates"
    if [[ "$INSTALL_JAVA" == true ]]; then
        echo "5. For Java development, download JDTLS to ~/.local/share/eclipse/jdtls"
        echo "   from: https://download.eclipse.org/jdtls/snapshots/?d"
    fi
    echo
    log_info "Your Python path in init.vim points to: /usr/local/bin/python3.10"
    log_info "Symlink created to: $(which python3) → /usr/local/bin/python3.10"
    echo
    log_success "Happy coding with Neovim! 🚀"
}

# Run main function
main "$@"
