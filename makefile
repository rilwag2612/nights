# -----------------------------
# Detect platform
# -----------------------------
UNAME_S := $(shell uname -s)

# -----------------------------
# Compiler and flags
# -----------------------------
CXX := clang++
CXXFLAGS := -std=c++17 -Wall -I./src -I./src/imgui -I./src/imgui/backends
LDFLAGS :=

# -----------------------------
# Platform-specific SDL2 detection
# -----------------------------
ifeq ($(UNAME_S),Darwin)
    # Will adjust architecture in targets
    BREW_PREFIX_ARM ?= /opt/homebrew
    BREW_PREFIX_INTEL ?= /usr/local

    SDL2_FLAGS_ARM  := -I$(BREW_PREFIX_ARM)/include/SDL2
    SDL2_LIBS_ARM   := -L$(BREW_PREFIX_ARM)/lib -lSDL2
    IMG_FLAGS_ARM   := -I$(BREW_PREFIX_ARM)/opt/sdl2_image/include
    IMG_LIBS_ARM    := -L$(BREW_PREFIX_ARM)/opt/sdl2_image/lib -lSDL2_image
    MIX_FLAGS_ARM   := -I$(BREW_PREFIX_ARM)/opt/sdl2_mixer/include
    MIX_LIBS_ARM    := -L$(BREW_PREFIX_ARM)/opt/sdl2_mixer/lib -lSDL2_mixer
    TTF_FLAGS_ARM   := -I$(BREW_PREFIX_ARM)/opt/sdl2_ttf/include
    TTF_LIBS_ARM    := -L$(BREW_PREFIX_ARM)/opt/sdl2_ttf/lib -lSDL2_ttf

    SDL2_FLAGS_INTEL  := -I$(BREW_PREFIX_INTEL)/include/SDL2
    SDL2_LIBS_INTEL   := -L$(BREW_PREFIX_INTEL)/lib -lSDL2
    IMG_FLAGS_INTEL   := -I$(BREW_PREFIX_INTEL)/opt/sdl2_image/include
    IMG_LIBS_INTEL    := -L$(BREW_PREFIX_INTEL)/opt/sdl2_image/lib -lSDL2_image
    MIX_FLAGS_INTEL   := -I$(BREW_PREFIX_INTEL)/opt/sdl2_mixer/include
    MIX_LIBS_INTEL    := -L$(BREW_PREFIX_INTEL)/opt/sdl2_mixer/lib -lSDL2_mixer
    TTF_FLAGS_INTEL   := -I$(BREW_PREFIX_INTEL)/opt/sdl2_ttf/include
    TTF_LIBS_INTEL    := -L$(BREW_PREFIX_INTEL)/opt/sdl2_ttf/lib -lSDL2_ttf
endif

# -----------------------------
# Sources
# -----------------------------
IMGUI_SOURCES = \
	src/imgui/imgui.cpp \
	src/imgui/imgui_draw.cpp \
	src/imgui/imgui_widgets.cpp \
	src/imgui/imgui_tables.cpp \
	src/imgui/backends/imgui_impl_sdl2.cpp \
	src/imgui/backends/imgui_impl_sdlrenderer2.cpp

SRC = src/main.cpp
TARGET = Nights

# -----------------------------
# macOS bundle paths
# -----------------------------
BUNDLE_DIR = bundle/$(TARGET).app/Contents
BUNDLE_MACOS = $(BUNDLE_DIR)/MacOS
BUNDLE_RESOURCES = $(BUNDLE_DIR)/Resources/assets
ICON_SRC = .github/assets/logo.png
ICON_NAME = MyIcon.icns
PLIST_SRC = src/macos.plist

# -----------------------------
# Default target
# -----------------------------
all: macos-fat

