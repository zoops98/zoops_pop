function phonicsUnit(name, focus, label, families, patterns, words, split) {
  const unit = { name, focus, label, families, patterns, words };
  if (split) unit.split = split;
  return unit;
}

var PHONICS_DATA = {
  "Section 1": {
    subtitle: "Short Vowels",
    accent: "#ff263d",
    soft: "#ffe8a6",
    units: [
      phonicsUnit("Short A", "a", "Short 'a' Sound", ["at", "an", "ap", "ag"], ["a"], ["cat","bat","hat","mat","rat","sat","can","man","fan","pan","bag","jam"]),
      phonicsUnit("Short E", "e", "Short 'e' Sound", ["ed", "eg", "en", "et"], ["e"], ["bed","red","fed","peg","leg","men","web","jet","wet","hen","pen","net"]),
      phonicsUnit("Short I", "i", "Short 'i' Sound", ["ig", "it", "in", "ip"], ["i"], ["big","dig","pig","sit","kid","pin","fin","lip","zip","win","lid","tip"]),
      phonicsUnit("Short O", "o", "Short 'o' Sound", ["og", "ot", "op", "ob"], ["o"], ["dog","log","fog","pot","mop","hot","cot","rod","job","hop","dot","top"]),
      phonicsUnit("Short U", "u", "Short 'u' Sound", ["ug", "un", "ut", "ub"], ["u"], ["bug","mug","hug","pup","nut","gum","tub","run","cup","sun","hut","rug"]),
      phonicsUnit("CVC Review", "a e i o u", "Mixed Short Vowels", ["CVC", "short vowels"], ["a","e","i","o","u"], ["map","bed","fin","log","sun","tap","hen","sit","fox","cup","jam","red"])
    ]
  },
  "Section 2": {
    subtitle: "CVC Endings",
    accent: "#f05a47",
    soft: "#ffe5dc",
    units: [
      phonicsUnit("Final CK", "ck", "Final /k/ Sound", ["ack", "eck", "ick", "ock", "uck"], ["ck"], ["back","neck","sick","rock","duck","pack","deck","pick","sock","luck","clock","truck"]),
      phonicsUnit("Double Finals", "ff ll ss zz", "FLOSS Rule", ["ff", "ll", "ss", "zz"], ["ff","ll","ss","zz"], ["off","puff","bell","hill","miss","dress","buzz","fizz","staff","shell","class","fuzz"]),
      phonicsUnit("Final NG", "ng", "Nasal Ending", ["ang", "ing", "ong", "ung"], ["ng"], ["bang","fang","ring","sing","king","song","long","wing","sang","hang","lung","sung"]),
      phonicsUnit("Final NK", "nk", "Nasal Blend", ["ank", "ink", "onk", "unk"], ["nk"], ["bank","tank","pink","sink","wink","honk","junk","bunk","drink","thank","blink","trunk"]),
      phonicsUnit("Final Blends", "nd nt mp st", "Two Final Consonants", ["nd", "nt", "mp", "st"], ["nd","nt","mp","st"], ["hand","sand","tent","mint","lamp","jump","nest","fast","bend","hunt","camp","rest"]),
      phonicsUnit("CVC Endings Review", "ck ff ll ss ng nk", "Ending Review", ["ck", "FLOSS", "ng", "nk"], ["ck","ff","ll","ss","zz","ng","nk"], ["black","stiff","spell","grass","buzz","thing","think","clock","fluff","shell","swing","drink"])
    ]
  },
  "Section 3": {
    subtitle: "Consonant Digraphs",
    accent: "#ff8d1b",
    soft: "#fff1d8",
    units: [
      phonicsUnit("SH", "sh", "Digraph /sh/", ["sh", "ash", "ish"], ["sh"], ["ship","shop","shut","shed","shin","shell","fish","dish","cash","rush","brush","flash"]),
      phonicsUnit("CH", "ch", "Digraph /ch/", ["ch", "atch", "inch"], ["ch","tch"], ["chat","chin","chop","much","rich","lunch","bench","chest","chick","catch","match","patch"]),
      phonicsUnit("TH", "th", "Voiced and Unvoiced TH", ["thin", "this", "bath"], ["th"], ["thin","thick","thank","thumb","bath","moth","this","that","them","then","with","father"]),
      phonicsUnit("WH", "wh", "Digraph /w/", ["wh", "whe", "whi"], ["wh"], ["when","whip","whiz","which","white","whale","wheel","wheat","where","while","whisk","whisper"]),
      phonicsUnit("PH", "ph", "Digraph /f/", ["ph", "graph"], ["ph"], ["phone","photo","graph","dolphin","elephant","alphabet","phrase","trophy","phantom","nephew","phonics","sphere"]),
      phonicsUnit("QU and Digraph Review", "qu", "Digraph Review", ["qu", "sh", "ch", "th", "wh"], ["qu","sh","ch","th","wh"], ["quit","quiz","quack","queen","quick","shell","chick","thumb","whale","squid","brush","lunch"])
    ]
  },
  "Section 4": {
    subtitle: "Consonant Blends",
    accent: "#e17b12",
    soft: "#ffedd8",
    units: [
      phonicsUnit("L Blends", "bl cl fl gl pl sl", "Initial L Blends", ["bl", "cl", "fl", "gl", "pl", "sl"], ["bl","cl","fl","gl","pl","sl"], ["black","clap","flag","glad","plan","slip","blue","clock","flat","glass","plug","sled"]),
      phonicsUnit("R Blends", "br cr dr fr gr pr tr", "Initial R Blends", ["br", "cr", "dr", "fr", "gr", "pr", "tr"], ["br","cr","dr","fr","gr","pr","tr"], ["brag","crab","drum","frog","grin","press","trip","brick","crop","drag","fresh","track"]),
      phonicsUnit("S Blends", "sc sk sl sm sn sp st sw", "Initial S Blends", ["sc", "sk", "sm", "sn", "sp", "st", "sw"], ["sc","sk","sm","sn","sp","st","sw"], ["scan","skip","smell","snack","spin","stop","swim","skin","smash","snap","spot","step"]),
      phonicsUnit("Final Blends", "ft ld lk lp lt", "Final Consonant Blends", ["ft", "ld", "lk", "lp", "lt"], ["ft","ld","lk","lp","lt"], ["gift","soft","cold","gold","milk","silk","help","yelp","belt","melt","left","child"]),
      phonicsUnit("Three-Letter Blends", "scr spl spr str", "Three Consonant Blends", ["scr", "spl", "spr", "str"], ["scr","spl","spr","str"], ["scrap","scrub","splash","split","spray","spring","strap","string","scratch","sprint","strong","street"]),
      phonicsUnit("Blend Review", "bl br st nd", "Mixed Blends", ["L blends", "R blends", "S blends", "final"], ["bl","cl","fl","br","cr","dr","fr","gr","tr","st","sp","nd"], ["plant","brush","stamp","crust","grand","flint","trust","blend","stand","print","blank","drift"])
    ]
  },
  "Section 5": {
    subtitle: "Silent E",
    accent: "#16a7ef",
    soft: "#dbf6ff",
    units: [
      phonicsUnit("Long A: a_e", "a_e", "Silent-e Long A", ["ake", "ame", "ate", "ave"], [], ["cake","lake","make","name","game","same","date","gate","cave","wave","brave","plate"], ["a","e"]),
      phonicsUnit("Long I: i_e", "i_e", "Silent-e Long I", ["ike", "ime", "ine", "ide"], [], ["bike","like","time","lime","fine","line","hide","ride","wide","smile","slide","shine"], ["i","e"]),
      phonicsUnit("Long O: o_e", "o_e", "Silent-e Long O", ["oke", "one", "ope", "ose"], [], ["home","hope","rope","nose","rose","stone","phone","joke","smoke","close","those","globe"], ["o","e"]),
      phonicsUnit("Long U: u_e", "u_e", "Silent-e Long U", ["ube", "ude", "ule", "ute"], [], ["cube","tube","cute","mule","rule","June","tune","flute","dune","huge","rude","use"], ["u","e"]),
      phonicsUnit("Silent E Contrast", "CVC CVCe", "Short and Long Vowels", ["cap/cape", "kit/kite"], ["a","i","o","u"], ["cap","cape","kit","kite","hop","hope","cub","cube","mad","made","rid","ride"]),
      phonicsUnit("Silent E Review", "a_e i_e o_e u_e", "Mixed Silent-e", ["a_e", "i_e", "o_e", "u_e"], [], ["snake","grape","white","prize","stone","spoke","flute","bride","plane","drive","chose","tune"], ["a","e"])
    ]
  },
  "Section 6": {
    subtitle: "Long Vowel Teams",
    accent: "#21a0d8",
    soft: "#dff7ff",
    units: [
      phonicsUnit("AI / AY", "ai ay", "Long A Teams", ["ai", "ay"], ["ai","ay"], ["rain","train","mail","paint","chain","brain","day","play","stay","gray","tray","spray"]),
      phonicsUnit("EE / EA", "ee ea", "Long E Teams", ["ee", "ea"], ["ee","ea"], ["bee","tree","feet","green","sheep","sleep","sea","beach","leaf","clean","dream","reach"]),
      phonicsUnit("OA / OW", "oa ow", "Long O Teams", ["oa", "ow"], ["oa","ow"], ["boat","coat","road","goat","soap","float","snow","grow","show","slow","window","yellow"]),
      phonicsUnit("UE / EW", "ue ew", "Long U Teams", ["ue", "ew"], ["ue","ew"], ["blue","clue","glue","true","due","rescue","new","few","chew","grew","stew","flew"]),
      phonicsUnit("IGH / IE / Y", "igh ie y", "Long I Teams", ["igh", "ie", "y"], ["igh","ie","y"], ["light","night","right","bright","pie","tie","cried","tried","fly","sky","cry","shy"]),
      phonicsUnit("Long Vowel Review", "ai ee oa ue igh", "Mixed Vowel Teams", ["long a", "long e", "long i", "long o", "long u"], ["ai","ay","ee","ea","oa","ow","ue","ew","igh","ie"], ["paint","play","sheep","dream","float","snow","clue","chew","bright","cried","train","beach"])
    ]
  },
  "Section 7": {
    subtitle: "R-Controlled Vowels",
    accent: "#72c827",
    soft: "#ecffd3",
    units: [
      phonicsUnit("AR", "ar", "R-Controlled /ar/", ["ar", "ark", "art"], ["ar"], ["car","far","jar","star","park","dark","shark","farm","cart","start","hard","march"]),
      phonicsUnit("OR", "or", "R-Controlled /or/", ["or", "ork", "orn"], ["or"], ["for","corn","horn","born","storm","fork","cork","horse","short","sport","north","porch"]),
      phonicsUnit("ER", "er", "R-Controlled /er/", ["er", "erm"], ["er"], ["her","term","fern","germ","stern","person","winter","sister","under","river","number","letter"]),
      phonicsUnit("IR", "ir", "R-Controlled /er/", ["ir", "ird", "irt"], ["ir"], ["bird","girl","shirt","skirt","dirt","first","third","stir","firm","birth","chirp","thirst"]),
      phonicsUnit("UR", "ur", "R-Controlled /er/", ["ur", "urn", "urt"], ["ur"], ["fur","turn","burn","hurt","surf","curl","burst","nurse","purse","church","purple","turtle"]),
      phonicsUnit("R-Controlled Review", "ar or er ir ur", "Bossy R Review", ["ar", "or", "er", "ir", "ur"], ["ar","or","er","ir","ur"], ["farm","storm","fern","bird","turn","market","corner","winter","circle","purple","garden","morning"])
    ]
  },
  "Section 8": {
    subtitle: "Diphthongs",
    accent: "#6cbf2a",
    soft: "#edffd8",
    units: [
      phonicsUnit("OI / OY", "oi oy", "Diphthong /oi/", ["oi", "oy"], ["oi","oy"], ["oil","coin","soil","boil","point","join","boy","toy","joy","enjoy","royal","oyster"]),
      phonicsUnit("OU / OW", "ou ow", "Diphthong /ou/", ["ou", "ow"], ["ou","ow"], ["out","cloud","round","sound","house","mouse","cow","how","now","town","brown","clown"]),
      phonicsUnit("OO as in Moon", "oo", "Long OO Sound", ["oo", "oon", "oom"], ["oo"], ["moon","food","room","soon","zoo","boot","root","spoon","school","tooth","smooth","broom"]),
      phonicsUnit("OO as in Book", "oo", "Short OO Sound", ["ook", "ood", "oot"], ["oo"], ["book","look","cook","hook","foot","good","wood","stood","wool","brook","shook","crook"]),
      phonicsUnit("AU / AW", "au aw", "Broad A Sound", ["au", "aw"], ["au","aw"], ["haul","Paul","fault","cause","pause","launch","saw","paw","draw","straw","lawn","crawl"]),
      phonicsUnit("Diphthong Review", "oi oy ou ow oo aw", "Mixed Diphthongs", ["oi", "oy", "ou", "ow", "oo", "aw"], ["oi","oy","ou","ow","oo","aw"], ["point","enjoy","cloud","brown","spoon","book","draw","fault","round","toy","school","crawl"])
    ]
  },
  "Section 9": {
    subtitle: "Advanced Vowel Teams",
    accent: "#3da65c",
    soft: "#e1f9e8",
    units: [
      phonicsUnit("EA Variations", "ea", "Long and Short EA", ["eat", "ead", "eak"], ["ea"], ["eat","meat","team","dream","head","bread","dead","ready","great","break","steak","heavy"]),
      phonicsUnit("OW Variations", "ow", "Long O and /ou/", ["snow", "cow"], ["ow"], ["snow","grow","show","yellow","window","cow","how","now","brown","clown","flower","shower"]),
      phonicsUnit("EIGH / EI / EY", "eigh ei ey", "Long A Alternatives", ["eigh", "ei", "ey"], ["eigh","ei","ey"], ["eight","weight","sleigh","freight","weigh","neighbor","vein","rein","they","prey","obey","survey"]),
      phonicsUnit("IE Variations", "ie", "Long I and Long E", ["pie", "chief"], ["ie"], ["pie","tie","lie","cried","tried","fries","chief","brief","field","piece","shield","thief"]),
      phonicsUnit("Y as a Vowel", "y", "Long I and Long E Y", ["fly", "baby"], ["y"], ["my","by","fly","cry","sky","shy","baby","happy","sunny","candy","family","puppy"]),
      phonicsUnit("Vowel Team Review", "ea ow eigh ie y", "Advanced Team Review", ["ea", "ow", "eigh", "ie", "y"], ["ea","ow","eigh","ei","ey","ie","y"], ["bread","steak","flower","window","eight","they","shield","cried","happy","sky","neighbor","ready"])
    ]
  },
  "Section 10": {
    subtitle: "Advanced Consonants",
    accent: "#b579d6",
    soft: "#f5e8ff",
    units: [
      phonicsUnit("Soft C", "c", "C Says /s/", ["ce", "ci", "cy"], ["c"], ["city","cent","cell","race","face","ice","cycle","fancy","pencil","place","space","dance"]),
      phonicsUnit("Soft G / DGE", "g dge", "Soft G Sound", ["ge", "gi", "dge"], ["g","dge"], ["gem","giant","giraffe","cage","page","huge","badge","edge","bridge","judge","fudge","fridge"]),
      phonicsUnit("KN / WR / GN", "kn wr gn", "Silent First Letters", ["kn", "wr", "gn"], ["kn","wr","gn"], ["knee","knit","knock","knife","know","write","wrap","wrist","wrong","gnat","gnaw","sign"]),
      phonicsUnit("MB / GH", "mb gh", "Silent Final Letters", ["mb", "gh"], ["mb","gh"], ["lamb","comb","climb","thumb","crumb","dumb","light","night","right","sigh","high","bright"]),
      phonicsUnit("C / K / CK", "c k ck", "Spelling the /k/ Sound", ["c", "k", "ck"], ["c","k","ck"], ["cat","cot","cup","kid","kit","kennel","back","neck","pick","rock","duck","clock"]),
      phonicsUnit("X / QU", "x qu", "Complex Consonant Sounds", ["x", "qu"], ["x","qu"], ["box","fox","six","wax","next","extra","quit","quick","queen","quiz","squid","square"])
    ]
  },
  "Section 11": {
    subtitle: "Word Endings",
    accent: "#d16b9c",
    soft: "#ffe5f2",
    units: [
      phonicsUnit("Plural S", "s", "Plural /s/ and /z/", ["-s"], ["s"], ["cats","hats","cups","books","dogs","pigs","beds","fans","kids","rugs","maps","hens"]),
      phonicsUnit("Plural ES", "es", "Plural /iz/", ["-es"], ["es"], ["boxes","foxes","dishes","wishes","buses","classes","watches","benches","buzzes","races","pages","roses"]),
      phonicsUnit("Past ED", "ed", "Past-Tense Endings", ["/t/", "/d/", "/id/"], ["ed"], ["jumped","looked","washed","played","rained","called","wanted","needed","painted","helped","filled","started"]),
      phonicsUnit("ING", "ing", "Present Participle", ["-ing"], ["ing"], ["jumping","running","sitting","playing","reading","looking","making","riding","swimming","helping","singing","painting"]),
      phonicsUnit("ER / EST", "er est", "Comparative Endings", ["-er", "-est"], ["er","est"], ["faster","fastest","smaller","smallest","taller","tallest","brighter","brightest","shorter","shortest","stronger","strongest"]),
      phonicsUnit("Ending Review", "s es ed ing er est", "Inflectional Endings", ["s", "es", "ed", "ing", "er", "est"], ["ed","ing","er","est"], ["dogs","boxes","jumped","playing","faster","smallest","wishes","needed","riding","brighter","cats","started"])
    ]
  },
  "Section 12": {
    subtitle: "Syllables & Mastery",
    accent: "#5367d8",
    soft: "#e8ebff",
    units: [
      phonicsUnit("Closed Syllables", "closed", "Closed Syllable", ["VC", "CVC"], ["a","e","i","o","u"], ["rabbit","basket","picnic","sunset","napkin","helmet","insect","problem","fantastic","magnet","pumpkin","kitten"]),
      phonicsUnit("Open Syllables", "open", "Open Syllable", ["CV"], ["a","e","i","o","u"], ["robot","tiger","music","paper","zero","pilot","baby","hotel","basic","unit","moment","frozen"]),
      phonicsUnit("Silent-e Syllables", "VCe", "Silent-e Syllable", ["VCe"], [], ["sunshine","inside","mistake","complete","invite","explode","cupcake","athlete","remote","reptile","homemade","lifetime"], ["a","e"]),
      phonicsUnit("Vowel-Team Syllables", "team", "Vowel-Team Syllable", ["ai", "ee", "oa", "oo"], ["ai","ay","ee","ea","oa","ow","oo"], ["raincoat","daydream","seashore","peanut","snowman","weekday","toothbrush","bedroom","sailboat","mailbox","playground","teacher"]),
      phonicsUnit("R-Controlled Syllables", "r", "R-Controlled Syllable", ["ar", "or", "er", "ir", "ur"], ["ar","or","er","ir","ur"], ["market","garden","morning","corner","winter","birthday","purple","turtle","farmer","stormy","thirteen","perfect"]),
      phonicsUnit("Consonant-le & Mastery", "le", "Final Stable Syllable", ["-ble", "-cle", "-dle", "-gle", "-ple", "-tle"], ["ble","cle","dle","gle","ple","tle"], ["table","candle","little","purple","bottle","jungle","apple","simple","circle","puzzle","bubble","turtle"])
    ]
  }
};

