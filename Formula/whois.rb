class Whois < Formula
  desc "Lookup tool for domain names and other internet resources"
  homepage "https://packages.debian.org/sid/whois"
  url "https://mirrors.ocf.berkeley.edu/debian/pool/main/w/whois/whois_5.2.17.tar.xz"
  mirror "https://mirrorservice.org/sites/ftp.debian.org/debian/pool/main/w/whois/whois_5.2.17.tar.xz"
  sha256 "257585678f571e18964667b41dc6543fe9da6123ac95743660c9c3ae1eba9664"
  head "https://github.com/rfc1036/whois.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "cf92d3f158f0a8d859f30180c9110da9a36d855eb77f3eb054202f9c211b9085" => :sierra
    sha256 "4747c2120aea12ac76e9538752680d307f24f37240dc25f972c0b41c91b74239" => :el_capitan
    sha256 "a09c672b49196965dc1fa33f2726dfd41c1852b07731b846d9cc743090b85eff" => :yosemite
    sha256 "e94ec3a3e39fcd570dadba7d9f93ae0167bee67ce38e4b65c1f958d164261065" => :x86_64_linux
  end

  def install
    system "make", "whois", *(["HAVE_ICONV=1", "whois_LDADD+=-liconv"] if OS.mac?)
    bin.install "whois"
    man1.install "whois.1"
  end

  def caveats; <<-EOS.undent
    Debian whois has been installed as `whois` and may shadow the
    system binary of the same name.
    EOS
  end

  test do
    system "#{bin}/whois", "brew.sh"
  end
end
