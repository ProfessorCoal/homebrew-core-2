require "language/node"

class Heroku < Formula
  desc "Command-line client for the cloud PaaS"
  homepage "https://cli.heroku.com"
  url "https://registry.npmjs.org/heroku-cli/-/heroku-cli-6.13.13.tgz"
  sha256 "1809598ebd2cc2e91f60e68478c0042555773ce6c2d6bfdad1a8caa62606d2e9"
  head "https://github.com/heroku/cli.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "caff9b06913b9c24dd7de046c5372643d07cb2c042199156a251c6b7fe9653c5" => :sierra
    sha256 "a358223912366aad79761f335ed78c5fe6f32a21282a5757b8c16fc66b4e5c14" => :el_capitan
    sha256 "0ff7bc445f165068a7e173e98e75fe14665667960b4c63e5d56a0e90af9c4f73" => :yosemite
  end

  depends_on :macos
  depends_on :arch => :x86_64
  depends_on "node"

  def install
    inreplace "bin/run.js", "npm update -g heroku-cli", "brew upgrade heroku"
    inreplace "bin/run", "node \"$DIR/run.js\"",
                         "#{Formula["node"].opt_bin}/node \"$DIR/run.js\""
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    system bin/"heroku", "version"
  end
end
