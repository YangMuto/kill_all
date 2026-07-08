# 发布指南：GitHub + Homebrew（不签名 / 自建 tap）

占位符 `YangMuto` = 你的 GitHub 用户名。两个仓库：
- `kill_all` —— 源码 + Release 里挂 zip
- `homebrew-tap` —— 存放 cask 公式（仓库名**必须**以 `homebrew-` 开头）

---

## 一次性准备
```bash
# 装 gh（可选，方便建仓建 release）
brew install gh
gh auth login
```

## 第 1 步：主仓库 kill_all
```bash
cd /Users/bytedance/Claude/Projects/kill_all
git init && git add -A && git commit -m "KillAll v1.0.0"
gh repo create kill_all --public --source=. --push
# 或手动：git remote add origin https://github.com/YangMuto/kill_all.git && git push -u origin main
```

## 第 2 步：打包并建 Release
```bash
./release.sh 1.0.0          # 产出 dist/KillAll-1.0.0.zip，并打印 sha256
gh release create v1.0.0 dist/KillAll-1.0.0.zip -t "v1.0.0" -n "首个版本"
```
记下打印出来的 **sha256**。

## 第 3 步：tap 仓库
```bash
mkdir -p ~/homebrew-tap/Casks
cp Casks/killall.rb ~/homebrew-tap/Casks/killall.rb
# 编辑 killall.rb：sha256 换成第2步打印的值（url 里用户名已是 YangMuto）
cd ~/homebrew-tap
git init && git add -A && git commit -m "killall cask 1.0.0"
gh repo create homebrew-tap --public --source=. --push
```

## 第 4 步：别人安装
```bash
brew install --cask --no-quarantine YangMuto/tap/killall
open -a KillAll
```
（`tap` 是仓库名 `homebrew-tap` 去掉前缀后的简称。）

---

## 以后发新版本
```bash
# 1. 改代码后，更新版本号（Info.plist 的 CFBundleShortVersionString / CFBundleVersion）
./release.sh 1.1.0
gh release create v1.1.0 dist/KillAll-1.1.0.zip -t "v1.1.0" -n "更新说明"
# 2. 更新 tap：killall.rb 里 version 改 1.1.0，sha256 换成新的
cd ~/homebrew-tap && git commit -am "killall 1.1.0" && git push
# 3. 用户升级
brew upgrade --cask killall
```

## 常见坑
- **sha256 对不上** → cask 里的 sha256 必须是你**真正上传到 Release 的那个 zip** 的值，重新打包会变。
- **仓库名** → tap 仓库必须叫 `homebrew-xxx`，用户 tap 时写 `YangMuto/xxx`。
- **未签名打不开** → 用 `--no-quarantine` 装，或 `xattr -dr com.apple.quarantine /Applications/KillAll.app`。
- **想要零警告体验** → 需 Apple Developer（$99/年）签名+公证，见 README 的路线 B。
- **上 homebrew-cask 官方库** → 要求 app 已公证 + 有一定知名度，个人项目先用自建 tap。
