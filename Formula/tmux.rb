class Tmux < Formula
  desc "Terminal multiplexer"
  homepage "https://tmux.github.io/"
  url "https://github.com/tmux/tmux/releases/download/2.5/tmux-2.5.tar.gz"
  sha256 "ae135ec37c1bf6b7750a84e3a35e93d91033a806943e034521c8af51b12d95df"

  bottle do
    sha256 "232d1d04e4b6fb4c860d0d72a6e98dc000d33028b2d6cea87f476d2502fc7bac" => :sierra
    sha256 "3bcc934afd1b4067dcd57400d5296c38d37f9e671b716578eae3ad150a64b3b3" => :el_capitan
    sha256 "d137eb4f725cd7784162c01b1e6053c88059079aed639b685f3a3eba82efe31f" => :yosemite
    sha256 "5ffa45b3316572ec0e022b97ee4afd878dc7e97dbadb51786deb68ced4dec2f5" => :x86_64_linux
  end

  head do
    url "https://github.com/tmux/tmux.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "libevent"
  depends_on "utf8proc" => :optional
  depends_on "ncurses" unless OS.mac?

  resource "completion" do
    url "https://raw.githubusercontent.com/imomaliev/tmux-bash-completion/homebrew_1.0.0/completions/tmux"
    sha256 "05e79fc1ecb27637dc9d6a52c315b8f207cf010cdcee9928805525076c9020ae"
  end

  def install
    system "sh", "autogen.sh" if build.head?

    args = %W[
      --disable-Dependency-tracking
      --prefix=#{prefix}
      --sysconfdir=#{etc}
    ]

    args << "--enable-utf8proc" if build.with?("utf8proc")

    ENV.append "LDFLAGS", "-lresolv"
    system "./configure", *args

    system "make", "install"

    pkgshare.install "example_tmux.conf"
    bash_completion.install resource("completion")
  end

  def caveats; <<-EOS.undent
    Example configuration has been installed to:
      #{opt_pkgshare}
    EOS
  end

  test do
    system "#{bin}/tmux", "-V"
  end
end
