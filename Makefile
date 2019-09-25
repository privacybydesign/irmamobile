# Versions
FLUTTER_VERSION = 1.9.1+hotfix.2-stable
GOLANG_VERSION = 1.12.9
GOLANG_DEP_VERSION = 0.5.4
ANDROID_SDK_VERSION = 4333796
ANDROID_CMAKE_VERSION = 3.10.2.4988404
ANDROID_LLDB_VERSION = 3.1
ANDROID_SDK_PACKAGES ?= \
	"build-tools;28.0.3" \
	"platforms;android-28" \
	"emulator" \
	"system-images;android-28;google_apis_playstore;x86"

# Check for host OS
ifeq ($(OS),Windows_NT)
	$(error Windows is not supported by this makefile)
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSNAME=linux
		FLUTTER_OS=linux
		FLUTTER_CHECKSUM = f82875a865c8dbebd10b7a69ffc4cb19d9c916054f3bbcda5a66395f30477d91
		GOLANG_CHECKSUM = ac2a6efcc1f5ec8bdc0db0a988bb1d301d64b6d61b7e8d9e42f662fbb75a2b9b
		GOLANG_DEP_CHECKSUM = 40a78c13753f482208d3f4bea51244ca60a914341050c588dad1f00b1acc116c
		ANDROID_SDK_CHECKSUM = 92ffee5a1d98d856634e8b71132e8a95d96c83a63fde1099be3d86df3106def9
	endif
	ifeq ($(UNAME_S),Darwin)
		OSNAME=darwin
		FLUTTER_OS=macos
		FLUTTER_CHECKSUM = 8f7a5cfa1494b6758e1b9b7913871a60934c7f3d487979a6ef176ce4f2a7b4a3
		GOLANG_CHECKSUM = 4f189102b15de0be1852d03a764acb7ac5ea2c67672a6ad3a340bd18d0e04bb4
		GOLANG_DEP_CHECKSUM = c36cf732053f4b70732a499eecaa0ac38c6f5547a235362c062446ab8764b3c2
		ANDROID_SDK_CHECKSUM = ecb29358bc0f13d7c2fa0f9290135a5b608e38434aad9bf7067d0252c160853e
	endif
endif
ifndef OSNAME
	$(error Your OS is not supported by this makefile)
endif

# Project root directory
PROJECT_ROOT = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Android SDK locations
export ANDROID_HOME ?= $(HOME)/Android/Sdk
ANDROID_SDK_ZIP = sdk-tools-$(OSNAME)-$(ANDROID_SDK_VERSION).zip
ANDROID_SDK_URL = https://dl.google.com/android/repository/$(ANDROID_SDK_ZIP)

# Flutter SDK locations
ifeq (, $(shell which flutter))
	FLUTTER_HOME ?= $(HOME)/Android/flutter
else
	FLUTTER_HOME ?= $(patsubst %/bin/flutter,%,$(shell which flutter))
endif
FLUTTER_TARBALL = flutter_$(FLUTTER_OS)_v$(FLUTTER_VERSION).tar.xz
FLUTTER_URL = https://storage.googleapis.com/flutter_infra/releases/stable/$(FLUTTER_OS)/$(FLUTTER_TARBALL)

# Go binary setup
GOLANG_TARBALL=go$(GOLANG_VERSION).$(OSNAME)-amd64.tar.gz
GOLANG_URL=https://dl.google.com/go/$(GOLANG_TARBALL)
GOLANG_DEP_URL=https://github.com/golang/dep/releases/download/v$(GOLANG_DEP_VERSION)/dep-$(OSNAME)-amd64
export GOPATH ?= "$(patsubst %/src/github.com/privacybydesign/irmamobile/,%,$(PROJECT_ROOT))"
ifeq (, $(shell which go))
	export GOROOT ?= $(abspath gobuild/go)
else
	export GOROOT ?= $(shell go env GOROOT)
endif

# Target to build android apk
apk: flutter-pub-get irmagobridge-android
	flutter build apk

# Target to get flutter/dart dependencies
flutter-pub-get: flutter-sdk
	flutter pub get

# Target for building the android version of the irmagobridge
irmagobridge-android: android/irmagobridge/irmagobridge.aar
android/irmagobridge/irmagobridge.aar: android-ndk dep-ensure gomobile-init
	$(GOPATH)/bin/gomobile bind -target android -o android/irmagobridge/irmagobridge.aar github.com/privacybydesign/irmamobile/irmagobridge

# Target to clean the android version of the irmagobridge
clean-irmagobridge-android:
	rm -rf android/irmagobridge/irmagobridge.aar

# Target for initializing gomobile
gomobile-init: gomobile
	$(GOPATH)/bin/gomobile init

# Target for installing gomobile
gomobile: golang $(GOPATH)/bin/gomobile
$(GOPATH)/bin/gomobile: $(GOPATH)/pkg/$(OSNAME)_amd64/golang.org/x/tools/go/packages.a
	$(GOROOT)/bin/go get -u golang.org/x/mobile/cmd/gomobile
$(GOPATH)/pkg/$(OSNAME)_amd64/golang.org/x/tools/go/packages.a:
	$(GOROOT)/bin/go get -u golang.org/x/tools/go/packages

# Target for cleaning gomobile
clean-gomobile: clean-go-tools-packages
	rm -rf $(GOPATH)/bin/gomobile
	rm -rf $(GOPATH)/src/golang.org/x/mobile/cmd/gomobile
