cask "killall" do
  version "1.0.1"
  sha256 "e088fe5009b096bd0003184944342158ce424b04da795692991c9d7532dd49a6"

  url "https://github.com/YangMuto/kill_all/releases/download/v#{version}/KillAll-#{version}.zip"
  name "KillAll"
  desc "Menu bar monitor that kills stray dev processes (node/python/vite/…)"
  homepage "https://github.com/YangMuto/kill_all"

  app "KillAll.app"

  # 未签名分发：装完请去掉隔离属性再打开（或用 `--no-quarantine` 安装）
  caveats <<~EOS
    KillAll 未做 Apple 签名。若打开被拦，执行一次：
      xattr -dr com.apple.quarantine "/Applications/KillAll.app"
    或安装时加 --no-quarantine：
      brew install --cask --no-quarantine #{token}
  EOS

  zap trash: [
    "~/Library/Preferences/com.local.killall.plist",
  ]
end