var SIGHT_WORD_POOLS = {
  "Section 1": [
    "a", "I", "am", "can", "and", "the", "it", "in", "is", "on", "up", "not",
    "my", "see", "we", "me", "he", "she", "yes", "no", "go", "so", "to", "do"
  ],
  "Section 2": [
    "all", "will", "tell", "off", "back", "look", "little", "thing", "think", "thank", "drink", "with",
    "this", "that", "then", "them", "when", "which", "much", "such", "went", "want", "best", "last"
  ],
  "Section 3": [
    "this", "that", "them", "then", "with", "when", "where", "which", "while", "why", "what", "who",
    "there", "they", "three", "phone", "photo", "school", "chair", "cheese", "ship", "shop", "thank", "think"
  ],
  "Section 4": [
    "blue", "black", "play", "please", "sleep", "small", "stop", "step", "still", "strong", "street", "friend",
    "from", "bring", "drink", "green", "brown", "every", "after", "under", "just", "must", "first", "last"
  ],
  "Section 5": [
    "make", "made", "came", "same", "take", "name", "like", "time", "home", "those", "use", "these",
    "have", "give", "live", "come", "some", "one", "done", "love", "move", "every", "there", "where"
  ],
  "Section 6": [
    "day", "say", "may", "way", "play", "they", "see", "green", "three", "read", "eat", "please",
    "boat", "show", "yellow", "new", "few", "blue", "right", "light", "night", "my", "by", "why"
  ],
  "Section 7": [
    "for", "or", "more", "before", "her", "first", "third", "turn", "our", "your", "their", "there",
    "under", "after", "over", "every", "mother", "father", "sister", "brother", "water", "work", "world", "learn"
  ],
  "Section 8": [
    "out", "about", "around", "down", "now", "how", "brown", "found", "good", "look", "book", "school",
    "soon", "too", "food", "boy", "toy", "joy", "saw", "draw", "because", "house", "sound", "round"
  ],
  "Section 9": [
    "they", "their", "eight", "weigh", "neighbor", "great", "break", "ready", "head", "bread", "read", "piece",
    "field", "chief", "baby", "happy", "family", "every", "very", "many", "only", "both", "again", "away"
  ],
  "Section 10": [
    "city", "place", "space", "ice", "face", "once", "give", "giant", "large", "page", "write", "know",
    "wrong", "sign", "high", "right", "light", "next", "six", "quick", "queen", "question", "because", "again"
  ],
  "Section 11": [
    "cats", "dogs", "books", "kids", "boxes", "wishes", "played", "looked", "wanted", "needed", "started", "called",
    "reading", "playing", "going", "doing", "helping", "faster", "fastest", "smaller", "every", "always", "today", "tomorrow"
  ],
  "Section 12": [
    "little", "people", "because", "about", "before", "after", "again", "around", "together", "family", "favorite", "different",
    "important", "beautiful", "number", "another", "mother", "father", "teacher", "friend", "school", "student", "complete", "perfect"
  ]
};

var SIGHT_WORDS_PER_UNIT = 9;

function assignSightWords() {
  Object.entries(PHONICS_DATA).forEach(([sectionKey, section]) => {
    const pool = [];
    (SIGHT_WORD_POOLS[sectionKey] || []).forEach(word => {
      if (word && !pool.includes(word)) pool.push(word);
    });
    section.units.forEach((unit, index) => {
      const start = (index * SIGHT_WORDS_PER_UNIT) % pool.length;
      const words = [];
      for (
        let offset = 0;
        words.length < Math.min(SIGHT_WORDS_PER_UNIT, pool.length) && offset < pool.length;
        offset += 1
      ) {
        const word = pool[(start + offset) % pool.length];
        if (word && !words.includes(word)) words.push(word);
      }
      unit.sightWords = words;
    });
  });
}

assignSightWords();
