return {
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   ssh_domains = {},

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   wsl_domains = {
      {
         name = 'WSL:OSX',
         distribution = 'OSX',
         username = 'johnbauer',
         default_cwd = '/home/johnbauer',
         default_prog = { 'zsh' },
      },
   },
}
