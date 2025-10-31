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
    SDL2_CFLAGS  := $(shell sdl2-config --cflags)
    SDL2_LDFLAGS := $(shell sdl2-config --libs)
    
    IMGFLAGS  := -I$(shell brew --prefix sdl2_image)/include
    IMGLIBS   := -L$(shell brew --prefix sdl2_image)/lib -lSDL2_image

    MIXFLAGS  := -I$(shell brew --prefix sdl2_mixer)/include
    MIXLIBS   := -L$(shell brew --prefix sdl2_mixer)/lib -lSDL2_mixer

    TTFFLAGS  := -I$(shell brew --prefix sdl2_ttf)/include
    TTFLIBS   := -L$(shell brew --prefix sdl2_ttf)/lib -lSDL2_ttf

    CXXFLAGS += $(SDL2_CFLAGS) $(IMGFLAGS) $(MIXFLAGS) $(TTFFLAGS) -arch arm64
    LDFLAGS  += $(SDL2_LDFLAGS) $(IMGLIBS) $(MIXLIBS) $(TTFLIBS) -arch arm64
else ifeq ($(UNAME_S),Linux)
    CXXFLAGS += $(shell pkg-config --cflags sdl2 SDL2_image SDL2_mixer SDL2_ttf)
    LDFLAGS  += $(shell pkg-config --libs sdl2 SDL2_image SDL2_mixer SDL2_ttf)
else
    SDL2_PREFIX := C:/SDL2
    CXXFLAGS += -I$(SDL2_PREFIX)/include
    LDFLAGS  += -L$(SDL2_PREFIX)/lib -lmingw32 -lSDL2main -lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf
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
TARGET = FNaF N.I.G.H.T.S.
TARGET_DEST = build/$(TARGET)

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
all: "$(TARGET)"

"$(TARGET)": $(SRC) $(IMGUI_SOURCES)
	@mkdir -p build
	$(CXX) $(CXXFLAGS) $(SRC) $(IMGUI_SOURCES) $(LDFLAGS) -o "$(TARGET_DEST)"

# -----------------------------
# Clean
# -----------------------------
clean:
	rm -rf build/*
	rm -rf bundle/*

# -----------------------------
# macOS Bundle
# -----------------------------
bundle: "$(TARGET)"
	@echo "Creating macOS app bundle..."
	@mkdir -p "$(BUNDLE_MACOS)" "$(BUNDLE_RESOURCES)/sprites"
	cp "$(TARGET_DEST)" "$(BUNDLE_MACOS)/"
	cp assets/nights_logo.png "$(BUNDLE_RESOURCES)/"
	cp assets/sprites/* "$(BUNDLE_RESOURCES)/sprites/"

	# Copy user-provided plist
	cp "$(PLIST_SRC)" "$(BUNDLE_DIR)/Info.plist"

	# Generate .icns icon
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
	@echo "App icon generated at $(BUNDLE_DIR)/Resources/$(ICON_NAME)"

	@echo "Bundle created at $(BUNDLE_DIR)"

.PHONY: all clean bundle
