#!/bin/bash
set -e

# --------------------------
# Ask for sudo password once
# --------------------------
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

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
# Install system prerequisites
# --------------------------
echo "Installing prerequisites..."
sudo apt update -qq
sudo apt install -y software-properties-common git curl unzip build-essential > /dev/null

# --------------------------
# Install latest Neovim
# --------------------------
echo "Installing Neovim..."
sudo add-apt-repository -y ppa:neovim-ppa/unstable > /dev/null
sudo apt update -qq
sudo apt install -y neovim luajit luarocks > /dev/null

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
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"

-- Remove old lazy.nvim if exists
if vim.fn.isdirectory(lazypath) == 1 then
  vim.fn.system({ "rm", "-rf", lazypath })
end

-- Clone fresh lazy.nvim quietly
local out = vim.fn.system({ "git", "clone", "--quiet", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
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
# Install plugins with progress bar & error reporting
# --------------------------
echo -n "Installing LazyVim plugins: ["

# Run plugin installation in background and capture errors
{
  nvim --headless +Lazy! +TSUpdateSync +qall 2> /tmp/nvim_install_errors.log &
  pid=$!
  
  # Show simple progress bar while running
  while kill -0 $pid 2>/dev/null; do
    echo -n "#"
    sleep 0.5
  done
  wait $pid
} || {
  echo "] Failed!"
  echo "❌ An error occurred during plugin installation:"
  cat /tmp/nvim_install_errors.log
  exit 1
}

echo "] Done!"
echo "✅ LazyVim installation complete!"
