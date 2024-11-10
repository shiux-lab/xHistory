# 
<p align="center">
<img src="./xHistory/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">xHistory</h1>
<h3 align="center">A powerful command line history manager built with SwiftUI<br><a href="./README_zh.md">[中文版本]</a></h3> 
</p>

## Screenshots
<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./img/preview_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./img/preview.png">
  <img alt="xHistory Screenshots" src="./img/preview.png" width="610"/>
</picture>
</p>

## Installation and Usage
### System Requirements:
- macOS 12.0 and Later  

### Installation:
Download the latest installation file [here](../../releases/latest) or install via Homebrew:  

```bash
brew install lihaoyun6/tap/xhistory
```

### Usage: 
- xHistory is simple to use and can automatically read histories from various shells without requiring manual configuration of terminal options.  

- By default, xHistory appears in the menu bar after launching (it can be hidden), and you can quickly open the panel via a shortcut or command line.  
- xHistory supports searching history, syntax highlighting, automatic filling (without copying), magic slicing, pin commands, command blacklist, and more.  

## Q&A
**1. Why don’t executed commands appear in the history panel?**
> After installing and launching xHistory for the first time, you need to log in to a new shell session for it to work.  

**2. Why does xHistory need Accessibility permissions?**
> The “Auto Fill” feature of xHistory simulates keyboard input, which requires Accessibility permissions to function properly. 

## Donate
<img src="./img/donate.png" width="350"/>

## Thanks
[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) @sindresorhus  
[SFSMonitor](https://github.com/ClassicalDude/SFSMonitor) @ClassicalDude  
[SwiftTreeSitter](https://github.com/ChimeHQ/SwiftTreeSitter) @ChimeHQ  
[tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) @tree-sitter  
[ChatGPT](https://chat.openai.com) @OpenAI  
