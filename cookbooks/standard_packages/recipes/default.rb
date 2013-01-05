##
# Installs standard Agilion Apps development tools.

['zsh', 'vim', 'ack-grep', 'tmux'].each do |pkg|
  package pkg do
    action :install
  end
end
