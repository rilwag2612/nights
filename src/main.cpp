#include <SDL.h>
#include <SDL_image.h>
#include <SDL_ttf.h>
#include <stdio.h>
#include <vector>
#include <string>
#include <cstdlib>

#include "imgui.h"
#include "backends/imgui_impl_sdl2.h"
#include "backends/imgui_impl_sdlrenderer2.h"

// ------------------------
// Cross-platform URL opener
// ------------------------
void OpenURL(const std::string& url) {
#if defined(_WIN32)
    system(("start " + url).c_str());
#elif defined(__APPLE__)
    system(("open " + url).c_str());
#else
    system(("xdg-open " + url).c_str());
#endif
}

// ------------------------
// Cross-platform Legal Notice popup
// ------------------------
void ShowLegalNotice(SDL_Window* window) {
    const SDL_MessageBoxButtonData buttons[] = {
        { SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT, 1, "I acknowledge" },
        { 0, 2, "View Full Notice" },
        { SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT, 0, "Exit" }
    };

    SDL_MessageBoxData msg{};
    msg.flags = SDL_MESSAGEBOX_INFORMATION;
    msg.window = window;
    msg.title  = "⚖️ Legal Notice";
    msg.message =
        "Five Nights at Freddy’s is a copyrighted property of Scott Cawthon.\n"
        "Fan-made projects must remain free and non-commercial.\n\n"
        "Select 'View Full Notice' to read the complete policy on GitHub.";
    msg.numbuttons = SDL_arraysize(buttons);
    msg.buttons = buttons;

    int buttonid;
    if (SDL_ShowMessageBox(&msg, &buttonid) == 0) {
        switch (buttonid) {
            case 2:
                OpenURL("https://github.com/rilwag2612/nights#legal-notice");
                ShowLegalNotice(window); // reopen after viewing
                break;
            case 0:
                SDL_Quit();
                std::exit(0);
                break;
            default:
                break; // acknowledged
        }
    }
}

// ------------------------
// Tutorial placeholder
// ------------------------
void tutorial() {
    printf("Tutorial function called (Placeholder)\n");
}

