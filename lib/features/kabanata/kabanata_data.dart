class Kabanata {
  const Kabanata({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  String get label => 'Kabanata $number: $title';

  String get imagePath => switch (number % 3) {
    0 => 'assets/images/ibong_adarna.png',
    1 => 'assets/images/adarna.png',
    _ => 'assets/images/piedras_platas.png',
  };
}

const kabanataList = <Kabanata>[
  Kabanata(
    number: 1,
    title: 'Ang Berbanya',
    description: 'Ipinakikilala ang kaharian ng Berbanya at ang pamilya ng Haring Fernando.',
  ),
  Kabanata(
    number: 2,
    title: 'Ang Karamdaman ni Don Fernando',
    description:
        'Nagkasakit ang hari, kaya naghanap ang kaniyang mga anak ng lunas.',
  ),
  Kabanata(
    number: 3,
    title: 'Ang Paglalakbay ni Don Pedro',
    description:
        'Nagsimula si Don Pedro sa paglalakbay upang hanapin ang Ibong Adarna.',
  ),
  Kabanata(
    number: 4,
    title: 'Ang Kabiguan ni Don Pedro',
    description: 'Nabigo si Don Pedro sa paghuli sa ibon at hindi niya nagamot ang hari.',
  ),
  Kabanata(
    number: 5,
    title: 'Ang Paglalakbay ni Don Juan',
    description:
        'Naglakbay si Don Juan upang hanapin ang lunas para sa kaniyang ama.',
  ),
  Kabanata(
    number: 6,
    title: 'Ang Leprosong Ermitanyo',
    description: 'Tinulungan ni Don Juan ang isang ermitanyong may ketong at ginantimpalaan siya nito.',
  ),
  Kabanata(
    number: 7,
    title: 'Ang Ibong Adarna',
    description:
        'Natagpuan ni Don Juan ang mahiwagang ibon at sinikap itong mahuli.',
  ),
  Kabanata(
    number: 8,
    title: 'Ang Pagligtas kay Don Diego at Don Pedro',
    description: 'Iniligtas ni Don Juan ang kaniyang mga kapatid at nahuli nila ang ibon.',
  ),
  Kabanata(
    number: 9,
    title: 'Ang Mahiwagang Katotohanan',
    description: 'Nabunyag ang tunay na nangyari sa paghuli sa Ibong Adarna.',
  ),
  Kabanata(
    number: 10,
    title: 'Ang Pagtataksil nina Don Pedro at Don Diego',
    description: 'Nagbalak sina Don Pedro at Don Diego laban kay Don Juan.',
  ),
  Kabanata(
    number: 11,
    title: 'Ang Panalangin ni Don Juan',
    description:
        'Dumulog si Don Juan sa panalangin sa gitna ng kaniyang paghihirap.',
  ),
  Kabanata(
    number: 12,
    title: 'Ang Pagliligtas kay Don Juan',
    description: 'Tinulungan ng isang matanda si Don Juan at pinagaling ang kaniyang mga sugat.',
  ),
  Kabanata(
    number: 13,
    title: 'Ang Pagbabalik ni Don Juan',
    description: 'Nagbalik si Don Juan sa Berbanya kasama ang Ibong Adarna.',
  ),
  Kabanata(
    number: 14,
    title: 'Ang Muling Pagtataksil',
    description: 'Muli na namang nagpakita ng inggit at pagtataksil ang mga kapatid ni Don Juan.',
  ),
  Kabanata(
    number: 15,
    title: 'Ang Muling Paglisan ni Don Juan',
    description: 'Iniwan ni Don Juan ang Berbanya at naglakbay patungo sa bagong kaharian.',
  ),
  Kabanata(
    number: 16,
    title: 'Ang Bagong Paraiso',
    description:
        'Natuklasan ni Don Juan ang isang kahanga-hanga at mahiwagang pook.',
  ),
  Kabanata(
    number: 17,
    title: 'Ang Mahiwagang Balon sa Armenya',
    description: 'Dumating si Don Juan sa Armenya at natagpuan ang isang mahiwagang balon.',
  ),
  Kabanata(
    number: 18,
    title: 'Ang Nakakaakit na si Donya Juana',
    description:
        'Nakilala ni Don Juan si Donya Juana at sinikap siyang iligtas.',
  ),
  Kabanata(
    number: 19,
    title: 'Ang Higanteng Bantay',
    description: 'Hinarap ni Don Juan ang higanteng nagbabantay sa kinaroroonan ni Donya Juana.',
  ),
  Kabanata(
    number: 20,
    title: 'Ang Prinsesang Mas Kaibig-ibig',
    description: 'Nakilala ni Don Juan si Donya Leonora, na higit pang nagpabago sa kaniyang kapalaran.',
  ),
  Kabanata(
    number: 21,
    title: 'Ang Serpyenteng may Pitong Ulo',
    description:
        'Nilabanan ni Don Juan ang nakatatakot na serpyenteng may pitong ulo.',
  ),
  Kabanata(
    number: 22,
    title: 'Ang Panibagong Panlilinlang',
    description: 'Muling nagsinungaling si Don Pedro upang agawin ang tagumpay ni Don Juan.',
  ),
  Kabanata(
    number: 23,
    title: 'Ang Lobong Engkantada',
    description: 'Tinulungan ng isang mahiwagang lobo si Don Juan sa kaniyang paghahanap.',
  ),
  Kabanata(
    number: 24,
    title: 'Ang Muling Pagkikita ng Ibong Adarna at ni Don Juan',
    description: 'Muling nagtagpo si Don Juan at ang Ibong Adarna, na nagbigay sa kaniya ng payo.',
  ),
  Kabanata(
    number: 25,
    title: 'Ang Bagong Mundo',
    description: 'Nagpatuloy si Don Juan sa paglalakbay at nakarating sa isang bagong daigdig.',
  ),
  Kabanata(
    number: 26,
    title: 'Ang Panangis ni Prinsesa Leonora',
    description:
        'Nagdalamhati si Prinsesa Leonora dahil sa pagkawala ni Don Juan.',
  ),
  Kabanata(
    number: 27,
    title: 'Ang Ikapitong Bundok',
    description:
        'Tinahak ni Don Juan ang ikapitong bundok sa kaniyang paghahanap.',
  ),
  Kabanata(
    number: 28,
    title: 'Ang Higanteng Agila',
    description: 'Nakatagpo ni Don Juan ang higanteng agilang tumulong sa kaniyang paglalakbay.',
  ),
  Kabanata(
    number: 29,
    title: 'Ang Reyno Delos Cristales',
    description: 'Nakarating si Don Juan sa kahanga-hangang kaharian ng Reyno Delos Cristales.',
  ),
  Kabanata(
    number: 30,
    title: 'Ang Prinsesang si Maria Blanca',
    description: 'Nakilala ni Don Juan si Prinsesa Maria Blanca at namagitan ang pag-ibig.',
  ),
  Kabanata(
    number: 31,
    title: 'Ang Ika-Unang Pagsubok ng Hari',
    description:
        'Iniharap ng hari kay Don Juan ang una sa mahihirap na pagsubok.',
  ),
  Kabanata(
    number: 32,
    title: 'Ang Ikalawang Utos ng Hari',
    description: 'Hinarap ni Don Juan ang ikalawang utos na ipinagawa ng hari.',
  ),
  Kabanata(
    number: 33,
    title: 'Ang Paglipat sa Bundok',
    description:
        'Sinubok ni Don Juan ang lakas at talino sa utos na ilipat ang bundok.',
  ),
  Kabanata(
    number: 34,
    title: 'Ang Paggawa ng Kastilyo',
    description:
        'Gumawa si Don Juan ng kastilyo bilang pagtupad sa isa pang pagsubok.',
  ),
  Kabanata(
    number: 35,
    title: 'Ang Nawawalang Singsing',
    description:
        'Hinanap ni Don Juan ang nawawalang singsing sa ilalim ng dagat.',
  ),
  Kabanata(
    number: 36,
    title: 'Ang Pag-Amo sa Kabayo',
    description:
        'Sinikap ni Don Juan na paamuin ang mabangis na kabayo ng hari.',
  ),
  Kabanata(
    number: 37,
    title: 'Ang Pagpili sa mga Prinsesa',
    description: 'Hinarap ni Don Juan ang pagsubok na pumili sa mga prinsesa.',
  ),
  Kabanata(
    number: 38,
    title: 'Ang Pagtakas sa Reyno Delos Cristales',
    description: 'Tumakas sina Don Juan at Maria Blanca mula sa kaharian.',
  ),
  Kabanata(
    number: 39,
    title: 'Ang Sumpaan',
    description: 'Nangako sina Don Juan at Maria Blanca na mananatiling tapat sa isa’t isa.',
  ),
  Kabanata(
    number: 40,
    title: 'Ang Paglimot sa Sumpaan',
    description: 'Nakalimot si Don Juan sa kaniyang pangako matapos siyang bumalik sa Berbanya.',
  ),
  Kabanata(
    number: 41,
    title: 'Ang Pagbawi kay Don Juan',
    description:
        'Sinikap ni Maria Blanca na mabawi at muling makasama si Don Juan.',
  ),
  Kabanata(
    number: 42,
    title: 'Ang Dula-Dulaan',
    description: 'Gumamit si Maria Blanca ng pagtatanghal upang ipaalala kay Don Juan ang nakaraan.',
  ),
  Kabanata(
    number: 43,
    title: 'Ang Pagpaparusa kay Don Juan',
    description:
        'Hinarap ni Don Juan ang bunga ng kaniyang paglimot at pagsuway.',
  ),
  Kabanata(
    number: 44,
    title: 'Ang Pagbabalik ng Alaala ni Don Juan',
    description: 'Naalala ni Don Juan ang kaniyang sumpaan at ang tunay niyang minamahal.',
  ),
  Kabanata(
    number: 45,
    title: 'Ang Masayang Yugto',
    description:
        'Naging matagumpay ang muling pagsasama at naghari ang kasiyahan.',
  ),
  Kabanata(
    number: 46,
    title: 'Ang Hari at Reyna ng Reyno Delos Cristales',
    description: 'Naging hari at reyna sina Don Juan at Maria Blanca sa kanilang kaharian.',
  ),
];

Kabanata? kabanataByNumber(int? number) {
  if (number == null || number < 1 || number > kabanataList.length) return null;
  return kabanataList[number - 1];
}
