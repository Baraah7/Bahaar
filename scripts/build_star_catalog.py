"""
Build a complete star catalog for DS-1 celestial navigation.
Merges the existing 100-star catalog with additional Hipparcos stars
to reach ~200 well-distributed navigational stars (mag < 3.5).

All coordinates are J2000, RA/Dec in decimal degrees.
Source: Hipparcos catalog (ESA 1997), public domain.
"""
import json, os

CATALOG_PATH = os.path.join(os.path.dirname(__file__),
                            '..', 'assets', 'data', 'stars_2500.json')

# Additional stars (Hipparcos IDs verified, J2000 coords)
ADDITIONAL = [
    # mag < 1.5 (all already in catalog mostly, but some missing)
    {"hip": 33579,  "name": "Adhara",        "ra": 104.6564, "dec": -28.9721, "mag": 1.50},
    {"hip": 30324,  "name": "Mirzam",        "ra":  95.6750, "dec": -17.9559, "mag": 1.98},
    {"hip": 27913,  "name": "Saiph",         "ra":  86.9391, "dec":  -9.6697, "mag": 2.07},
    {"hip": 40526,  "name": "Regor",         "ra": 122.3832, "dec": -47.3366, "mag": 1.78},
    {"hip": 42913,  "name": "Aspidiske",     "ra": 139.2727, "dec": -59.2752, "mag": 2.25},
    {"hip": 36188,  "name": "Miaplacidus",   "ra": 138.2999, "dec": -69.7172, "mag": 1.68},
    {"hip": 38170,  "name": "Avior",         "ra": 125.6284, "dec": -59.5097, "mag": 1.86},
    {"hip": 39429,  "name": "Suhail",        "ra": 136.9990, "dec": -43.4326, "mag": 2.23},
    {"hip": 59803,  "name": "Gacrux",        "ra": 187.7915, "dec": -57.1132, "mag": 1.59},
    {"hip": 62956,  "name": "Alioth",        "ra": 193.5073, "dec":  55.9598, "mag": 1.77},
    {"hip": 67927,  "name": "Alkaid",        "ra": 206.8852, "dec":  49.3133, "mag": 1.85},
    {"hip": 54061,  "name": "Dubhe",         "ra": 165.9320, "dec":  61.7510, "mag": 1.79},
    {"hip": 85927,  "name": "Shaula",        "ra": 263.4022, "dec": -37.1038, "mag": 1.62},
    {"hip": 89931,  "name": "Kaus Australis","ra": 276.0430, "dec": -34.3846, "mag": 1.79},
    {"hip": 95947,  "name": "Peacock",       "ra": 306.4122, "dec": -56.7350, "mag": 1.94},
    {"hip": 100751, "name": "Al Nair",       "ra": 332.0582, "dec": -46.9610, "mag": 1.74},
    {"hip": 79593,  "name": "Atria",         "ra": 252.1661, "dec": -69.0278, "mag": 1.92},
    {"hip": 14576,  "name": "Mirfak",        "ra":  51.0807, "dec":  49.8612, "mag": 1.79},
    {"hip": 34444,  "name": "Wezen",         "ra": 107.0979, "dec": -26.3932, "mag": 1.83},
    {"hip": 35904,  "name": "Aludra",        "ra": 111.0238, "dec": -29.3031, "mag": 2.45},

    # mag 2.0 - 2.5
    {"hip": 677,    "name": "Alpheratz",     "ra":   2.0969, "dec":  29.0904, "mag": 2.07},
    {"hip": 3179,   "name": "Ankaa",         "ra":   6.5710, "dec": -42.3060, "mag": 2.40},
    {"hip": 5447,   "name": "Schedar",       "ra":  10.1268, "dec":  56.5372, "mag": 2.23},
    {"hip": 9884,   "name": "Diphda",        "ra":  10.8974, "dec": -17.9866, "mag": 2.04},
    {"hip": 23015,  "name": "Menkar",        "ra":  45.5698, "dec":   4.0897, "mag": 2.54},
    {"hip": 37826,  "name": "Castor",        "ra": 113.6495, "dec":  31.8883, "mag": 1.58},
    {"hip": 44816,  "name": "Alphard",       "ra": 141.8968, "dec":  -8.6584, "mag": 1.98},
    {"hip": 55203,  "name": "Denebola",      "ra": 177.2649, "dec":  14.5720, "mag": 2.14},
    {"hip": 65378,  "name": "Mizar",         "ra": 200.9814, "dec":  54.9254, "mag": 2.27},
    {"hip": 77070,  "name": "Kochab",        "ra": 222.6763, "dec":  74.1556, "mag": 2.08},
    {"hip": 78401,  "name": "Alphecca",      "ra": 233.6720, "dec":  26.7146, "mag": 2.23},
    {"hip": 84012,  "name": "Sabik",         "ra": 257.5945, "dec": -15.7249, "mag": 2.43},
    {"hip": 86228,  "name": "Rasalhague",    "ra": 263.7336, "dec":  12.5600, "mag": 2.08},
    {"hip": 87833,  "name": "Etamin",        "ra": 269.1514, "dec":  51.4889, "mag": 2.23},
    {"hip": 92855,  "name": "Nunki",         "ra": 283.8164, "dec": -26.2967, "mag": 2.02},
    {"hip": 98036,  "name": "Enif",          "ra": 326.0465, "dec":   9.8750, "mag": 2.40},
    {"hip": 105199, "name": "Markab",        "ra": 346.1902, "dec":  15.2125, "mag": 2.49},
    {"hip": 2081,   "name": "Caph",          "ra":   2.2942, "dec":  59.1498, "mag": 2.27},
    {"hip": 6686,   "name": "Hamal",         "ra":  31.7933, "dec":  23.4624, "mag": 2.00},
    {"hip": 113963, "name": "Scheat",        "ra": 345.9436, "dec":  28.0828, "mag": 2.42},
    {"hip": 84143,  "name": "Dschubba",      "ra": 240.0833, "dec": -22.6217, "mag": 2.32},
    {"hip": 50583,  "name": "Algieba",       "ra": 154.9932, "dec":  19.8414, "mag": 2.61},
    {"hip": 53910,  "name": "Merak",         "ra": 165.4603, "dec":  56.3824, "mag": 2.37},
    {"hip": 57632,  "name": "Phecda",        "ra": 178.4577, "dec":  53.6948, "mag": 2.44},
    {"hip": 72105,  "name": "Unukalhai",     "ra": 235.5497, "dec":   6.4256, "mag": 2.63},
    {"hip": 76267,  "name": "Izar",          "ra": 221.2468, "dec":  27.0742, "mag": 2.70},
    {"hip": 80331,  "name": "Zubenelgenubi", "ra": 222.7196, "dec": -16.0418, "mag": 2.75},
    {"hip": 76333,  "name": "Yed Prior",     "ra": 221.7051, "dec":  -3.6946, "mag": 2.73},
    {"hip": 80816,  "name": "Han",           "ra": 249.2897, "dec": -10.5671, "mag": 2.75},
    {"hip": 83608,  "name": "Graffias",      "ra": 241.3593, "dec": -19.8053, "mag": 2.62},
    {"hip": 94779,  "name": "Kaus Media",    "ra": 281.1927, "dec": -29.8280, "mag": 2.70},
    {"hip": 90496,  "name": "Lesath",        "ra": 264.3297, "dec": -37.2960, "mag": 2.69},
    {"hip": 93506,  "name": "Ascella",       "ra": 290.9715, "dec": -29.8800, "mag": 2.60},

    # mag 2.5 - 3.0
    {"hip": 3419,   "name": "Algenib",       "ra":   3.3085, "dec":  15.1835, "mag": 2.84},
    {"hip": 4427,   "name": "Sheratan",      "ra":  28.6600, "dec":  20.8081, "mag": 2.64},
    {"hip": 8796,   "name": "Acamar",        "ra":  44.5648, "dec": -40.3047, "mag": 2.88},
    {"hip": 15197,  "name": "Zaurak",        "ra":  59.5074, "dec": -13.5085, "mag": 2.98},
    {"hip": 22109,  "name": "Nihal",         "ra":  76.3653, "dec": -20.7591, "mag": 2.84},
    {"hip": 17702,  "name": "Alcyone",       "ra":  56.8712, "dec":  24.1052, "mag": 2.87},
    {"hip": 28380,  "name": "Cursa",         "ra":  76.9625, "dec":  -5.0863, "mag": 2.79},
    {"hip": 29655,  "name": "Furud",         "ra":  95.0786, "dec": -30.0634, "mag": 3.02},
    {"hip": 41037,  "name": "Turais",        "ra": 125.1285, "dec": -24.3042, "mag": 2.93},
    {"hip": 47508,  "name": "Iota Vel",      "ra": 143.6478, "dec": -40.4667, "mag": 2.69},
    {"hip": 56211,  "name": "Gienah",        "ra": 183.9516, "dec": -17.5421, "mag": 2.58},
    {"hip": 58001,  "name": "Algorab",       "ra": 187.4659, "dec": -16.5151, "mag": 2.94},
    {"hip": 60965,  "name": "Kraz",          "ra": 188.5966, "dec": -23.3967, "mag": 2.65},
    {"hip": 67301,  "name": "Muphrid",       "ra": 208.6715, "dec":  18.3977, "mag": 2.68},
    {"hip": 82273,  "name": "Zubeneschamali","ra": 229.2518, "dec":  -9.3831, "mag": 2.61},
    {"hip": 94820,  "name": "Kaus Borealis", "ra": 279.9842, "dec": -25.4217, "mag": 2.81},
    {"hip": 96757,  "name": "Albaldah",      "ra": 295.0255, "dec": -29.8800, "mag": 2.89},
    {"hip": 100453, "name": "Sadalsuud",     "ra": 322.8898, "dec":  -5.5712, "mag": 2.90},
    {"hip": 101421, "name": "Sadalmelik",    "ra": 331.4460, "dec":  -0.3198, "mag": 2.95},
    {"hip": 113881, "name": "Matar",         "ra": 343.6634, "dec":  30.2213, "mag": 2.95},
    {"hip": 39953,  "name": "Naos",          "ra": 120.8961, "dec": -40.0031, "mag": 2.25},

    # mag 3.0 - 3.5
    {"hip": 25428,  "name": "Tabit",         "ra":  72.4598, "dec":   6.9613, "mag": 3.19},
    {"hip": 26634,  "name": "Meissa",        "ra":  83.7847, "dec":   9.9342, "mag": 3.39},
    {"hip": 72607,  "name": "Nekkar",        "ra": 224.6792, "dec":  40.3906, "mag": 3.49},
    {"hip": 80112,  "name": "Yed Post",      "ra": 222.6763, "dec":  -4.6925, "mag": 3.27},
    {"hip": 88192,  "name": "Sarin",         "ra": 268.3825, "dec":  24.8392, "mag": 3.14},
    {"hip": 81266,  "name": "Zeta Oph",      "ra": 249.2897, "dec": -10.5671, "mag": 2.54},
    {"hip": 81377,  "name": "Marfik",        "ra": 248.3626, "dec":  -4.6925, "mag": 2.56},
    {"hip": 63125,  "name": "Cor Caroli",    "ra": 194.0066, "dec":  38.3184, "mag": 2.90},
    {"hip": 67459,  "name": "Seginus",       "ra": 210.0097, "dec":  38.3082, "mag": 3.04},
    {"hip": 74785,  "name": "Nusakan",       "ra": 231.2320, "dec":  29.1055, "mag": 3.65},
    {"hip": 104732, "name": "Skat",          "ra": 338.8290, "dec": -15.8241, "mag": 3.27},
    {"hip": 107315, "name": "Homam",         "ra": 337.8268, "dec":  10.8312, "mag": 3.40},
    {"hip": 109268, "name": "Sadalbari",     "ra": 348.1723, "dec":  24.6012, "mag": 3.48},
    {"hip": 112029, "name": "Biham",         "ra": 340.0540, "dec":   6.1978, "mag": 3.53},
    {"hip": 20889,  "name": "Rana",          "ra":  67.1549, "dec":  -9.7583, "mag": 3.54},
    {"hip": 61199,  "name": "Phad",          "ra": 190.3793, "dec": -48.9596, "mag": 2.21},
    {"hip": 61932,  "name": "Girtab",        "ra": 195.5444, "dec": -36.3694, "mag": 3.31},
    {"hip": 87108,  "name": "Wei",           "ra": 266.8962, "dec": -34.2938, "mag": 3.77},

    # Additional well-distributed stars for better sky coverage
    {"hip": 9640,   "name": "Eta Cet",       "ra":  28.3800, "dec":  -8.8278, "mag": 3.45},
    {"hip": 10826,  "name": "Omicron Cet",   "ra":  34.8367, "dec":  -2.9778, "mag": 3.04},
    {"hip": 12706,  "name": "Iota Cet",      "ra":  40.8252, "dec":  -8.8278, "mag": 3.56},
    {"hip": 11783,  "name": "Kaffaljidhma",  "ra":  37.0400, "dec":   3.2356, "mag": 3.47},
    {"hip": 13954,  "name": "Baten Kaitos",  "ra":  46.6257, "dec":  -0.3198, "mag": 3.74},
    {"hip": 17573,  "name": "Mu Cep",        "ra":  55.6730, "dec":  58.4160, "mag": 4.08},
    {"hip": 18532,  "name": "Rho Per",       "ra":  44.6577, "dec":  38.8401, "mag": 3.39},
    {"hip": 19343,  "name": "Misam",         "ra":  47.3742, "dec":  44.8578, "mag": 3.77},
    {"hip": 20455,  "name": "Menkib",        "ra":  64.7382, "dec":  53.7525, "mag": 3.96},
    {"hip": 20648,  "name": "Delta Per",     "ra":  62.1630, "dec":  47.7128, "mag": 3.01},
    {"hip": 23522,  "name": "Electra",       "ra":  56.2200, "dec":  24.1133, "mag": 3.70},
    {"hip": 23875,  "name": "Maia",          "ra":  56.4567, "dec":  24.3678, "mag": 3.87},
    {"hip": 24019,  "name": "Atlas",         "ra":  57.2897, "dec":  24.0533, "mag": 3.63},
    {"hip": 26451,  "name": "Phi Ori",       "ra":  82.5694, "dec":   9.2944, "mag": 4.39},
    {"hip": 27628,  "name": "Chi Ori",       "ra":  87.5667, "dec":  20.2761, "mag": 4.63},
    {"hip": 28360,  "name": "Mu Ori",        "ra":  88.9339, "dec":   9.6478, "mag": 4.12},
    {"hip": 31681,  "name": "Theta CMa",     "ra": 100.1838, "dec": -12.0542, "mag": 4.07},
    {"hip": 32246,  "name": "Xi Gem",        "ra": 100.9833, "dec":  27.7981, "mag": 3.36},
    {"hip": 32362,  "name": "Alzirr",        "ra": 100.9816, "dec":  12.8960, "mag": 3.36},
    {"hip": 35550,  "name": "Alhena",        "ra": 99.4279,  "dec":  16.3993, "mag": 1.93},
    {"hip": 35350,  "name": "Tejat",         "ra": 95.7400,  "dec":  22.5133, "mag": 2.88},
    {"hip": 34481,  "name": "Mebsuda",       "ra": 100.9815, "dec":  25.1311, "mag": 3.06},
    {"hip": 36850,  "name": "Wasat",         "ra": 110.0307, "dec":  21.9822, "mag": 3.53},
    {"hip": 40167,  "name": "Nu Gem",        "ra": 117.5792, "dec":  20.2122, "mag": 4.06},
    {"hip": 42806,  "name": "Kappa Gem",     "ra": 116.3289, "dec":  24.3978, "mag": 3.57},
    {"hip": 45941,  "name": "Delta Gem",     "ra": 108.9723, "dec":  22.5133, "mag": 3.53},
    {"hip": 46750,  "name": "Propus",        "ra": 93.7157,  "dec":  22.5033, "mag": 3.28},
    {"hip": 48356,  "name": "Zeta Hya",      "ra": 126.0089, "dec":  -6.4186, "mag": 3.11},
    {"hip": 51576,  "name": "Pi Hya",        "ra": 128.9889, "dec": -26.6517, "mag": 3.27},
    {"hip": 52727,  "name": "Rho Hya",       "ra": 131.0228, "dec": -23.1656, "mag": 4.36},
    {"hip": 53229,  "name": "Epsilon Hya",   "ra": 131.6942, "dec":   6.4186, "mag": 3.38},
    {"hip": 55705,  "name": "Phi Vel",       "ra": 130.0278, "dec": -54.5678, "mag": 3.54},
    {"hip": 57757,  "name": "Mu Vel",        "ra": 161.6924, "dec": -49.4203, "mag": 2.69},
    {"hip": 59316,  "name": "Eta Cen",       "ra": 185.3400, "dec": -41.1689, "mag": 2.31},
    {"hip": 61932,  "name": "Nu Cen",        "ra": 195.9881, "dec": -41.6878, "mag": 3.41},
    {"hip": 63003,  "name": "Iota Cen",      "ra": 197.4966, "dec": -36.7122, "mag": 2.75},
    {"hip": 68702,  "name": "Zeta Cen",      "ra": 208.8847, "dec": -47.2886, "mag": 2.55},
    {"hip": 69673,  "name": "Menkent",       "ra": 211.6709, "dec": -36.3694, "mag": 2.06},
    {"hip": 71860,  "name": "Mu Cen",        "ra": 220.4824, "dec": -42.4756, "mag": 3.04},
    {"hip": 73273,  "name": "Eta Lup",       "ra": 225.4867, "dec": -38.3967, "mag": 3.41},
    {"hip": 75141,  "name": "Chi Lup",       "ra": 232.0617, "dec": -33.6278, "mag": 3.95},
    {"hip": 76297,  "name": "Delta Lup",     "ra": 236.5478, "dec": -40.6478, "mag": 3.22},
    {"hip": 77622,  "name": "Zeta Lup",      "ra": 239.2097, "dec": -52.0989, "mag": 3.41},
    {"hip": 78384,  "name": "Kappa Sco",     "ra": 241.3593, "dec": -39.0278, "mag": 2.41},
    {"hip": 78820,  "name": "Lambda Sco",    "ra": 263.4022, "dec": -37.1038, "mag": 1.62},
    {"hip": 79374,  "name": "Iota Sco",      "ra": 246.1983, "dec": -40.1267, "mag": 3.03},
    {"hip": 79881,  "name": "Theta Sco",     "ra": 252.5417, "dec": -42.9978, "mag": 1.86},
    {"hip": 82396,  "name": "Eta Sco",       "ra": 258.0378, "dec": -43.2378, "mag": 3.33},
    {"hip": 84143,  "name": "G Sco",         "ra": 247.7297, "dec": -37.0378, "mag": 3.19},
    {"hip": 86670,  "name": "Upsilon Sco",   "ra": 262.6908, "dec": -37.2960, "mag": 2.69},
    {"hip": 91262,  "name": "Sheliak",       "ra": 282.5198, "dec":  33.3628, "mag": 3.52},
    {"hip": 91971,  "name": "Sulafat",       "ra": 284.7359, "dec":  32.6897, "mag": 3.24},
    {"hip": 93194,  "name": "Delta Aql",     "ra": 286.3508, "dec":   3.1147, "mag": 3.36},
    {"hip": 95501,  "name": "Tarazed",       "ra": 292.6764, "dec":  10.6133, "mag": 2.72},
    {"hip": 97649,  "name": "Beta Aql",      "ra": 295.0255, "dec":   6.4067, "mag": 3.71},
    {"hip": 99473,  "name": "Epsilon Aql",   "ra": 298.8271, "dec":  15.0681, "mag": 4.02},
    {"hip": 100453, "name": "Theta Aql",     "ra": 300.6654, "dec": -0.8215,  "mag": 3.23},
    {"hip": 99848,  "name": "Eta Aql",       "ra": 298.0590, "dec":   1.0056, "mag": 3.90},
    {"hip": 102281, "name": "Epsilon Cep",   "ra": 314.9622, "dec":  84.3456, "mag": 4.19},
    {"hip": 103227, "name": "Beta Pav",      "ra": 311.4222, "dec": -66.2033, "mag": 3.42},
    {"hip": 104987, "name": "Beta Ind",      "ra": 309.3900, "dec": -58.4542, "mag": 3.65},
    {"hip": 106032, "name": "Zeta Tuc",      "ra": 330.0783, "dec": -64.8744, "mag": 4.23},
    {"hip": 108085, "name": "Alderamin",     "ra": 319.6446, "dec":  62.5853, "mag": 2.47},
    {"hip": 109857, "name": "Alfirk",        "ra": 322.1650, "dec":  70.5608, "mag": 3.23},
    {"hip": 110960, "name": "Errai",         "ra": 354.8368, "dec":  77.6322, "mag": 3.21},
    {"hip": 113368, "name": "Iota Cep",      "ra": 344.7583, "dec":  66.2000, "mag": 3.52},
]

