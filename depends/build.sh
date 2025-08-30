#!/bin/bash
set -e

OPENSSL_VERSION="3.3.1"
LIBSSH2_VERSION="1.11.0"

MIN_IOS="12.0"
MIN_MACOS="11.0"

BUILD_DIR="$(pwd)/build"
OUTPUT_DIR="$(pwd)/output"
XCFRAMEWORK_DIR="$OUTPUT_DIR/XCFrameworks"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$XCFRAMEWORK_DIR"

NUM_CPU=$(sysctl -n hw.logicalcpu)

############################
# Build OpenSSL / libssh2 helper
############################
build_one() {
  NAME=$1
  VERSION=$2
  PLATFORM=$3
  ARCH=$4
  SDK=$5
  MINFLAG=$6

  SRC_DIR="${NAME}-${VERSION}"
  PREFIX="$BUILD_DIR/$NAME/$PLATFORM-$ARCH"
  mkdir -p "$PREFIX"

  export CC="$(xcrun -sdk $SDK -find clang)"
  export CFLAGS="-arch $ARCH -isysroot $(xcrun -sdk $SDK --show-sdk-path) $MINFLAG -fembed-bitcode"
  export LDFLAGS="$CFLAGS"

  pushd "$SRC_DIR"

  case "$NAME" in
    openssl)
      # Choose correct target
      if [[ "$PLATFORM" == "iphonesimulator" ]]; then
          if [[ "$ARCH" == "x86_64" ]]; then
              TARGET="iossimulator-xcrun"
          else
              TARGET="iossimulator-arm64-xcrun"
          fi
      else
          TARGET="darwin64-${ARCH}-cc"
      fi

      ./Configure \
        no-shared no-dso no-hw no-engine no-tests no-legacy no-docs no-apps \
        $TARGET \
        --prefix="$PREFIX" --openssldir="$PREFIX"

      make clean
      make -j$NUM_CPU build_libs
      make install_sw
      ;;
    libssh2)
      # Host triple
      if [[ "$PLATFORM" == "iphoneos" ]]; then
        HOST="$ARCH-apple-darwin"
      elif [[ "$PLATFORM" == "iphonesimulator" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
          HOST="x86_64-apple-darwin"
        else
          HOST="arm-apple-darwin"
        fi
      else
        HOST="$ARCH-apple-darwin"
      fi

      ./configure --host="$HOST" \
        --disable-shared --enable-static \
        --disable-examples-build \
        --with-openssl --with-libssl-prefix="$BUILD_DIR/openssl/$PLATFORM-$ARCH" \
        --prefix="$PREFIX"

      make clean
      make -j$NUM_CPU
      make install
      ;;
  esac

  popd
}

############################
# Download sources if missing
############################
download_sources() {
  if [ ! -d "openssl-$OPENSSL_VERSION" ]; then
    curl -LO https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
    tar xzf openssl-$OPENSSL_VERSION.tar.gz
  fi
  if [ ! -d "libssh2-$LIBSSH2_VERSION" ]; then
    curl -LO https://www.libssh2.org/download/libssh2-$LIBSSH2_VERSION.tar.gz
    tar xzf libssh2-$LIBSSH2_VERSION.tar.gz
  fi
}
download_sources

############################
# Build all slices
############################
# OpenSSL
build_one openssl $OPENSSL_VERSION iphoneos arm64 iphoneos "-miphoneos-version-min=$MIN_IOS"
build_one openssl $OPENSSL_VERSION iphonesimulator x86_64 iphonesimulator "-miphonesimulator-version-min=$MIN_IOS"
build_one openssl $OPENSSL_VERSION iphonesimulator arm64 iphonesimulator "-miphonesimulator-version-min=$MIN_IOS"
build_one openssl $OPENSSL_VERSION macosx x86_64 macosx "-mmacosx-version-min=$MIN_MACOS"
build_one openssl $OPENSSL_VERSION macosx arm64 macosx "-mmacosx-version-min=$MIN_MACOS"

# libssh2
build_one libssh2 $LIBSSH2_VERSION iphoneos arm64 iphoneos "-miphoneos-version-min=$MIN_IOS"
build_one libssh2 $LIBSSH2_VERSION iphonesimulator arm64 iphonesimulator "-miphonesimulator-version-min=$MIN_IOS"
build_one libssh2 $LIBSSH2_VERSION iphonesimulator x86_64 iphonesimulator "-miphonesimulator-version-min=$MIN_IOS"
build_one libssh2 $LIBSSH2_VERSION macosx x86_64 macosx "-mmacosx-version-min=$MIN_MACOS"
build_one libssh2 $LIBSSH2_VERSION macosx arm64 macosx "-mmacosx-version-min=$MIN_MACOS"

create_universal_libs() {
  LIB_NAME=$1
  LIB_FILE=$2  # e.g., "libssh2.a"

  echo ">>> Creating universal binaries for $LIB_NAME"

  # iOS Simulator (x86_64 + arm64)
  mkdir -p "$BUILD_DIR/$LIB_NAME/iphonesimulator-universal/lib"
  lipo -create \
    "$BUILD_DIR/$LIB_NAME/iphonesimulator-x86_64/lib/$LIB_FILE" \
    "$BUILD_DIR/$LIB_NAME/iphonesimulator-arm64/lib/$LIB_FILE" \
    -output "$BUILD_DIR/$LIB_NAME/iphonesimulator-universal/lib/$LIB_FILE"

  # Copy headers for simulator universal
  cp -r "$BUILD_DIR/$LIB_NAME/iphonesimulator-arm64/include" "$BUILD_DIR/$LIB_NAME/iphonesimulator-universal/"

  # macOS (x86_64 + arm64)
  mkdir -p "$BUILD_DIR/$LIB_NAME/macos-universal/lib"
  lipo -create \
    "$BUILD_DIR/$LIB_NAME/macosx-x86_64/lib/$LIB_FILE" \
    "$BUILD_DIR/$LIB_NAME/macosx-arm64/lib/$LIB_FILE" \
    -output "$BUILD_DIR/$LIB_NAME/macos-universal/lib/$LIB_FILE"

  # Copy headers for macOS universal
  cp -r "$BUILD_DIR/$LIB_NAME/macosx-arm64/include" "$BUILD_DIR/$LIB_NAME/macos-universal/"
}

# Create universal binaries for OpenSSL libraries
create_universal_openssl_libs() {
  for LIB in ssl crypto; do
    echo ">>> Creating universal binaries for lib$LIB"

    # iOS Simulator (x86_64 + arm64)
    mkdir -p "$BUILD_DIR/openssl/iphonesimulator-universal/lib"
    lipo -create \
      "$BUILD_DIR/openssl/iphonesimulator-x86_64/lib/lib$LIB.a" \
      "$BUILD_DIR/openssl/iphonesimulator-arm64/lib/lib$LIB.a" \
      -output "$BUILD_DIR/openssl/iphonesimulator-universal/lib/lib$LIB.a"

    # macOS (x86_64 + arm64)
    mkdir -p "$BUILD_DIR/openssl/macos-universal/lib"
    lipo -create \
      "$BUILD_DIR/openssl/macosx-x86_64/lib/lib$LIB.a" \
      "$BUILD_DIR/openssl/macosx-arm64/lib/lib$LIB.a" \
      -output "$BUILD_DIR/openssl/macos-universal/lib/lib$LIB.a"
  done

  # Copy headers once for OpenSSL
  cp -r "$BUILD_DIR/openssl/iphonesimulator-arm64/include" "$BUILD_DIR/openssl/iphonesimulator-universal/"
  cp -r "$BUILD_DIR/openssl/macosx-arm64/include" "$BUILD_DIR/openssl/macos-universal/"
}

# Create universal libraries
create_universal_libs libssh2 libssh2.a
create_universal_openssl_libs

############################
# Create XCFrameworks
############################
create_xcframework() {
  LIB_NAME=$1
  shift
  LIB_PATHS=("$@")
  HEADER_PATHS=()
  for LIB in "${LIB_PATHS[@]}"; do
    HEADER_PATHS+=("$(dirname "$LIB")/../include")
  done

  CMD=(xcodebuild -create-xcframework)
  for i in "${!LIB_PATHS[@]}"; do
    CMD+=(-library "${LIB_PATHS[$i]}" -headers "${HEADER_PATHS[$i]}")
  done
  CMD+=(-output "$XCFRAMEWORK_DIR/$LIB_NAME.xcframework")

  echo ">>> Creating XCFramework for $LIB_NAME"
  "${CMD[@]}"
}

# Create XCFrameworks with universal binaries
create_xcframework libssh2 \
  "$BUILD_DIR/libssh2/iphoneos-arm64/lib/libssh2.a" \
  "$BUILD_DIR/libssh2/iphonesimulator-universal/lib/libssh2.a" \
  "$BUILD_DIR/libssh2/macos-universal/lib/libssh2.a"

create_xcframework libssl \
  "$BUILD_DIR/openssl/iphoneos-arm64/lib/libssl.a" \
  "$BUILD_DIR/openssl/iphonesimulator-universal/lib/libssl.a" \
  "$BUILD_DIR/openssl/macos-universal/lib/libssl.a"

create_xcframework libcrypto \
  "$BUILD_DIR/openssl/iphoneos-arm64/lib/libcrypto.a" \
  "$BUILD_DIR/openssl/iphonesimulator-universal/lib/libcrypto.a" \
  "$BUILD_DIR/openssl/macos-universal/lib/libcrypto.a"

echo ">>> All XCFrameworks are in $XCFRAMEWORK_DIR"