// ------------------------
// Main
// ------------------------
int main(int argc, char* argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        printf("SDL_Init Error: %s\n", SDL_GetError());
        return 1;
    }

    if (!(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG)) {
        printf("IMG_Init Error: %s\n", IMG_GetError());
        SDL_Quit();
        return 1;
    }

    const int windowWidth = 1200;
    const int windowHeight = 1000;

    SDL_Window* window = SDL_CreateWindow(
        "FNaF N.I.G.H.T.S.",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        windowWidth,
        windowHeight,
        SDL_WINDOW_SHOWN
    );

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    // --- OS Popup first ---
    ShowLegalNotice(window);

    // --- Setup ImGui ---
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui_ImplSDL2_InitForSDLRenderer(window, renderer);
    ImGui_ImplSDLRenderer2_Init(renderer);

    // --- Load textures ---
    SDL_Texture* logoTex = IMG_LoadTexture(renderer, "assets/nights_logo.png");
    SDL_Texture* freddyTex = IMG_LoadTexture(renderer, "assets/sprites/freddy.png");
    SDL_Texture* bonnieTex = IMG_LoadTexture(renderer, "assets/sprites/bonnie.png");
    SDL_Texture* chicaTex = IMG_LoadTexture(renderer, "assets/sprites/chica.png");
    SDL_Texture* foxyTex = IMG_LoadTexture(renderer, "assets/sprites/foxy.png");
    SDL_Texture* goldenFreddyTex = IMG_LoadTexture(renderer, "assets/sprites/golden_freddy.png");
    SDL_Texture* endoTex = IMG_LoadTexture(renderer, "assets/sprites/endo.png");

    std::vector<SDL_Texture*> animatronicTextures = {
        freddyTex, bonnieTex, chicaTex, foxyTex, goldenFreddyTex
    };
    const int numAnimatronics = animatronicTextures.size();

    // --- Positioning Endo ---
    int endoW, endoH;
    SDL_QueryTexture(endoTex, nullptr, nullptr, &endoW, &endoH);
    const int endoTargetH = 300;
    const int endoWScaled = (int)((float)endoW * endoTargetH / endoH);
    SDL_Rect endoRect = { (windowWidth - endoWScaled)/2, 50, endoWScaled, endoTargetH };

    // --- Animatronics row ---
    const int animH = 150;
    const int spacing = 20;
    std::vector<SDL_Rect> animRects(numAnimatronics);
    int totalWidth = 0;

    for (int i = 0; i < numAnimatronics; ++i) {
        int w = 100, h = 100;
        if (animatronicTextures[i]) SDL_QueryTexture(animatronicTextures[i], nullptr, nullptr, &w, &h);
        animRects[i].h = animH;
        animRects[i].w = (int)((float)w * animH / h);
        totalWidth += animRects[i].w;
    }
    totalWidth += spacing * (numAnimatronics -1);
    int startX = (windowWidth - totalWidth)/2;
    int rowY = endoRect.y + endoRect.h + 30;
    int currentX = startX;
    for (int i=0;i<numAnimatronics;i++){
        animRects[i].x = currentX;
        animRects[i].y = rowY;
        currentX += animRects[i].w + spacing;
    }

    // --- Logo ---
    int logoW, logoH;
    SDL_QueryTexture(logoTex, nullptr, nullptr, &logoW, &logoH);
    const int logoDisplayW = 400;
    const int logoDisplayH = (int)((float)logoH * logoDisplayW / logoW);
    SDL_Rect logoRectBottom = { (windowWidth - logoDisplayW)/2, rowY + animH + 20, logoDisplayW, logoDisplayH };

    // --- Loading bar ---
    const int barW = 300, barH = 20;
    SDL_Rect loadingBarBg = { (windowWidth - barW)/2, logoRectBottom.y + logoDisplayH + 20, barW, barH };
    SDL_Rect loadingBarFg = loadingBarBg;
    loadingBarFg.w = 0;

    // --- Main loop ---
    bool running = true;
    SDL_Event event;
    Uint32 lastTime = SDL_GetTicks();
    float loadingProgress = 0.0f;

    while (running){
        Uint32 now = SDL_GetTicks();
        float dt = (now - lastTime)/1000.f;
        lastTime = now;

        while(SDL_PollEvent(&event)){
            ImGui_ImplSDL2_ProcessEvent(&event);
            if(event.type==SDL_QUIT) running=false;
        }

        // Update loading bar
        if(loadingProgress<1.0f){
            loadingProgress += 0.2f*dt; // speed
            if(loadingProgress>1.0f) loadingProgress=1.0f;
        }
        loadingBarFg.w = (int)(loadingBarBg.w * loadingProgress);

        ImGui_ImplSDLRenderer2_NewFrame();
        ImGui_ImplSDL2_NewFrame();
        ImGui::NewFrame();
        ImGui::Render();

        // --- Render ---
        SDL_SetRenderDrawColor(renderer, 30,30,30,255);
        SDL_RenderClear(renderer);

        if (endoTex) SDL_RenderCopy(renderer, endoTex, nullptr, &endoRect);
        for(int i=0;i<numAnimatronics;i++)
            if(animatronicTextures[i]) SDL_RenderCopy(renderer, animatronicTextures[i], nullptr, &animRects[i]);
        SDL_RenderCopy(renderer, logoTex, nullptr, &logoRectBottom);

        SDL_SetRenderDrawColor(renderer, 50,50,50,255);
        SDL_RenderFillRect(renderer, &loadingBarBg);
        SDL_SetRenderDrawColor(renderer, 255,255,0,255);
        SDL_RenderFillRect(renderer, &loadingBarFg);

        ImGui_ImplSDLRenderer2_RenderDrawData(ImGui::GetDrawData(), renderer);
        SDL_RenderPresent(renderer);
    }

    // --- Cleanup ---
    for(auto t: animatronicTextures) if(t) SDL_DestroyTexture(t);
    if(logoTex) SDL_DestroyTexture(logoTex);
    if(endoTex) SDL_DestroyTexture(endoTex);

    ImGui_ImplSDLRenderer2_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    IMG_Quit();
    SDL_Quit();
    return 0;
}