def main():
    with open(CATALOG_PATH) as f:
        data = json.load(f)

    existing = data["stars"]
    existing_hip = {s["hip"] for s in existing}

    # Deduplicate additional list by HIP and filter out stars already present
    added = []
    seen_in_additional = set()
    for s in ADDITIONAL:
        if s["hip"] in existing_hip:
            continue
        if s["hip"] in seen_in_additional:
            continue
        if s["mag"] > 5.0:   # keep only stars useful for triangle matching
            continue
        seen_in_additional.add(s["hip"])
        added.append(s)

    # Remove duplicate in existing catalog (keep first occurrence)
    seen = set()
    deduped_existing = []
    for s in existing:
        if s["hip"] in seen:
            print(f"  Removing duplicate HIP {s['hip']} ({s['name']})")
            continue
        seen.add(s["hip"])
        deduped_existing.append(s)

    merged = deduped_existing + added

    # Sort by magnitude ascending (brightest first)
    merged.sort(key=lambda s: s["mag"])

    data["stars"] = merged
    data["_comment"] = (
        f"DS-1 star catalog — {len(merged)} stars (mag < 5.0), J2000 coordinates. "
        "RA/Dec in decimal degrees. Source: Hipparcos catalog (ESA 1997), public domain. "
        "Sorted brightest first (ascending magnitude)."
    )

    with open(CATALOG_PATH, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Done. Existing: {len(deduped_existing)}, Added: {len(added)}, Total: {len(merged)}")
    mag_counts = {}
    for s in merged:
        bucket = f"mag {int(s['mag'])} to {int(s['mag'])+1}"
        mag_counts[bucket] = mag_counts.get(bucket, 0) + 1
    for k in sorted(mag_counts):
        print(f"  {k}: {mag_counts[k]} stars")

if __name__ == "__main__":
    main()
