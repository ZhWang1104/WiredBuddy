cask "wiredbuddy" do
  version "0.1-fixsign"
  sha256 "662cf365cff1032c142f45c4acc0e4da2820e927c88b4ab743b66b8783b13018"

  url "https://github.com/yeahitsjan/WiredBuddy/releases/download/#{version}/WiredBuddy.zip"
  name "Wired Buddy"
  desc "Menu bar application that shows Ethernet status"
  homepage "https://github.com/yeahitsjan/WiredBuddy"

  auto_updates false
  depends_on macos: :ventura

  app "Build002_Team_SignLocal/Wired Buddy.app"
end