# -----------------------------
# macOS ARM build
# -----------------------------
macos-arm:
	@echo "Building arm64..."
	@mkdir -p build/arm64
	$(CXX) $(CXXFLAGS) $(SDL2_FLAGS_ARM) $(IMG_FLAGS_ARM) $(MIX_FLAGS_ARM) $(TTF_FLAGS_ARM) -arch arm64 $(SRC) $(IMGUI_SOURCES) $(SDL2_LIBS_ARM) $(IMG_LIBS_ARM) $(MIX_LIBS_ARM) $(TTF_LIBS_ARM) -o build/arm64/$(TARGET)
	$(MAKE) bundle TARGET_PATH=build/arm64/$(TARGET) ARCH=arm64

# -----------------------------
# macOS Intel build
# -----------------------------
macos-intel:
	@echo "Building x86_64..."
	@mkdir -p build/x86_64
	$(CXX) $(CXXFLAGS) $(SDL2_FLAGS_INTEL) $(IMG_FLAGS_INTEL) $(MIX_FLAGS_INTEL) $(TTF_FLAGS_INTEL) -arch x86_64 $(SRC) $(IMGUI_SOURCES) $(SDL2_LIBS_INTEL) $(IMG_LIBS_INTEL) $(MIX_LIBS_INTEL) $(TTF_LIBS_INTEL) -o build/x86_64/$(TARGET)
	$(MAKE) bundle TARGET_PATH=build/x86_64/$(TARGET) ARCH=x86_64

# -----------------------------
# macOS fat build
# -----------------------------
macos-fat: macos-arm macos-intel
	@echo "Creating universal binary..."
	@mkdir -p build/universal
	lipo -create build/arm64/$(TARGET) build/x86_64/$(TARGET) -output build/universal/$(TARGET)
	$(MAKE) bundle TARGET_PATH=build/universal/$(TARGET) ARCH=fat

# -----------------------------
# Bundle
# -----------------------------
bundle:
	@echo "Creating bundle for $(ARCH)..."
	@mkdir -p $(BUNDLE_MACOS) $(BUNDLE_RESOURCES)/sprites
	cp "$(TARGET_PATH)" "$(BUNDLE_MACOS)/"
	cp assets/nights_logo.png "$(BUNDLE_RESOURCES)/"
	cp assets/sprites/* "$(BUNDLE_RESOURCES)/sprites/"
	cp "$(PLIST_SRC)" "$(BUNDLE_DIR)/Info.plist"

	# Generate .icns
	@rm -rf MyIcon.iconset
	@mkdir MyIcon.iconset
	@sips -z 16 16   "$(ICON_SRC)" --out MyIcon.iconset/icon_16x16.png
	@sips -z 32 32   "$(ICON_SRC)" --out MyIcon.iconset/icon_16x16@2x.png
	@sips -z 32 32   "$(ICON_SRC)" --out MyIcon.iconset/icon_32x32.png
	@sips -z 64 64   "$(ICON_SRC)" --out MyIcon.iconset/icon_32x32@2x.png
	@sips -z 128 128 "$(ICON_SRC)" --out MyIcon.iconset/icon_128x128.png
	@sips -z 256 256 "$(ICON_SRC)" --out MyIcon.iconset/icon_128x128@2x.png
	@sips -z 256 256 "$(ICON_SRC)" --out MyIcon.iconset/icon_256x256.png
	@sips -z 512 512 "$(ICON_SRC)" --out MyIcon.iconset/icon_256x256@2x.png
	@sips -z 512 512 "$(ICON_SRC)" --out MyIcon.iconset/icon_512x512.png
	@cp "$(ICON_SRC)" MyIcon.iconset/icon_512x512@2x.png
	@iconutil -c icns MyIcon.iconset -o "$(BUNDLE_DIR)/Resources/$(ICON_NAME)"
	@rm -rf MyIcon.iconset
	@echo "Bundle created at $(BUNDLE_DIR)"

# -----------------------------
# Clean
# -----------------------------
clean:
	rm -rf build/*
	rm -rf bundle/*

.PHONY: all clean macos-arm macos-intel macos-fat bundle
