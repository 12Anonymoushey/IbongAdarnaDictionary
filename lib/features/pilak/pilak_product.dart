enum PilakProductCategory { theme, feature, material }

class PilakProduct {
  const PilakProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    this.assetPath,
    this.themeId,
  });

  final String id;
  final String name;
  final int price;
  final String description;
  final PilakProductCategory category;
  final String? assetPath;
  final String? themeId;
}

const pilakProducts = <PilakProduct>[
  PilakProduct(
    id: 'theme_armenya_forest',
    name: 'Armenya Forest',
    price: 300,
    description: 'Tema na may malalalim na kulay ng kagubatan.',
    category: PilakProductCategory.theme,
    themeId: 'armenya_forest',
  ),
  PilakProduct(
    id: 'theme_berbanya_crimson',
    name: 'Berbanya Crimson',
    price: 300,
    description: 'Maharlikang pulang tema para sa kaharian ng Berbanya.',
    category: PilakProductCategory.theme,
    themeId: 'berbanya_crimson',
  ),
  PilakProduct(
    id: 'theme_cave_ermitanyo',
    name: 'Cave of the Ermitanyo',
    price: 500,
    description: 'Purong itim na tema para sa mga OLED screen.',
    category: PilakProductCategory.theme,
    themeId: 'cave_ermitanyo',
  ),
  PilakProduct(
    id: 'theme_sepia_manuscript',
    name: 'Sepia Manuscript',
    price: 800,
    description: 'Mainit at papel na kulay na parang sinaunang manuskrito.',
    category: PilakProductCategory.theme,
    themeId: 'sepia_manuscript',
  ),
  PilakProduct(
    id: 'theme_typewriter_typography',
    name: 'Typewriter Typography',
    price: 1000,
    description: 'Monospace na titik para sa buong interface.',
    category: PilakProductCategory.theme,
    themeId: 'typewriter_typography',
  ),
  PilakProduct(
    id: 'theme_piedras_gold',
    name: 'Piedras Platas Gold',
    price: 1500,
    description: 'Matingkad na gintong kulay para sa mahahalagang bahagi.',
    category: PilakProductCategory.theme,
    themeId: 'piedras_platas_gold',
  ),
  PilakProduct(
    id: 'theme_cristales_glass',
    name: 'Reyno de los Cristales',
    price: 2000,
    description: 'Malamig at mala-kristal na kulay ng kaharian.',
    category: PilakProductCategory.theme,
    themeId: 'cristales_glass',
  ),
  PilakProduct(
    id: 'theme_8bit_retro',
    name: '8-Bit Retro Mode',
    price: 4500,
    description: 'Matitingkad na pixel-inspired na kulay at parisukat na card.',
    category: PilakProductCategory.theme,
    themeId: '8bit_retro',
  ),
  PilakProduct(
    id: 'theme_colonial_calligraphy',
    name: 'Colonial Calligraphy',
    price: 5000,
    description: 'Serif na titik na hango sa mga lumang aklat.',
    category: PilakProductCategory.theme,
    themeId: 'colonial_calligraphy',
  ),
  PilakProduct(
    id: 'theme_baybayin_overlay',
    name: 'Baybayin Script Overlay',
    price: 7500,
    description: 'Baybayin-inspired na estilong biswal para sa interface.',
    category: PilakProductCategory.theme,
    themeId: 'baybayin_overlay',
  ),
  PilakProduct(
    id: 'streak_freeze',
    name: 'Streak Freeze',
    price: 250,
    description: 'Pinananatili ang kasalukuyang streak sa loob ng 24 oras.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'quiz_decay_reset',
    name: 'Quiz Decay Reset',
    price: 400,
    description: 'Isang beses na hindi isasama ang quiz decay penalty.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'home_screen_widget',
    name: 'Home Screen Widget',
    price: 1200,
    description: 'Ina-unlock ang card ng Word of the Day sa app.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'advanced_sql_filters',
    name: 'Advanced SQL Filters',
    price: 1500,
    description:
        'Nagbibigay-daan sa pagsala ayon sa kabanata at bahagi ng pananalita.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'local_sqlite_backup',
    name: 'Local SQLite Backup',
    price: 2000,
    description: 'Ina-unlock ang paggawa ng kopya ng lokal na database.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'night_mode_scheduler',
    name: 'Night Mode Scheduler',
    price: 2500,
    description: 'Awtomatikong nagpapadilim ng tema mula alas-sais ng gabi.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'custom_quiz_architect',
    name: 'Custom Quiz Architect',
    price: 3500,
    description: 'Ina-unlock ang quiz na nakatuon sa mga napiling kabanata.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'audio_pronunciation',
    name: 'Audio Pronunciation',
    price: 5000,
    description:
        'Ina-unlock ang bigkas ng mga salita gamit ang text-to-speech.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'csv_bulk_exporter',
    name: 'CSV Bulk Exporter',
    price: 8000,
    description:
        'Ina-unlock ang pag-export ng mga naka-save na salita bilang CSV.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'spaced_repetition_engine',
    name: 'Spaced Repetition Engine',
    price: 12000,
    description: 'Ina-unlock ang pag-aaral na inuuna ang mga maling sagot.',
    category: PilakProductCategory.feature,
  ),
  PilakProduct(
    id: 'blank_study_worksheets',
    name: 'Blank Study Worksheets',
    price: 300,
    description: 'PDF ng mga blangkong talahanayan para sa pag-aaral.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/blank_study_worksheets.pdf',
  ),
  PilakProduct(
    id: 'pixel_art_wallpapers',
    name: 'Pixel Art Wallpapers',
    price: 500,
    description: 'ZIP na may sampung mobile wallpaper.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/pixel_art_wallpapers.zip',
  ),
  PilakProduct(
    id: 'a4_flashcards_basic',
    name: 'A4 Flashcards Basic',
    price: 1000,
    description: 'Napi-print na PDF ng 50 karaniwang salita.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/a4_flashcards_basic.pdf',
  ),
  PilakProduct(
    id: 'low_poly_don_juan',
    name: 'Low-Poly Don Juan',
    price: 1200,
    description: 'Template na papel na modelo ni Don Juan.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/low_poly_don_juan.pdf',
  ),
  PilakProduct(
    id: 'low_poly_adarna',
    name: 'Low-Poly Ibong Adarna',
    price: 1500,
    description: 'Template ng Ibong Adarna na may mga tupi ng pakpak.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/low_poly_adarna.pdf',
  ),
  PilakProduct(
    id: 'character_alliance_map',
    name: 'Character Alliance Map',
    price: 2000,
    description: 'Tsart ng mga ugnayan at pagtataksil ng mga tauhan.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/character_alliance_map.pdf',
  ),
  PilakProduct(
    id: 'geographical_realm_map',
    name: 'Geographical Realm Map',
    price: 2500,
    description: 'Mapa ng mga kahariang binagtas sa kuwento.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/geographical_realm_map.pdf',
  ),
  PilakProduct(
    id: 'full_400_word_flashcards',
    name: 'Full 400-Word Flashcards',
    price: 4000,
    description: 'Napi-print na flashcard set mula sa talahuluganan.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/full_400_word_flashcards.pdf',
  ),
  PilakProduct(
    id: 'complete_plot_flowchart',
    name: 'Complete Plot Flowchart',
    price: 6000,
    description: 'Daloy ng mga pangyayari sa 46 kabanata.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/complete_plot_flowchart.pdf',
  ),
  PilakProduct(
    id: 'teacher_answer_keys',
    name: 'Teacher Answer Keys',
    price: 10000,
    description: 'Mga gabay sa sagot para sa mga gawaing pangklase.',
    category: PilakProductCategory.material,
    assetPath: 'assets/marketplace/teacher_answer_keys.pdf',
  ),
];

const pilakThemeIds = <String>{
  'armenya_forest',
  'berbanya_crimson',
  'cave_ermitanyo',
  'sepia_manuscript',
  'typewriter_typography',
  'piedras_platas_gold',
  'cristales_glass',
  '8bit_retro',
  'colonial_calligraphy',
  'baybayin_overlay',
};

PilakProduct? pilakProductById(String id) {
  for (final product in pilakProducts) {
    if (product.id == id) return product;
  }
  return null;
}
