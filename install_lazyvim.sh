#!/bin/bash
set -e

# --------------------------
# Ask for sudo password once
# --------------------------
sudo -v
# Keep-alive: update sudo timestamp until script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --------------------------
# Clean old Neovim / LazyVim
# --------------------------
echo "Cleaning up old Neovim config and LazyVim..."
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim/lazy
rm -rf ~/.local/share/nvim/site
rm -rf ~/.local/share/nvim/swap
rm -rf ~/.local/share/nvim/backup

# --------------------------
# Install system prerequisites
# --------------------------
echo "Installing prerequisites..."
sudo apt update
sudo apt install -y software-properties-common git curl unzip build-essential

# --------------------------
# Install latest Neovim
# --------------------------
echo "Adding Neovim unstable PPA..."
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt update
sudo apt install -y neovim

# --------------------------
# Install LuaJIT and LuaRocks
# --------------------------
echo "Installing LuaJIT and LuaRocks..."
sudo apt install -y luajit luarocks

# --------------------------
# Setup Neovim configuration
# --------------------------
echo "Setting up Neovim config..."
mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins

# init.lua
cat > ~/.config/nvim/init.lua << 'EOF'
require("config.lazy")
EOF

# lua/config/lazy.lua
cat > ~/.config/nvim/lua/config/lazy.lua << 'EOF'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"

-- Remove old lazy.nvim if exists
if (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "rm", "-rf", lazypath })
end

-- Clone fresh
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
vim.opt.rtp:prepend(lazypath)

-- Set leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true, notify = true },
})

-- Leader key shortcuts
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>f', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>g', ':Telescope live_grep<CR>', { noremap = true, silent = true })
EOF

# lua/plugins/init.lua
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
# Install plugins and Tree-sitter parsers
# --------------------------
echo "Installing Neovim plugins and Tree-sitter parsers..."
nvim --headless +Lazy! +TSUpdateSync +qall

echo "✅ Clean LazyVim installation complete! Open Neovim with 'nvim'."
