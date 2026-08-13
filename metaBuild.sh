DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PREFIX=$DIR/.libs
echo $DIR
if [ -z "$2" ]; then
  ARCH="x86-64"
else
  ARCH="$2"
fi


if [ "$1" = "release" -o "$1" = "debug" ]; then
  SYSTEM_NAME=`uname -s`
  if [ "$SYSTEM_NAME" = "Darwin" ]; then
    echo "Building for OSX, architecture set to $ARCH"
    # Apple clang needs an explicit -arch fat-binary selector to actually target a
    # non-host architecture (e.g. cross-compiling x86-64 object code from an arm64
    # host, or vice versa); -march= alone only tunes codegen for whatever arch clang
    # already defaults to (the host arch), so without -arch a cross-arch -march=
    # value is rejected outright ("unsupported argument 'x86-64' to option
    # '-march='"). Mirrors the identical fix applied to geode's SConstruct for the
    # same otherplan macOS universal-build work (see otherplan
    # releng/macos/build-universal-deps.sh). Scoped to this Darwin branch only -- no
    # effect on the Linux/Windows branches below.
    case "$ARCH" in
      armv8-a) APPLE_ARCH="arm64" ;;
      x86-64)  APPLE_ARCH="x86_64" ;;
      *)       APPLE_ARCH="" ;;
    esac
    if [ -n "$APPLE_ARCH" ]; then
      DARWIN_ARCH_FLAG=" -arch $APPLE_ARCH"
    else
      DARWIN_ARCH_FLAG=""
    fi
    # -arch must also live inside the CXX= value itself, not just CXXFLAGS: mpir's
    # generated libtool script builds each C++ convenience library (libmpirxx,
    # libgmpxx) via a Darwin-only "master object" merge step
    # ($CC -r -keep_private_externs -nostdlib -o $lib-master.o $libobjs, from
    # aclocal.m4's archive_cmds) that intentionally omits $compiler_flags -- so
    # CXXFLAGS's -arch never reaches it. $CC there resolves to whatever CXX= was
    # configured as, so baking -arch into CXX= is the only way to reach that step.
    # Confirmed empirically: without this, the x86-64 pass silently links arm64
    # cxx/.libs/*.o objects into a master.o step that defaults to the host's arch
    # (arm64) absent any -arch flag, and ld -r drops every mismatched-arch object
    # with only a warning -- producing an incomplete (missing C++ wrapper symbols)
    # but still-valid-looking single-arch x86_64 dylib.
    (cd $DIR && \
    ./configure --libdir=$PREFIX CXX="clang++ -std=c++11 -stdlib=libc++$DARWIN_ARCH_FLAG" CXXFLAGS="-march=$ARCH -mtune=generic -mmacosx-version-min=10.8$DARWIN_ARCH_FLAG" CFLAGS="-march=$ARCH -mtune=generic$DARWIN_ARCH_FLAG" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
    make)
  elif [ "$SYSTEM_NAME" = "Linux" ]; then
    echo "Building for Linux, architecture set to $ARCH"
    if [ "$ARCH" = "armv8-a" ]; then
      # FIXME: Not sure how to get clang working in dockcross yet
      # ./configure --build=$ARCH --libdir=$PREFIX CC=clang CXX=clang++ CXXFLAGS="-std=c++11 -mcpu=arm7 -mtune=generic-arm7" CFLAGS="-mcpu=arm7 -mtune=generic-arm7" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
      # this doesn't make a share library for some reason:
      # ./configure --build=$ARCH --libdir=$PREFIX CXXFLAGS="-fPIC" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
      (cd $DIR && \
      ./configure --libdir=$PREFIX CC=clang CXX=clang++ CXXFLAGS="-std=c++11 -march=armv8-a" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
      make)
    else
      (cd $DIR && \
      ./configure --build=$ARCH --libdir=$PREFIX CC=clang CXX=clang++ CXXFLAGS="-std=c++11 -march=$ARCH -mtune=generic" CFLAGS="-march=$ARCH -mtune=generic" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
      make)
    fi
  elif echo "$SYSTEM_NAME" | grep -q "MINGW64_NT"; then
    echo "Building for Windows"
    (cd $DIR && \
    ./configure --libdir=$PREFIX --host=x86_64-w64-mingw64 --enable-fat --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
    make)
  elif echo "$SYSTEM_NAME" | grep -q "MSYS"; then
    echo "ERROR: the MSYS shell is not supported. Please use the MinGW-w64 Win64 Shell instead."
    exit 1
  else
    echo "ERROR: Unrecognized or unsupported platform: $SYSTEM_NAME!"
    exit 1
  fi
elif [ "$1" = "clean" ]; then
  (cd $DIR && \
    make clean)
else
  echo "Missing or unrecognized metabuild argument \"$1\""
  exit 1
fi
