#!/bin/bash
set -e

# --------------------------
# Ask for sudo password once
# --------------------------
sudo -v

# --------------------------
# Clean old Neovim / LazyVim
# --------------------------
echo "Cleaning old Neovim and LazyVim..."
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim/lazy
rm -rf ~/.local/share/nvim/site
rm -rf ~/.local/share/nvim/swap
rm -rf ~/.local/share/nvim/backup

# --------------------------
# Install system prerequisites via apt
# --------------------------
echo "Installing prerequisites..."
sudo apt update
sudo apt install -y software-properties-common git curl unzip build-essential jq

# --------------------------
# Install latest Neovim via apt
# --------------------------
echo "Installing Neovim..."
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt update
sudo apt install -y neovim luajit luarocks

# --------------------------
# Setup Neovim configuration
# --------------------------
echo "Setting up Neovim config..."
mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins

cat > ~/.config/nvim/init.lua << 'EOF'
require("config.lazy")
EOF

cat > ~/.config/nvim/lua/config/lazy.lua << 'EOF'
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true, notify = true },
})

vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>f', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>g', ':Telescope live_grep<CR>', { noremap = true, silent = true })
EOF

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

# --------------------------
# Install or update Lazy.nvim dynamically
# --------------------------
echo "Installing or updating Lazy.nvim to the latest release..."
LAZY_PATH="$HOME/.local/share/nvim/lazy/lazy.nvim"
REPO="https://github.com/folke/lazy.nvim.git"

# Fetch latest release tag from GitHub API
latest_tag=$(curl -s https://api.github.com/repos/folke/lazy.nvim/releases/latest | jq -r .tag_name)
echo "Latest Lazy.nvim release: $latest_tag"

if [ -d "$LAZY_PATH" ]; then
    echo "Updating existing Lazy.nvim..."
    git -C "$LAZY_PATH" fetch --tags
    git -C "$LAZY_PATH" checkout "$latest_tag"
    git -C "$LAZY_PATH" pull --ff-only
else
    echo "Cloning Lazy.nvim at latest release..."
    git clone "$REPO" "$LAZY_PATH"
    git -C "$LAZY_PATH" checkout "$latest_tag"
fi

# --------------------------
# Install plugins
# --------------------------
echo "Installing LazyVim plugins..."
if ! nvim --headless +Lazy! +TSUpdateSync +qall; then
    echo "❌ Error occurred during plugin installation"
    exit 1
fi

echo "✅ LazyVim installation complete!"