clean-go-tools-packages:
	rm -rf $(GOPATH)/src/golang.org/x/tools/go/packages
	rm -rf $(GOPATH/pkg/$(OSNAME)_amd64/golang.org/x/tools/go/packages.a

# Target for running dep ensure
dep-ensure: dep
ifeq (, $(shell which dep))
	gobuild/dep ensure
else
	dep ensure
endif


# Target for installing a local dep
dep: gobuild/dep
gobuild/dep: golang
ifeq (, $(shell which dep))
	curl -L -o gobuild/dep $(GOLANG_DEP_URL)
	echo "$(GOLANG_DEP_CHECKSUM) *gobuild/dep" | sha256sum -c
	chmod +x gobuild/dep
else
	$(info Not installing local dep, using dep found in $$PATH)
endif

# Target for installing a global dep
install-dep: /usr/local/bin/dep
/usr/local/bin/dep: install-golang
	curl -L -o /usr/local/bin/dep $(GOLANG_DEP_URL)
	echo "$(GOLANG_DEP_CHECKSUM) */usr/local/bin/dep" | sha256sum -c
	chmod +x /usr/local/bin/dep

# Target for installing a local go
golang: gobuild/go/bin/go
gobuild/go/bin/go:
ifeq (, $(shell which go))
	mkdir -p gobuild/
	curl -L -o gobuild/$(GOLANG_TARBALL) $(GOLANG_URL)
	echo "$(GOLANG_CHECKSUM) *gobuild/$(GOLANG_TARBALL)" | sha256sum -c
	tar -xf gobuild/$(GOLANG_TARBALL) -C gobuild/
	rm -f gobuild/$(GOLANG_TARBALL)
else
	$(info Not installing local go, using go found in $$PATH)
endif

# Target for installing a global go
install-golang: /opt/go/bin/go
/opt/go/bin/go:
	curl -L -o /tmp/$(GOLANG_TARBALL) $(GOLANG_URL)
	echo "$(GOLANG_CHECKSUM) */tmp/$(GOLANG_TARBALL)" | sha256sum -c
	mkdir -p /opt
	tar -xf /tmp/$(GOLANG_TARBALL) -C /opt
	rm -f /tmp/$(GOLANG_TARBALL)

# Target for removing the local dep
clean-dep:
	rm -f gobuild/dep

# Target for removing the local golang
clean-golang:
	rm -rf gobuild/go
	rm -f gobuild/$(GOLANG_TARBALL)

# Target for upgrading flutter and android SDKs
flutter-android-sdk-upgrade: clean-flutter-sdk clean-android-sdk flutter-android-sdk

# Combined target for flutter and android SDKs
flutter-android-sdk: android-sdk android-ndk flutter-sdk

# Target for installing the Flutter SDK
flutter-sdk:
	[ ! -f "$(FLUTTER_HOME)/bin/flutter" ] && { \
		mkdir -p "$(FLUTTER_HOME)" && \
		curl -L -o "$(FLUTTER_TARBALL)" "$(FLUTTER_URL)" && \
		echo "$(FLUTTER_CHECKSUM) *$(FLUTTER_TARBALL)" | sha256sum -c && \
        tar -xf "$(FLUTTER_TARBALL)" && \
        rm -rf $(FLUTTER_HOME) && \
        mv flutter $(FLUTTER_HOME) && \
        rm -f $(FLUTTER_TARBALL); \
	} || true
	$(FLUTTER_HOME)/bin/flutter doctor

# Target for removing the Flutter SDK
clean-flutter-sdk:
	rm -rf $(FLUTTER_HOME)

# Target for installing the Android NDK
android-ndk: android-sdk
	yes | "$(ANDROID_HOME)/tools/bin/sdkmanager" "ndk-bundle" "cmake;$(ANDROID_CMAKE_VERSION)" \
		"lldb;$(ANDROID_LLDB_VERSION)"
	yes | "$(ANDROID_HOME)/tools/bin/sdkmanager" --licenses

# Target for installing the Android SDK
android-sdk: android-sdk-base
	yes | "$(ANDROID_HOME)/tools/bin/sdkmanager" --update
	yes | "$(ANDROID_HOME)/tools/bin/sdkmanager" "platform-tools"
	yes | "$(ANDROID_HOME)/tools/bin/sdkmanager" $(ANDROID_SDK_PACKAGES)
	yes | "$(ANDROID_HOME)/tools/bin/sdkmanager" --licenses
android-sdk-base:
	mkdir -p "$(ANDROID_HOME)"
	[ ! -f "$(ANDROID_HOME)/tools/bin/sdkmanager" ] && { \
		curl -L -o "$(ANDROID_HOME)/$(ANDROID_SDK_ZIP)" "$(ANDROID_SDK_URL)" && \
		echo "$(ANDROID_SDK_CHECKSUM) *$(ANDROID_HOME)/$(ANDROID_SDK_ZIP)" | sha256sum -c && \
        unzip -q "$(ANDROID_HOME)/$(ANDROID_SDK_ZIP)" -d "$(ANDROID_HOME)" && \
        rm -f "$(ANDROID_HOME)/$(ANDROID_SDK_ZIP)"; \
    } || true

# Target for removing the Android SDK
clean-android-sdk:
	rm -rf $(ANDROID_HOME)
