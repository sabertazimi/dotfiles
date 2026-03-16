# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## [1.4.0](https://github.com/sabertazimi/dotfiles/compare/v1.3.0...v1.4.0) (2026-03-16)


### Features

* **ghostty-tmux:** add smart tmux wrapper script ([99b6ff5](https://github.com/sabertazimi/dotfiles/commit/99b6ff5c082fee060981aaa4163f160a97a3aaed))
* **ghostty-tmux:** attach tmux when terminal started ([1c7d14d](https://github.com/sabertazimi/dotfiles/commit/1c7d14d57464260beed1fee0a48f391c170bac18))
* **linux-terminal:** set up tmux pane keys ([6083067](https://github.com/sabertazimi/dotfiles/commit/60830678561491cd05adb722a746b0fb9857b71e))
* **linux-terminal:** tmux window name and host status ([c442ed3](https://github.com/sabertazimi/dotfiles/commit/c442ed3c816172eae4166a3de00d73cfd7e60aa8))
* **matugen-tmux:** add dynamic theme template ([69ed581](https://github.com/sabertazimi/dotfiles/commit/69ed581299892d438a84e88a794fa530c42cea03))
* **matugen:** use terminal color indices for starship palette ([1d8fb63](https://github.com/sabertazimi/dotfiles/commit/1d8fb633d0f883965938111a785b702363ad5a3d))
* **niri-window:** set up niri window rules ([445f75b](https://github.com/sabertazimi/dotfiles/commit/445f75be5ceabe0506073df4493f5fe5cc2842ab))
* **nvim-lualine:** customize `lualine` separator glyphs ([8bd15fe](https://github.com/sabertazimi/dotfiles/commit/8bd15feda8973f9b0b9768b8be9fa5f95e315ea8))
* **nvim:** switch to the official `catppuccin` color scheme ([e606208](https://github.com/sabertazimi/dotfiles/commit/e606208d605464c994de783f970e3b5dada2c6e2))
* **nvim:** update theme integration and lualine styling ([2ada3f1](https://github.com/sabertazimi/dotfiles/commit/2ada3f1919b229f8379c4738db487147f4a85175))
* **tmux:** adapt window separators to transparent background ([b122c88](https://github.com/sabertazimi/dotfiles/commit/b122c88c6f9969c8b3661865a78726686d624f71))
* **tmux:** add initial tmux configuration with `catppuccin` theme ([886b8ab](https://github.com/sabertazimi/dotfiles/commit/886b8ab903d635681146588f67adffa4dfd53c2c))
* **tmux:** enable extended keys ([bb90638](https://github.com/sabertazimi/dotfiles/commit/bb9063819931577bd61866697fea781bf7deea14))


### Bug Fixes

* **ghostty:** adjust vertical padding ([c31a7bd](https://github.com/sabertazimi/dotfiles/commit/c31a7bde604d2b95a0053f8656efd91dc489e56b))
* **ghostty:** restore ghostty vertical padding ([91bc77a](https://github.com/sabertazimi/dotfiles/commit/91bc77a605e87f3c83c5b22d9c3d6e523eddb58e))
* **linux-terminal:** tmux paste buffer bracketed mode ([c580e47](https://github.com/sabertazimi/dotfiles/commit/c580e4727b0bf7218238edf5ece24e7387f0423c))

## [1.3.0](https://github.com/sabertazimi/dotfiles/compare/v1.2.0...v1.3.0) (2026-03-07)


### Features

* **agent:** add alias to agents session ([a152ff6](https://github.com/sabertazimi/dotfiles/commit/a152ff62368e1f20acc78c1b950c66b46928b7d2))
* **agent:** set up alias to coding agents ([fa4d737](https://github.com/sabertazimi/dotfiles/commit/fa4d73717015f075b398f5d43c094f6fe9c61e4f))
* **dankmaterialshell:** add Firefox notification mute rule ([882a3ce](https://github.com/sabertazimi/dotfiles/commit/882a3ce2454617c4dc17f828e80c772dd0bb4d83))
* **fcitx:** set up fcitx key bindings ([efd80fe](https://github.com/sabertazimi/dotfiles/commit/efd80fea414a045210ea605cdc3dc32f72c978cb))
* **icon-theme:** change to `Papirus` icon theme ([4637913](https://github.com/sabertazimi/dotfiles/commit/46379134b180611d9dfce52cc5d589240903bb03))
* **niri-binds:** set up niri key binds ([e15976d](https://github.com/sabertazimi/dotfiles/commit/e15976d7e859c2d0b1a4c47d7f8a58858553330f))
* **nvim-pairs:** disable auto-pairs in command mode ([2a9c2f3](https://github.com/sabertazimi/dotfiles/commit/2a9c2f3e246007506e96f65fa977bd822c3cdb6e))
* **nvim:** add `toml` and `yaml` language extras plugins ([ede5629](https://github.com/sabertazimi/dotfiles/commit/ede56296c41fb8b2fbdda9e89b61b2fba7fb92b7))
* **zsh-nvm:** remove `Node.js` version manager `nvm` ([2f4d852](https://github.com/sabertazimi/dotfiles/commit/2f4d852a338254d28f37e1913b7b90a7a83ddacd))
* **zsh:** add local zsh configuration file ([72d8407](https://github.com/sabertazimi/dotfiles/commit/72d8407e784389913e28596cec67b8c17ca7a53e))
* **zsh:** command line DNS client `doggo` (dig) ([4726fb7](https://github.com/sabertazimi/dotfiles/commit/4726fb7385c899a516bf88364c7c4c3b57ea091e))
* **zsh:** reorganize shell config sections ([4ef4fa1](https://github.com/sabertazimi/dotfiles/commit/4ef4fa1b0c7e8afbb8fda15ed33724c7e0aea7fe))
* **zsh:** set up alias to `xdg-open` ([ccc50c2](https://github.com/sabertazimi/dotfiles/commit/ccc50c2c04bcfae0ce10be5b449ff96cdb50ab12))


### Bug Fixes

* **dms-dock:** remove apps from dock ([6b758a1](https://github.com/sabertazimi/dotfiles/commit/6b758a176d0f4dae67375a3ee8f34666947e7826))
* **linux-toolchain:** `zoxide` change directory command and tool headings ([09c00eb](https://github.com/sabertazimi/dotfiles/commit/09c00ebe9f05e65e2ea330bd3fe52641dc51740c))
* **linux-zsh:** change `zsh-autosuggestions` accept key ([3714456](https://github.com/sabertazimi/dotfiles/commit/37144569098543998a678e880b0108eb19fa9225))
* **mime:** format config file ([b884ac8](https://github.com/sabertazimi/dotfiles/commit/b884ac84da0a433d51492f679d24cb0df503fdf0))
* **mime:** format mime config file ([e82a0d2](https://github.com/sabertazimi/dotfiles/commit/e82a0d2bb5070e6959edcf52bc12e4ad17c566a9))
* **niri-binds:** change spawn key bindings ([780e7dc](https://github.com/sabertazimi/dotfiles/commit/780e7dc76403c37faaa4c27358139fe031ca5367))
* **niri-dms:** format config file ([d4e8e8f](https://github.com/sabertazimi/dotfiles/commit/d4e8e8fe3b49ac22ce74fbd9d23234be25c33ebb))
* **niri-dms:** reset notification popup position ([bff528e](https://github.com/sabertazimi/dotfiles/commit/bff528ef6d2089d9e6a7b0e7172cfcf7ebee66b2))
* **niri:** change browser key bind ([4380d92](https://github.com/sabertazimi/dotfiles/commit/4380d92414af6e40c6083a9d57705379bc416250))
* **nvim:** add `vi` alias ([5948695](https://github.com/sabertazimi/dotfiles/commit/5948695cf577528b8cc6265d329882d30e42cbeb))
* **nvim:** remove redundant example plugin ([30f6905](https://github.com/sabertazimi/dotfiles/commit/30f690551a57f7eb840c076e9ca33718968ba5e8))
* **nvim:** set up Neovim as default editor ([5df0190](https://github.com/sabertazimi/dotfiles/commit/5df0190a602889b9bd98315363d8a5f39227f8ba))
* **wallpapers:** replace sea hair with submerged city ([9e8b7db](https://github.com/sabertazimi/dotfiles/commit/9e8b7db4e3aa0fb0eacf41a5cde9cd2a7eb2c397))
* **wallpapers:** replace watermark wallpaper ([956e208](https://github.com/sabertazimi/dotfiles/commit/956e208f6851f9ebdf2db56aa4b081e6be803d90))

## [1.2.0](https://github.com/sabertazimi/dotfiles/compare/v1.1.0...v1.2.0) (2026-03-01)


### Features

* **github:** add alias for GitHub CLI ([5965539](https://github.com/sabertazimi/dotfiles/commit/5965539fa452dc8038f025323960d3b8695b9573))
* **linux-font:** set up Arch Linux font config ([3acf84d](https://github.com/sabertazimi/dotfiles/commit/3acf84ddb3d10d06250a48e628bce13131bf4ad2))
* **linux-fonts:** set up `fontconfig` ([dc5d55d](https://github.com/sabertazimi/dotfiles/commit/dc5d55d8db62cbc1779b6033259da9b1d1bc8609))
* **linux-fonts:** set up Adobe source han fonts ([60a1046](https://github.com/sabertazimi/dotfiles/commit/60a1046a7da38a4495b5b5be0c6646e3207ddc95))
* **linux-fonts:** upgrade to Maple Mono nerd font ([d417a25](https://github.com/sabertazimi/dotfiles/commit/d417a25f5d38f28d627809edc01f1403234aaf27))
* **niri-DMS:** add niri DMS config files ([#7](https://github.com/sabertazimi/dotfiles/issues/7)) ([1471140](https://github.com/sabertazimi/dotfiles/commit/1471140c191ea5694feb98bda5ba5a49214375f1))
* **niri:** add niri config file ([#8](https://github.com/sabertazimi/dotfiles/issues/8)) ([a4f708d](https://github.com/sabertazimi/dotfiles/commit/a4f708da2fd370bc6545b2add0644b257e838b1f))
* **nvim-aerial:** set up Neovim aerial plugin ([8362637](https://github.com/sabertazimi/dotfiles/commit/8362637b30e71d453fb879744494d94f459d7137))
* **nvim-keymaps:** bind vscode-style terminal keymap ([d4c5155](https://github.com/sabertazimi/dotfiles/commit/d4c5155c918bb452092b74933a2d422ba051d293))
* **nvim-spell:** change to Harper grammar checker ([a44e842](https://github.com/sabertazimi/dotfiles/commit/a44e84274f0b91ad5121f89d834b166e68f45dee))
* **nvim-theme:** change to `base16 catppuccin mocha` theme ([fbfdb68](https://github.com/sabertazimi/dotfiles/commit/fbfdb68e6a0ee028675e44b0f439a490ef099f5f))
* **nvim-wakatime:** add WakaTime plugin for Neovim ([3815769](https://github.com/sabertazimi/dotfiles/commit/3815769423ee88e2f942f3d58413cebe5e17ab05))
* **nvim:** add LazyVim configuration with language extras ([#6](https://github.com/sabertazimi/dotfiles/issues/6)) ([598b386](https://github.com/sabertazimi/dotfiles/commit/598b38699295d1ba461cfaf52dfa7c51a33f96da))
* **nvim:** add shellcheck for neovim ([03becf7](https://github.com/sabertazimi/dotfiles/commit/03becf7a6420fbdd2aea57d193fa231be7e84038))
* **television-channel:** add AUR channel for television ([aff94d4](https://github.com/sabertazimi/dotfiles/commit/aff94d4ea7288f1d1f72672561032183eb53f6ce))
* **television:** add shell integration ([e18144b](https://github.com/sabertazimi/dotfiles/commit/e18144b0ad6ffaff512ad7b555041ca72500debf))
* **television:** channel to install AUR packages ([ca26840](https://github.com/sabertazimi/dotfiles/commit/ca26840c5a4f905b1c26dd0aedba1684dd7b21f2))
* **tldr:** replace man with tldr ([121a8cd](https://github.com/sabertazimi/dotfiles/commit/121a8cd52073d09f74d339d628e687b69984edc1))
* **zsh-fzf:** set up fzf tab completion plugin ([dc70db7](https://github.com/sabertazimi/dotfiles/commit/dc70db78346b3878deeefab573e459f97da07c12))


### Bug Fixes

* **ghostty:** leave `ctrl+t` to fzf/shell completion ([36b9d29](https://github.com/sabertazimi/dotfiles/commit/36b9d299b095500b6606b7db863bfd098072ceb7))
* **linux-aur:** set up `AUR` helper alias ([d451d3c](https://github.com/sabertazimi/dotfiles/commit/d451d3c90afc467ec46d9aefc4589bdd540db7ea))
* **linux-font:** standardize `fontconfig` XML formatting and attribute ordering ([7820286](https://github.com/sabertazimi/dotfiles/commit/7820286bcf4b51eb8af15e49ecc8b731e8d1164a))
* **niri-DMS:** disable tail line appending ([ae5d45e](https://github.com/sabertazimi/dotfiles/commit/ae5d45e2062c77f1d27d6568fc32d7d41a4b7ebe))
* **nvim-keymaps:** add rebuild dictionary keymaps ([d253692](https://github.com/sabertazimi/dotfiles/commit/d25369254d014ee3a59413e815fb7a064b532d8d))
* **nvim-keymaps:** bind Snacks commands picker to `<C-P>` ([8b5d5f3](https://github.com/sabertazimi/dotfiles/commit/8b5d5f3cf8aa78bc2090bff7a7bc28f3d441d734))
* **nvim-lsp:** disable JSON language server format ([857aba2](https://github.com/sabertazimi/dotfiles/commit/857aba2cc4cbcfff87eacd863230faac34ac858a))
* **nvim:** enable JSON language server formatting ([aa39cbb](https://github.com/sabertazimi/dotfiles/commit/aa39cbb4773f65693c1a0be6a2b68d447fcc1b8a))
* **nvim:** move to autocmd file ([a8d8f12](https://github.com/sabertazimi/dotfiles/commit/a8d8f1244086cde9305b3a3bd712ba84faeb0677))
* **python-mirrors:** add suffix '/' to mirrors URL ([c136426](https://github.com/sabertazimi/dotfiles/commit/c1364260957301583451eb750d24b23863a1b887))
* **wallpapers:** change outrun with radium style ([e9cbcfa](https://github.com/sabertazimi/dotfiles/commit/e9cbcfa9a2184318fe716c5f455840c779317c3f))
* **zsh-procs:** add procs completion ([be04c02](https://github.com/sabertazimi/dotfiles/commit/be04c029bb2eb0ecbc3e8b082875038190baed89))

## [1.1.0](https://github.com/sabertazimi/dotfiles/compare/v1.0.0...v1.1.0) (2026-02-27)


### Features

* **go-env:** set up go env file ([73a0f90](https://github.com/sabertazimi/dotfiles/commit/73a0f90c2b6f6f8d615728938fc03f52484c3a73))
* **mime:** add mime apps list ([117be78](https://github.com/sabertazimi/dotfiles/commit/117be7863d865e90eb6a221f2a346be74a2dd01a))
* **niri-binds:** add niri keybinds config ([06172e4](https://github.com/sabertazimi/dotfiles/commit/06172e495cc3efc4817d7997e284645fce97d175))
* **pacman-fzf:** interactive TUI pacman helper ([a79e723](https://github.com/sabertazimi/dotfiles/commit/a79e72346e710c18bbf9ddc16e5dd8193fedc29a))
* **wallpapers:** add custom filenames to defaults and expand pixiv collection ([975b4b7](https://github.com/sabertazimi/dotfiles/commit/975b4b725c89eb579d66f06beedb2487e78a89c2))
* **wallpapers:** add pixiv support and custom filename feature ([515c07d](https://github.com/sabertazimi/dotfiles/commit/515c07d459033e16f1672fd217af7c71cbe79a64))
* **wallpapers:** add skip detection and summary statistics ([5efa3be](https://github.com/sabertazimi/dotfiles/commit/5efa3be204772a1baf42ede606aa56827436e9a9))
* **wallpapers:** add wallhaven wallpapers ([bdb7477](https://github.com/sabertazimi/dotfiles/commit/bdb747711e8f17d7c7976eeddb9ed559792347e8))
* **wallpapers:** add wallpapers from D3Ext/aesthetic-wallpapers ([419569a](https://github.com/sabertazimi/dotfiles/commit/419569a9e2593e6ed8b800cc59c7dcc7b1c0c0ba))


### Bug Fixes

* **rclone-onedrive:** change to background job ([bfda5a6](https://github.com/sabertazimi/dotfiles/commit/bfda5a63ed70539b7685a467575f0f96e1002864))
* **rclone-onedrive:** change to daemon mode ([51b8ed1](https://github.com/sabertazimi/dotfiles/commit/51b8ed1e8415daefa5e56fe3c579d5d114824608))
* **rclone-onedrive:** mount onedrive to local disk ([4f2df77](https://github.com/sabertazimi/dotfiles/commit/4f2df77051e9b7e52a2da81bc8a47b518793e93f))
* **starship:** change arrow symbol color ([38de404](https://github.com/sabertazimi/dotfiles/commit/38de404273b4fd2e5184f52926aa28eac76fa3f2))
* **wallpapers:** change nord category wallpaper ([23151e4](https://github.com/sabertazimi/dotfiles/commit/23151e48f18bc3e793e050fb346932dbfdf52639))
* **wallpapers:** change wallpaper name ([bfbb190](https://github.com/sabertazimi/dotfiles/commit/bfbb19024834b472c5c1071049595ae77f7e98e9))
* **wallpapers:** remove green land wallpaper ([2170a87](https://github.com/sabertazimi/dotfiles/commit/2170a876971296ceec74c52dd970ffbec5eb20e4))
* **wallpapers:** remove logo and pixel style wallpapers ([4d32496](https://github.com/sabertazimi/dotfiles/commit/4d324967ee95832f322cb6c87832186e6ed2de91))
* **wallpapers:** remove low resolution wallpapers ([6b0127f](https://github.com/sabertazimi/dotfiles/commit/6b0127f8fd7398abd96a873a48f8e5e403d81579))
* **wallpapers:** replace acrylic with town ([1b60c1d](https://github.com/sabertazimi/dotfiles/commit/1b60c1d288fa50d9c2821b418d96a30fcd067be8))
* **wallpapers:** replace cliff side with terraced farm ([7b5f394](https://github.com/sabertazimi/dotfiles/commit/7b5f3949c3c4b068da7f0813dd8ab1ab8ccd6fb5))
* **wallpapers:** replace desert with forest ([ec7ebdb](https://github.com/sabertazimi/dotfiles/commit/ec7ebdb235876b0ed473b4e12f87f90ffd89e14c))
* **wallpapers:** replace groudon and kyogre with arceus ([05c4363](https://github.com/sabertazimi/dotfiles/commit/05c4363b4bc098a48f059c12675a624d325ab636))
* **zshrc:** keep consistent with manual install ([630fcf8](https://github.com/sabertazimi/dotfiles/commit/630fcf8adfbfbbb3bb29c4c402dd3a29abf0954a))

## 1.0.0 (2026-02-25)


### Features

* **chezmoi:** ignore files for chezmoi (dotfiles manager) ([8c9e382](https://github.com/sabertazimi/dotfiles/commit/8c9e382739de3aed2b002290a47a19f7ed38b006))
* **ci:** add GitHub Actions workflow ([#1](https://github.com/sabertazimi/dotfiles/issues/1)) ([f0892f2](https://github.com/sabertazimi/dotfiles/commit/f0892f2c999a4303bb1e6c7dd2ad1c27e0bc1753))
* **dotfiles:** add application configs ([#2](https://github.com/sabertazimi/dotfiles/issues/2)) ([406fa0e](https://github.com/sabertazimi/dotfiles/commit/406fa0e164283c139b2017a474decf353e4cc57e))
* **dragon theme-git prompt:** add git status prompt support ([3c107b8](https://github.com/sabertazimi/dotfiles/commit/3c107b810f758fba5c545366bdfea24a9daba137))
* **dragon theme-time:** add time prompt ([b9d8a4e](https://github.com/sabertazimi/dotfiles/commit/b9d8a4e2a1a195631da5cbe0b2b9f201eaac3100))
* **GitHub Linguist:** enable zsh theme detection ([331bee2](https://github.com/sabertazimi/dotfiles/commit/331bee241b58663da1927479ad8c106c99af26cb))
* **matugen:** add matugen config files ([107fdbd](https://github.com/sabertazimi/dotfiles/commit/107fdbdb4a4378c00c7e951218fc33c7e4b9e2f7))
* **theme-bash:** add dragon bash theme ([db758c1](https://github.com/sabertazimi/dotfiles/commit/db758c1bec1664e669c1545db5294abac6b709a8))
* **wallpapers:** add third-party wallpapers ([1426a74](https://github.com/sabertazimi/dotfiles/commit/1426a74771d6b05839810b86a7fc9bd38d66b822))
* **wallpapers:** add wallpaper management scripts ([b5c7e73](https://github.com/sabertazimi/dotfiles/commit/b5c7e7354f0d5aca0c07c4f925a2de321a6f78a3))
* **zsh:** add `.zshrc` dotfile ([5ae1119](https://github.com/sabertazimi/dotfiles/commit/5ae11199dfae053bca3530c747a44bad707b58a7))


### Bug Fixes

* **chezmoi:** ignore CHANGELOG file ([4e1c0f4](https://github.com/sabertazimi/dotfiles/commit/4e1c0f4fe4187d3bc28e5db528b3fa8e43876f51))
* **chezmoi:** ignore Node.js files ([9a7e808](https://github.com/sabertazimi/dotfiles/commit/9a7e808383ec0ace9776c0f083542c479e242eaa))
* **ripgrep:** remove comment period ([a3c6163](https://github.com/sabertazimi/dotfiles/commit/a3c6163ef0fe2689f61eef852b5c4011da4c3d30))
* **theme-bash:** add user context and change status icon ([3603dca](https://github.com/sabertazimi/dotfiles/commit/3603dca4209317d7a0b7ab52d6f65084b596227f))
* **theme:** simplify git prompt logic ([5e2bfa0](https://github.com/sabertazimi/dotfiles/commit/5e2bfa003a9a3f39a75da5872905c405b0166b3a))
