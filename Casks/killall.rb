cask "killall" do
  version "1.0.3"
  sha256 "dee20d8ada3d06efcb332980def48673246fb168a9a53a79fd85ee47fe61ff36"

  url "https://github.com/YangMuto/kill_all/releases/download/v#{version}/KillAll-#{version}.zip"
  name "KillAll"
  desc "Menu bar monitor that kills stray dev processes (node/python/vite/…)"
  homepage "https://github.com/YangMuto/kill_all"

  app "KillAll.app"

  # 未签名分发：Homebrew 仍会加隔离属性，装完需去掉才能打开
  caveats <<~EOS
    KillAll 未做 Apple 签名，装完请执行一次去隔离，否则打不开：

      xattr -dr com.apple.quarantine "/Applications/KillAll.app"

    然后打开： open -a KillAll
    （首次打开会自动加入登录项，实现开机自启；面板底部可关。）
  EOS

  zap trash: [
    "~/Library/Preferences/com.local.killall.plist",
  ]
end
