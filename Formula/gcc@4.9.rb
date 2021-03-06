class GccAT49 < Formula
  def arch
    if Hardware::CPU.type == :intel
      if MacOS.prefer_64_bit?
        "x86_64"
      else
        "i686"
      end
    elsif Hardware::CPU.type == :ppc
      if MacOS.prefer_64_bit?
        "powerpc64"
      else
        "powerpc"
      end
    end
  end

  def osmajor
    `uname -r`.chomp
  end

  desc "The GNU Compiler Collection"
  homepage "https://gcc.gnu.org/"
  url "https://ftp.gnu.org/gnu/gcc/gcc-4.9.4/gcc-4.9.4.tar.bz2"
  mirror "https://ftpmirror.gnu.org/gcc/gcc-4.9.4/gcc-4.9.4.tar.bz2"
  sha256 "6c11d292cd01b294f9f84c9a59c230d80e9e4a47e5c6355f046bb36d4f358092"
  head "svn://gcc.gnu.org/svn/gcc/branches/gcc-4_9-branch"

  bottle do
    cellar :any unless OS.mac?
    sha256 "ad74e12473b9d5e20275a47028b63f94aedde641d035b8d101a1860e2bf19b76" => :sierra
    sha256 "3283035aaaf32998cccdec8ada8ae5d32ef49fdab14461d0473d6862800ae16e" => :el_capitan
    sha256 "dfd72720aef0ef7a2f924b9aa79a0ab5f6b1cd55e81ff592a79b52a59282c8eb" => :yosemite
    sha256 "d9acda4b7a1b62adea7ea01f87a3fd912b6e9de162c9e0830c3eba99d5ceb01e" => :x86_64_linux
  end

  option "without-fortran", "Build without the gfortran compiler"
  option "with-java", "Build the gcj compiler"
  option "with-all-languages", "Enable all compilers and languages, except Ada"
  option "with-nls", "Build with native language support (localization)"
  option "with-profiled-build", "Make use of profile guided optimization when bootstrapping GCC"

  deprecated_option "enable-java" => "with-java"
  deprecated_option "enable-all-languages" => "with-all-languages"
  deprecated_option "enable-nls" => "with-nls"
  deprecated_option "enable-profiled-build" => "with-profiled-build"

  unless OS.mac?
    depends_on "binutils"
    depends_on "zlib"
  end
  depends_on "gmp@4"
  depends_on "libmpc@0.8"
  depends_on "mpfr@2"
  depends_on "cloog"
  depends_on "isl@0.12"
  depends_on "ecj" if build.with?("java") || build.with?("all-languages")

  # The bottles are built on systems with the CLT installed, and do not work
  # out of the box on Xcode-only systems due to an incorrect sysroot.
  def pour_bottle?
    MacOS::CLT.installed?
  end

  # GCC bootstraps itself, so it is OK to have an incompatible C++ stdlib
  cxxstdlib_check :skip

  def install
    # GCC will suffer build errors if forced to use a particular linker.
    ENV.delete "LD"

    if build.with? "all-languages"
      # Everything but Ada, which requires a pre-existing GCC Ada compiler
      # (gnat) to bootstrap. GCC 4.6.0 add go as a language option, but it is
      # currently only compilable on Linux.
      languages = %w[c c++ fortran java objc obj-c++]
    else
      # C, C++, ObjC compilers are always built
      languages = %w[c c++ objc obj-c++]

      languages << "fortran" if build.with? "fortran"
      languages << "java" if build.with? "java"
    end

    version_suffix = version.to_s.slice(/\d\.\d/)

    args = []
    if OS.mac?
      args << "--build=#{arch}-apple-darwin#{osmajor}"
      args << "--libdir=#{lib}/gcc/#{version_suffix}"
    end
    args = [
      "--prefix=#{prefix}",
      "--enable-languages=#{languages.join(",")}",
      # Make most executables versioned to avoid conflicts.
      "--program-suffix=-#{version_suffix}",
      "--with-gmp=#{Formula["gmp@4"].opt_prefix}",
      "--with-mpfr=#{Formula["mpfr@2"].opt_prefix}",
      "--with-mpc=#{Formula["libmpc@0.8"].opt_prefix}",
      "--with-cloog=#{Formula["cloog"].opt_prefix}",
      "--with-isl=#{Formula["isl@0.12"].opt_prefix}",
      "--with-system-zlib",
      "--enable-libstdcxx-time=yes",
      "--enable-stage1-checking",
      "--enable-checking=release",
      "--enable-lto",
      "--enable-plugin",
      # Use 'bootstrap-debug' build configuration to force stripping of object
      # files prior to comparison during bootstrap (broken by Xcode 6.3).
      "--with-build-config=bootstrap-debug",
      # A no-op unless --HEAD is built because in head warnings will
      # raise errors. But still a good idea to include.
      "--disable-werror",
      "--with-pkgversion=Homebrew GCC #{pkg_version} #{build.used_options*" "}".strip,
      "--with-bugurl=https://github.com/Homebrew/homebrew-core/issues",
      # Even when suffixes are appended, the info pages conflict when
      # install-info is run.
      "MAKEINFO=missing",
    ]

    args << "--disable-nls" if build.without? "nls"

    if build.with?("java") || build.with?("all-languages")
      args << "--with-ecj-jar=#{Formula["ecj"].opt_prefix}/share/java/ecj.jar"
    end

    if MacOS.prefer_64_bit?
      args << "--enable-multilib"
    else
      args << "--disable-multilib"
    end

    ENV["CPPFLAGS"] = "-I#{Formula["zlib"].include}" unless OS.mac?

    # Ensure correct install names when linking against libgcc_s;
    # see discussion in https://github.com/Homebrew/homebrew/pull/34303
    inreplace "libgcc/config/t-slibgcc-darwin", "@shlib_slibdir@", "#{HOMEBREW_PREFIX}/lib/gcc/#{version_suffix}"

    mkdir "build" do
      if OS.mac? && !MacOS::CLT.installed?
        # For Xcode-only systems, we need to tell the sysroot path.
        # "native-system-headers" will be appended
        args << "--with-native-system-header-dir=/usr/include"
        args << "--with-sysroot=#{MacOS.sdk_path}"
      end

      system "../configure", *args

      if build.with? "profiled-build"
        # Takes longer to build, may bug out. Provided for those who want to
        # optimise all the way to 11.
        system "make", "profiledbootstrap"
      else
        system "make", "bootstrap"
      end

      # At this point `make check` could be invoked to run the testsuite. The
      # deja-gnu and autogen formulae must be installed in order to do this.
      system "make", "install"
    end

    # Handle conflicts between GCC formulae.
    # Rename man7.
    Dir.glob(man7/"*.7") { |file| add_suffix file, version_suffix }
    # Even when we disable building info pages some are still installed.
    info.rmtree

    if OS.linux?
      # Strip the executables to reduce their size from 600 MB to 100 MB.
      libexecgcc = libexec/"gcc/x86_64-unknown-linux-gnu"/version
      system "strip", *(Dir[libexecgcc/"*"] - Dir[libexecgcc/"*.la"]).select { |f| File.file? f }
    end
  end

  def add_suffix(file, suffix)
    dir = File.dirname(file)
    ext = File.extname(file)
    base = File.basename(file, ext)
    File.rename file, "#{dir}/#{base}-#{suffix}#{ext}"
  end

  def post_install
    return if OS.mac?

    # Create the GCC specs file
    # See https://gcc.gnu.org/onlinedocs/gcc/Spec-Files.html
    version_suffix = version.to_s[/\d\.\d/]
    gcc = bin/"gcc-#{version_suffix}"
    libgcc = Pathname.new(Utils.popen_read(gcc, "-print-libgcc-file-name").chomp).dirname
    raise "command failed: #{gcc} -print-libgcc-file-name" unless $?.success?
    specs = libgcc/"specs"
    ohai "Creating the GCC specs file: #{specs}"
    specs_orig = Pathname.new("#{specs}.orig")
    rm_f [specs_orig, specs]

    # Save a backup of the default specs file
    specs_string = Utils.popen_read(gcc, "-dumpspecs")
    raise "command failed: #{gcc} -dumpspecs" unless $?.success?
    specs_orig.write specs_string

    # Set the dynamic linker and library search path
    glibc = Formula["glibc"]
    specs.write specs_string + <<-EOS.undent
      *cpp_unique_options:
      + -isystem #{HOMEBREW_PREFIX}/include

      *link_libgcc:
      #{glibc.installed? ? "-nostdlib -L#{libgcc}" : "+"} -L#{HOMEBREW_PREFIX}/lib

      *link:
      + --dynamic-linker #{HOMEBREW_PREFIX}/lib/ld.so -rpath #{HOMEBREW_PREFIX}/lib

    EOS
  end

  test do
    (testpath/"hello-c.c").write <<-EOS.undent
      #include <stdio.h>
      int main()
      {
        puts("Hello, world!");
        return 0;
      }
    EOS
    system bin/"gcc-4.9", "-o", "hello-c", "hello-c.c"
    assert_equal "Hello, world!\n", `./hello-c`
  end
end
