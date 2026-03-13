import Foundation

enum PhosphorToSFSymbol {
    private static let mapping: [String: String] = [
        "fork-knife": "fork.knife",
        "car": "car",
        "car-simple": "car",
        "shopping-cart": "cart",
        "cart": "cart",
        "heart": "heart",
        "credit-card": "creditcard",
        "house": "house",
        "buildings": "building.2",
        "building": "building",
        "airplane": "airplane",
        "train": "tram",
        "bus": "bus",
        "taxi": "car.fill",
        "coffee": "cup.and.saucer",
        "wine": "wineglass",
        "beer-stein": "mug",
        "pizza": "fork.knife",
        "hamburger": "fork.knife",
        "bread": "fork.knife",
        "apple-logo": "apple.logo",
        "device-mobile": "iphone",
        "laptop": "laptopcomputer",
        "computer-tower": "desktopcomputer",
        "monitor": "display",
        "television": "tv",
        "headphones": "headphones",
        "speaker-high": "speaker.wave.3",
        "camera": "camera",
        "game-controller": "gamecontroller",
        "watch": "applewatch",
        "shirt": "tshirt",
        "pants": "person",
        "sneaker": "shoeprints.fill",
        "bag": "bag",
        "handbag": "bag",
        "suitcase": "suitcase",
        "baby": "figure.child",
        "stethoscope": "stethoscope",
        "pill": "pills",
        "first-aid": "cross.case",
        "hospital": "cross",
        "bandages": "bandage",
        "dumbbell": "dumbbell",
        "soccer-ball": "soccerball",
        "basketball": "basketball",
        "tennis-ball": "tennisball",
        "golf": "figure.golf",
        "swimming-pool": "figure.pool.swim",
        "bicycle": "bicycle",
        "tree": "tree",
        "flower": "camera.macro",
        "leaf": "leaf",
        "sun": "sun.max",
        "moon": "moon",
        "cloud": "cloud",
        "umbrella": "umbrella",
        "snowflake": "snowflake",
        "drop": "drop",
        "fire": "flame",
        "lightning": "bolt",
        "music-note": "music.note",
        "microphone": "mic",
        "film-slate": "film",
        "ticket": "ticket",
        "book": "book",
        "graduation-cap": "graduationcap",
        "backpack": "backpack",
        "pencil": "pencil",
        "palette": "paintpalette",
        "wrench": "wrench",
        "hammer": "hammer",
        "screwdriver": "screwdriver",
        "paint-roller": "roller",
        "broom": "broom",
        "scissors": "scissors",
        "gift": "gift",
        "party-popper": "party.popper",
        "balloon": "balloon",
        "confetti": "sparkles",
        "star": "star",
        "tag": "tag",
        "currency-dollar": "dollarsign",
        "currency-circle-dollar": "dollarsign.circle",
        "money": "banknote",
        "bank": "building.columns",
        "piggy-bank": "banknote",
        "chart-line-up": "chart.line.uptrend.xyaxis",
        "chart-bar": "chart.bar",
        "receipt": "receipt",
        "invoice": "doc.text",
        "gas-pump": "fuelpump",
        "charging-station": "bolt.car",
        "map-pin": "mappin",
        "map": "map",
        "globe": "globe",
        "phone": "phone",
        "envelope": "envelope",
        "chat": "bubble.left",
        "shield": "shield",
        "lock": "lock",
        "key": "key",
        "user": "person",
        "users": "person.2",
        "dog": "pawprint",
        "cat": "pawprint",
        "paw-print": "pawprint",
        "pharmacy": "cross.circle",
        "tooth": "mouth",
        "eye": "eye",
        "sparkle": "sparkle",
        "magic-wand": "wand.and.stars",

        // Geral
        "circle": "circle",
        "bookmark": "bookmark",
        "flag": "flag",
        "gear": "gear",
        "clock": "clock",
        "calendar": "calendar",
        "bell": "bell",

        // Alimentação & Bebidas
        "cookie": "birthday.cake",
        "cake": "birthday.cake",
        "bowl-food": "bowl.fill",
        "cooking-pot": "flame",
        "carrot": "leaf",
        "orange": "fork.knife",
        "champagne": "wineglass",
        "chef-hat": "fork.knife",

        // Transporte
        "motorcycle": "fuelpump",
        "boat": "sailboat",

        // Moradia
        "bed": "bed.double",
        "couch": "sofa",
        "lightbulb": "lightbulb",
        "paint-bucket": "paintbrush",
        "bathtub": "shower",
        "dresser": "cabinet",

        // Saúde & Fitness
        "heartbeat": "waveform.path.ecg",
        "bandaids": "bandage",
        "barbell": "dumbbell",
        "person-simple-run": "figure.run",
        "person-simple-swim": "figure.pool.swim",
        "person-simple-bike": "figure.outdoor.cycle",

        // Beleza & Cuidado Pessoal
        "hand-soap": "hands.sparkles",
        "hairdryer": "wind",

        // Lazer
        "music-notes": "music.note.list",
        "guitar": "guitars",

        // Educação
        "book-open": "book",
        "student": "graduationcap",
        "chalkboard-teacher": "person.chalkboard",

        // Trabalho
        "briefcase": "briefcase",
        "handshake": "hands.clap",
        "building-office": "building.2",
        "newspaper": "newspaper",

        // Finanças
        "wallet": "wallet.pass",
        "coins": "dollarsign.circle",
        "hand-coins": "hand.raised",

        // Compras & Moda
        "shopping-bag": "bag",
        "storefront": "storefront",
        "t-shirt": "tshirt",
        "dress": "tshirt",

        // Tecnologia
        "wifi-high": "wifi",

        // Viagem
        "compass": "compass.drawing",
        "tent": "tent",

        // Família
        "baby-carriage": "figure.child",

        // Pets & Natureza
        "fish": "fish"
    ]

    static func map(_ phosphorSymbol: String) -> String {
        let cleaned = phosphorSymbol.hasPrefix("phosphor:")
            ? String(phosphorSymbol.dropFirst("phosphor:".count))
            : phosphorSymbol
        return mapping[cleaned] ?? "tag"
    }
}
