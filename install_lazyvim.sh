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
# Install system prerequisites via apt (show all output)
# --------------------------
echo "Installing prerequisites..."
sudo apt update
sudo apt install -y software-properties-common git curl unzip build-essential

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
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"

-- If lazy.nvim exists, update it; otherwise, clone fresh
if vim.fn.isdirectory(lazypath) == 1 then
  print("Updating existing lazy.nvim...")
  local out = vim.fn.system({ "git", "-C", lazypath, "pull" })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to update lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    os.exit(1)
  end
else
  print("Cloning lazy.nvim...")
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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
# Install plugins normally
# --------------------------
echo "Installing LazyVim plugins..."
if ! nvim --headless +Lazy! +TSUpdateSync +qall; then
  echo "❌ Error occurred during plugin installation"
  exit 1
fi

echo "✅ LazyVim installation complete!"
