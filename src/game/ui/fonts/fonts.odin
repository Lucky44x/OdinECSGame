package uifonts

import "../../../resource"

FONT_ID_BODY_16 :: 0
FONT_ID_BODY_24 :: 8
FONT_ID_BODY_28 :: 7
FONT_ID_BODY_30 :: 6
FONT_ID_BODY_36 :: 5
FONT_ID_TITLE_32 :: 4
FONT_ID_TITLE_36 :: 3
FONT_ID_TITLE_48 :: 2
FONT_ID_TITLE_52 :: 1
FONT_ID_TITLE_56 :: 9

load_fonts :: proc() {
    resource.LoadFont(FONT_ID_TITLE_32, 32, "./assets/fonts/neue_regarde_semb.otf")
    resource.LoadFont(FONT_ID_TITLE_36, 32, "./assets/fonts/neue_regarde_semb.otf")
    resource.LoadFont(FONT_ID_TITLE_48, 32, "./assets/fonts/neue_regarde_semb.otf")
    resource.LoadFont(FONT_ID_TITLE_52, 32, "./assets/fonts/neue_regarde_semb.otf")
    resource.LoadFont(FONT_ID_TITLE_56, 32, "./assets/fonts/neue_regarde_semb.otf")

    resource.LoadFont(FONT_ID_BODY_16, 16, "./assets/fonts/neue_regarde_med.otf")
    resource.LoadFont(FONT_ID_BODY_24, 24, "./assets/fonts/neue_regarde_med.otf")
    resource.LoadFont(FONT_ID_BODY_28, 28, "./assets/fonts/neue_regarde_med.otf")
    resource.LoadFont(FONT_ID_BODY_30, 30, "./assets/fonts/neue_regarde_med.otf")
    resource.LoadFont(FONT_ID_BODY_36, 36, "./assets/fonts/neue_regarde_med.otf")
}