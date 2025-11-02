#!/bin/bash

set -e

echo "Detecting Linux distribution..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect Linux distribution."
    exit 1
fi
echo "Detected distro: $DISTRO"

install_neovim_ubuntu() {
    echo "Installing prerequisites..."
    sudo apt update
    sudo apt install -y software-properties-common curl git unzip build-essential

    echo "Adding Neovim unstable PPA..."
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt update
    sudo apt install -y neovim luajit luarocks
}

install_neovim_fedora() {
    echo "Installing prerequisites..."
    sudo dnf install -y git curl unzip luajit luarocks

    echo "Installing Neovim..."
    sudo dnf install -y neovim
}

install_neovim_arch() {
    echo "Updating packages..."
    sudo pacman -Sy --noconfirm
    echo "Installing Neovim and Lua..."
    sudo pacman -S --noconfirm neovim luajit luarocks git unzip base-devel
}

case "$DISTRO" in
    ubuntu|debian)
        install_neovim_ubuntu
        ;;
    fedora)
        install_neovim_fedora
        ;;
    arch)
        install_neovim_arch
        ;;
    *)
        echo "Unsupported Linux distribution: $DISTRO"
        exit 1
        ;;
esac

# 3. Setup Neovim config directories
echo "Setting up Neovim configuration..."
mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins

# 4. Write init.lua
cat > ~/.config/nvim/init.lua << 'EOF'
require("config.lazy")
EOF

# 5. Write lua/config/lazy.lua
cat > ~/.config/nvim/lua/config/lazy.lua << 'EOF'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Set leader keys before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})

-- Leader key shortcuts
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>f', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>g', ':Telescope live_grep<CR>', { noremap = true, silent = true })
EOF

# 6. Write lua/plugins/init.lua
cat > ~/.config/nvim/lua/plugins/init.lua << 'EOF'
return {
  { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        sort_by = "name",
        view = { width = 30, side = "left" },
        renderer = { icons = { show = { git = true, folder = true, file = true } } },
      })
    end,
  },
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "nvim-tree/nvim-web-devicons" },
}
EOF

# 7. Install plugins and Treesitter parsers headlessly
echo "Installing Neovim plugins and Treesitter parsers..."
nvim --headless +Lazy! +TSUpdateSync +qall

echo "✅ LazyVim installation complete! Open Neovim with 'nvim'."
