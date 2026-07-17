cask "killall" do
  version "1.0.4"
  sha256 "2f8871217363272239ceebc96592aa72e247ba5207311d01e7dc2564f45a9588"

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
