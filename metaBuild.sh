DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ "$1" = "build" ]; then
  SYSTEM_NAME=`uname -s` 
  if [ "$SYSTEM_NAME" = "Darwin" ]; then
    echo "Building for OSX"
    (cd $DIR && \
      ./configure CXX='clang++ -std=c++11 -stdlib=libc++' --enable-cxx --enable-gmpcompat --enable-shared --disable-static && \
      make)
  elif echo "$SYSTEM_NAME" | grep -q "MINGW64_NT"; then
    echo "Building for Windows"
    (cd $DIR && \
    ./configure --host=corei7-w64-mingw64 --enable-fat --enable-cxx --enable-gmpcompat --enable-shared --disable-static && \
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
