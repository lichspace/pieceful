import Foundation

enum PuzzleCatalog {
    static let all: [PuzzleDefinition] =
        collection(.animals, [
            ("red-panda", "red_panda", "森林里的小熊猫"),
            ("owl-moon", "owl_moon", "月夜猫头鹰"),
            ("cat-window", "cat_window", "窗边的猫"),
            ("otter-river", "otter_river", "河湾水獭"),
            ("deer-stream", "deer_stream", "溪边小鹿"),
            ("penguin-ice", "penguin_ice", "冰原企鹅"),
            ("elephant-savanna", "elephant_savanna", "草原大象"),
            ("parrot-rainforest", "parrot_rainforest", "雨林鹦鹉"),
            ("rabbit-garden", "rabbit_garden", "花园白兔"),
            ("fox-autumn", "fox_autumn", "秋林小狐狸")
        ]) +
        collection(.architecture, [
            ("lighthouse", "lighthouse", "海边灯塔"),
            ("mountain-castle", "mountain_castle", "云山古堡"),
            ("desert-palace", "desert_palace", "沙漠宫殿"),
            ("floating-library", "floating_library", "云端图书馆"),
            ("forest-cabin", "forest_cabin", "林间木屋"),
            ("canal-houses", "canal_houses", "运河小镇"),
            ("garden-courtyard", "garden_courtyard", "竹影庭院"),
            ("snow-village", "snow_village", "雪落村庄"),
            ("rainy-street", "rainy_street", "雨后街角"),
            ("seaside-villa", "seaside_villa", "海岸白屋")
        ]) +
        collection(.vehicles, [
            ("blue-tram", "tram", "蓝色电车"),
            ("sailboat-harbor", "sailboat_harbor", "港湾帆船"),
            ("steam-train", "steam_train", "山谷蒸汽列车"),
            ("hot-air-balloons", "hot_air_balloons", "彩色热气球"),
            ("snow-express", "snow_express", "雪国列车"),
            ("moon-bicycle", "moon_bicycle", "月光飞艇"),
            ("retro-bicycle", "retro_bicycle", "花篮自行车"),
            ("city-bus", "city_bus", "城市巴士"),
            ("propeller-plane", "propeller_plane", "云间小飞机")
        ]) +
        collection(.nature, [
            ("spring-meadow", "meadow", "春日溪畔"),
            ("desert-oasis", "desert_oasis", "沙海绿洲"),
            ("bamboo-path", "bamboo_path", "竹林小径"),
            ("mushroom-forest", "mushroom_forest", "蘑菇秘境"),
            ("aurora-pines", "aurora_pines", "极光松林"),
            ("lavender-hills", "lavender_hills", "薰衣草山丘"),
            ("alpine-lake", "alpine_lake", "高山湖泊"),
            ("lotus-pond", "lotus_pond", "夏日荷塘"),
            ("canyon-river", "canyon_river", "峡谷长河"),
            ("autumn-waterfall", "autumn_waterfall", "秋日瀑布")
        ]) +
        collection(.space, [
            ("comet-valley", "comet_valley", "彗星山谷"),
            ("ringed-planet", "ringed_planet", "星环漫游"),
            ("galaxy-train", "galaxy_train", "银河列车"),
            ("astronaut-flowers", "astronaut_flowers", "宇航员的花园"),
            ("mars-rover", "mars_rover", "火星探险"),
            ("orbital-station", "orbital_station", "环轨空间站"),
            ("desert-rover", "desert_rover", "沙丘越野车"),
            ("moon-base", "moon_base", "月球基地"),
            ("saturn-observatory", "saturn_observatory", "星际观测台"),
            ("nebula-garden", "nebula_garden", "星云花园")
        ]) +
        collection(.mecha, [
            ("mecha-guardian", "mecha_guardian", "森林守护者"),
            ("mecha-star-patrol", "mecha_star_patrol", "星环巡逻队"),
            ("mecha-neon-vanguard", "mecha_neon_vanguard", "霓虹先锋队"),
            ("mecha-aurora-explorers", "mecha_aurora_explorers", "极光探索队"),
            ("mecha-desert-rescue", "mecha_desert_rescue", "沙海救援队"),
            ("mecha-deepblue-divers", "mecha_deepblue_divers", "深蓝潜航队")
        ]) +
        collection(.ocean, [
            ("coral-turtle", "coral_turtle", "珊瑚海龟")
        ])

    static func definitions(for category: PuzzleCategory) -> [PuzzleDefinition] {
        all.filter { $0.category == category }
    }

    private static func collection(
        _ category: PuzzleCategory,
        _ entries: [(id: String, imageName: String, title: String)]
    ) -> [PuzzleDefinition] {
        entries.map { entry in
            PuzzleDefinition(
                id: entry.id,
                category: category,
                imageName: entry.imageName,
                title: entry.title,
                aspectRatio: 4.0 / 3.0,
                availableDifficulties: Difficulty.allCases
            )
        }
    }
}
