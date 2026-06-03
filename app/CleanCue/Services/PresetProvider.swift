import Foundation

nonisolated struct PresetProvider {
    static let defaultProvider = PresetProvider()

    let places: [PresetPlace]
    let homeMaintenancePlace: PresetPlace
    let tasks: [PresetTask]

    init() {
        self.places = [
            PresetPlace(id: "kitchen", displayName: "キッチン", localizedNameKey: "preset.place.kitchen", iconName: "fork.knife", colorHex: "#3A7CA5"),
            PresetPlace(id: "bathroom", displayName: "浴室", localizedNameKey: "preset.place.bathroom", iconName: "shower", colorHex: "#4F8F7B"),
            PresetPlace(id: "toilet", displayName: "トイレ", localizedNameKey: "preset.place.toilet", iconName: "toilet", colorHex: "#6A7FDB"),
            PresetPlace(id: "living_room", displayName: "リビング", localizedNameKey: "preset.place.livingRoom", iconName: "sofa", colorHex: "#B87942"),
            PresetPlace(id: "bedroom", displayName: "寝室", localizedNameKey: "preset.place.bedroom", iconName: "bed.double", colorHex: "#8B6BB1"),
            PresetPlace(id: "entryway", displayName: "玄関", localizedNameKey: "preset.place.entryway", iconName: "door.left.hand.open", colorHex: "#5C8790"),
            PresetPlace(id: "washroom", displayName: "洗面所", localizedNameKey: "preset.place.washroom", iconName: "sink", colorHex: "#4A8C9F"),
            PresetPlace(id: "laundry", displayName: "洗濯まわり", localizedNameKey: "preset.place.laundry", iconName: "washer", colorHex: "#5B8FB9"),
            PresetPlace(id: "balcony", displayName: "ベランダ", localizedNameKey: "preset.place.balcony", iconName: "sun.max", colorHex: "#C28D3E"),
            PresetPlace(id: "office", displayName: "オフィス", localizedNameKey: "preset.place.office", iconName: "desktopcomputer", colorHex: "#586F7C"),
            PresetPlace(id: "hallway_stairs", displayName: "廊下・階段", localizedNameKey: "preset.place.hallwayStairs", iconName: "stairs", colorHex: "#7C8B64"),
            PresetPlace(id: "closet_storage", displayName: "収納", localizedNameKey: "preset.place.closetStorage", iconName: "archivebox", colorHex: "#94735A"),
            PresetPlace(id: "other", displayName: "その他", localizedNameKey: "preset.place.other", iconName: "square.grid.2x2", colorHex: "#6B7280")
        ]

        self.homeMaintenancePlace = PresetPlace(
            id: "home_maintenance",
            displayName: "家メンテ",
            localizedNameKey: "preset.place.homeMaintenance",
            iconName: "wrench.and.screwdriver",
            colorHex: "#7A6C5D"
        )

        self.tasks = [
            PresetTask(id: "kitchen_sink_clean", placeID: "kitchen", displayName: "シンク掃除", localizedNameKey: "preset.task.kitchen.sinkClean", note: "水あかと排水まわりを軽く整える", tools: "スポンジ、台所用洗剤", estimatedMinutes: 5, intervalRule: IntervalRule(value: 3, unit: .day)),
            PresetTask(id: "kitchen_stove_wipe", placeID: "kitchen", displayName: "コンロ拭き", localizedNameKey: "preset.task.kitchen.stoveWipe", note: "油はねをためずに拭く", tools: "ふきん、油汚れ用スプレー", estimatedMinutes: 7, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "kitchen_drain_clean", placeID: "kitchen", displayName: "排水口掃除", localizedNameKey: "preset.task.kitchen.drainClean", note: "ぬめりを軽く落とす", tools: "手袋、ブラシ", estimatedMinutes: 8, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "kitchen_counter_wipe", placeID: "kitchen", displayName: "調理台拭き", localizedNameKey: "preset.task.kitchen.counterWipe", note: "食べこぼしと水滴を拭く", tools: "ふきん、台所用洗剤", estimatedMinutes: 5, intervalRule: IntervalRule(value: 3, unit: .day)),
            PresetTask(id: "kitchen_microwave_wipe", placeID: "kitchen", displayName: "電子レンジ拭き", localizedNameKey: "preset.task.kitchen.microwaveWipe", note: "食べ物の飛び散りを拭く", tools: "クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "kitchen_fridge_reset", placeID: "kitchen", displayName: "冷蔵庫整理", localizedNameKey: "preset.task.kitchen.fridgeReset", note: "期限切れと奥の食品を確認する", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "kitchen_trash_bin_wipe", placeID: "kitchen", displayName: "ゴミ箱拭き", localizedNameKey: "preset.task.kitchen.trashBinWipe", note: "ふたや内側の汚れを拭く", tools: "掃除シート、洗剤", estimatedMinutes: 8, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "kitchen_cabinet_handle_wipe", placeID: "kitchen", displayName: "取っ手拭き", localizedNameKey: "preset.task.kitchen.cabinetHandleWipe", note: "よく触る取っ手の手あかを拭く", tools: "クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "kitchen_fridge_shelf_wipe", placeID: "kitchen", displayName: "冷蔵庫内拭き", localizedNameKey: "preset.task.kitchen.fridgeShelfWipe", note: "棚を外せる範囲で拭く", tools: "クロス、台所用洗剤", estimatedMinutes: 20, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),
            PresetTask(id: "kitchen_vent_filter", placeID: "kitchen", displayName: "換気扇フィルター", localizedNameKey: "preset.task.kitchen.ventFilter", note: "汚れ具合を見て洗うか交換する", estimatedMinutes: 15, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),

            PresetTask(id: "bathroom_drain_clean", placeID: "bathroom", displayName: "排水口掃除", localizedNameKey: "preset.task.bathroom.drainClean", note: "髪の毛とぬめりを取る", tools: "手袋、ブラシ", estimatedMinutes: 8, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "bathroom_floor_clean", placeID: "bathroom", displayName: "床掃除", localizedNameKey: "preset.task.bathroom.floorClean", note: "床のぬめりを洗い流す", estimatedMinutes: 10, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "bathroom_tub_clean", placeID: "bathroom", displayName: "浴槽掃除", localizedNameKey: "preset.task.bathroom.tubClean", note: "入る範囲だけ軽く洗う", tools: "スポンジ、浴室用洗剤", estimatedMinutes: 8, intervalRule: IntervalRule(value: 3, unit: .day)),
            PresetTask(id: "bathroom_mirror_wipe", placeID: "bathroom", displayName: "鏡拭き", localizedNameKey: "preset.task.bathroom.mirrorWipe", note: "水滴あとを軽く拭く", tools: "クロス", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "bathroom_wall_door_rinse", placeID: "bathroom", displayName: "壁・ドアまわり洗い", localizedNameKey: "preset.task.bathroom.wallDoorRinse", note: "石けんカスをためない", tools: "スポンジ", estimatedMinutes: 7, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "bathroom_bottle_tray_wash", placeID: "bathroom", displayName: "ボトル置き場洗い", localizedNameKey: "preset.task.bathroom.bottleTrayWash", note: "ぬめりや水あかを落とす", tools: "スポンジ", estimatedMinutes: 8, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "bathroom_mold_care", placeID: "bathroom", displayName: "カビ取り", localizedNameKey: "preset.task.bathroom.moldCare", note: "気になる場所だけ短くケアする", estimatedMinutes: 15, priority: .high, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "bathroom_chair_bowl_clean", placeID: "bathroom", displayName: "イス・洗面器洗い", localizedNameKey: "preset.task.bathroom.chairBowlClean", note: "裏側のぬめりを落とす", tools: "スポンジ", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "bathroom_tub_pipe", placeID: "bathroom", displayName: "風呂釜洗浄", localizedNameKey: "preset.task.bathroom.tubPipe", note: "洗浄剤の手順に沿って行う", estimatedMinutes: 20, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),

            PresetTask(id: "toilet_bowl_clean", placeID: "toilet", displayName: "便器掃除", localizedNameKey: "preset.task.toilet.bowlClean", note: "便器内とふちを軽く掃除する", tools: "トイレブラシ、洗剤", estimatedMinutes: 7, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "toilet_floor_wipe", placeID: "toilet", displayName: "床拭き", localizedNameKey: "preset.task.toilet.floorWipe", note: "床と便器まわりを拭く", tools: "掃除シート", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "toilet_seat_lid_wipe", placeID: "toilet", displayName: "便座・レバー拭き", localizedNameKey: "preset.task.toilet.seatLidWipe", note: "手が触れる場所を拭く", tools: "掃除シート", estimatedMinutes: 5, intervalRule: IntervalRule(value: 3, unit: .day)),
            PresetTask(id: "toilet_sink_clean", placeID: "toilet", displayName: "手洗い場掃除", localizedNameKey: "preset.task.toilet.sinkClean", note: "水あかをためない", estimatedMinutes: 5, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "toilet_mat_towel_change", placeID: "toilet", displayName: "マット・タオル交換", localizedNameKey: "preset.task.toilet.matTowelChange", note: "必要なら洗濯へ回す", tools: "替えタオル", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "toilet_wall_handle_wipe", placeID: "toilet", displayName: "壁・ドアノブ拭き", localizedNameKey: "preset.task.toilet.wallHandleWipe", note: "手あかと飛び散りを拭く", tools: "掃除シート", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "toilet_vent_filter", placeID: "toilet", displayName: "換気扇フィルター", localizedNameKey: "preset.task.toilet.ventFilter", note: "ほこりを取る", tools: "掃除機、クロス", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),

            PresetTask(id: "washroom_sink_wipe", placeID: "washroom", displayName: "洗面台拭き", localizedNameKey: "preset.task.washroom.sinkWipe", note: "水あかと髪の毛を取る", tools: "クロス", estimatedMinutes: 5, intervalRule: IntervalRule(value: 3, unit: .day)),
            PresetTask(id: "washroom_mirror_wipe", placeID: "washroom", displayName: "鏡拭き", localizedNameKey: "preset.task.washroom.mirrorWipe", note: "水滴あとを拭く", tools: "クロス", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "washroom_drain_hair", placeID: "washroom", displayName: "排水口の髪取り", localizedNameKey: "preset.task.washroom.drainHair", note: "髪の毛とぬめりを取る", tools: "手袋、ティッシュ", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "washroom_counter_reset", placeID: "washroom", displayName: "洗面台まわり整理", localizedNameKey: "preset.task.washroom.counterReset", note: "出しっぱなしを戻す", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "washroom_towel_change", placeID: "washroom", displayName: "タオル交換", localizedNameKey: "preset.task.washroom.towelChange", note: "湿ったタオルを替える", tools: "替えタオル", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "washroom_toothbrush_stand", placeID: "washroom", displayName: "歯ブラシスタンド洗い", localizedNameKey: "preset.task.washroom.toothbrushStand", note: "底のぬめりを落とす", tools: "スポンジ", estimatedMinutes: 8, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "washroom_cabinet_wipe", placeID: "washroom", displayName: "収納棚拭き", localizedNameKey: "preset.task.washroom.cabinetWipe", note: "棚のほこりを拭く", tools: "クロス", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),

            PresetTask(id: "living_floor_dust", placeID: "living_room", displayName: "床のほこり取り", localizedNameKey: "preset.task.livingRoom.floorDust", note: "見える範囲だけ整える", tools: "掃除機", estimatedMinutes: 8, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "living_table_wipe", placeID: "living_room", displayName: "テーブル拭き", localizedNameKey: "preset.task.livingRoom.tableWipe", note: "手あかと食べこぼしを拭く", estimatedMinutes: 5, intervalRule: IntervalRule(value: 3, unit: .day)),
            PresetTask(id: "living_sofa_crumbs", placeID: "living_room", displayName: "ソファまわり掃除", localizedNameKey: "preset.task.livingRoom.sofaCrumbs", note: "座面とすき間のほこりを取る", tools: "掃除機", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "living_remote_switch_wipe", placeID: "living_room", displayName: "リモコン・スイッチ拭き", localizedNameKey: "preset.task.livingRoom.remoteSwitchWipe", note: "手あかを拭く", tools: "クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "living_shelf_tv_dust", placeID: "living_room", displayName: "棚・テレビまわりほこり取り", localizedNameKey: "preset.task.livingRoom.shelfTVDust", note: "画面はやさしく拭く", tools: "ハンディモップ", estimatedMinutes: 8, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "living_rug_reset", placeID: "living_room", displayName: "ラグ・クッション整え", localizedNameKey: "preset.task.livingRoom.rugReset", note: "ほこりを払って位置を戻す", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "living_window_sill_dust", placeID: "living_room", displayName: "窓まわりほこり取り", localizedNameKey: "preset.task.livingRoom.windowSillDust", note: "サッシ手前と窓台を拭く", tools: "クロス", estimatedMinutes: 8, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),

            PresetTask(id: "bedroom_sheet_change", placeID: "bedroom", displayName: "シーツ交換", localizedNameKey: "preset.task.bedroom.sheetChange", note: "寝具を軽くリセットする", estimatedMinutes: 10, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "bedroom_pillowcase_change", placeID: "bedroom", displayName: "枕カバー交換", localizedNameKey: "preset.task.bedroom.pillowcaseChange", note: "汗や皮脂をためない", tools: "替えカバー", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "bedroom_floor_dust", placeID: "bedroom", displayName: "床のほこり取り", localizedNameKey: "preset.task.bedroom.floorDust", note: "ベッド周りを中心に整える", tools: "フロアワイパー", estimatedMinutes: 8, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "bedroom_bedside_wipe", placeID: "bedroom", displayName: "ベッドサイド拭き", localizedNameKey: "preset.task.bedroom.bedsideWipe", note: "ほこりと小物を整える", tools: "クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "bedroom_clothes_reset", placeID: "bedroom", displayName: "服の一時置きリセット", localizedNameKey: "preset.task.bedroom.clothesReset", note: "椅子や床の服を戻す", estimatedMinutes: 10, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "bedroom_under_bed_dust", placeID: "bedroom", displayName: "ベッド下ほこり取り", localizedNameKey: "preset.task.bedroom.underBedDust", note: "届く範囲だけでOK", tools: "ワイパー", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "bedroom_closet_quick_reset", placeID: "bedroom", displayName: "クローゼット整理", localizedNameKey: "preset.task.bedroom.closetQuickReset", note: "よく使う服だけ整える", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),

            PresetTask(id: "entryway_sweep", placeID: "entryway", displayName: "玄関掃き", localizedNameKey: "preset.task.entryway.sweep", note: "砂やほこりを集める", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "entryway_shoes_reset", placeID: "entryway", displayName: "靴の整理", localizedNameKey: "preset.task.entryway.shoesReset", note: "出ている靴を減らす", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "entryway_floor_wipe", placeID: "entryway", displayName: "たたき拭き", localizedNameKey: "preset.task.entryway.floorWipe", note: "汚れの目立つ部分だけ拭く", tools: "雑巾、掃除シート", estimatedMinutes: 8, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "entryway_mat_shake", placeID: "entryway", displayName: "玄関マット掃除", localizedNameKey: "preset.task.entryway.matShake", note: "砂ぼこりを落とす", tools: "掃除機", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "entryway_door_handle_wipe", placeID: "entryway", displayName: "ドアノブ拭き", localizedNameKey: "preset.task.entryway.doorHandleWipe", note: "手が触れる場所を拭く", tools: "クロス", estimatedMinutes: 3, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "entryway_umbrella_reset", placeID: "entryway", displayName: "傘立て整理", localizedNameKey: "preset.task.entryway.umbrellaReset", note: "濡れた傘や不要な傘を確認する", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),

            PresetTask(id: "laundry_lint_filter", placeID: "laundry", displayName: "糸くずフィルター掃除", localizedNameKey: "preset.task.laundry.lintFilter", note: "たまった糸くずを取る", tools: "ブラシ、ティッシュ", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "laundry_washer_tub_clean", placeID: "laundry", displayName: "洗濯槽掃除", localizedNameKey: "preset.task.laundry.washerTubClean", note: "洗浄剤の手順に沿って行う", tools: "洗濯槽クリーナー", estimatedMinutes: 20, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "laundry_detergent_tray", placeID: "laundry", displayName: "洗剤投入口洗い", localizedNameKey: "preset.task.laundry.detergentTray", note: "洗剤残りを落とす", tools: "ブラシ", estimatedMinutes: 8, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "laundry_washer_exterior", placeID: "laundry", displayName: "洗濯機まわり拭き", localizedNameKey: "preset.task.laundry.washerExterior", note: "ふたや周辺のほこりを拭く", tools: "クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "laundry_basket_reset", placeID: "laundry", displayName: "洗濯かご整理", localizedNameKey: "preset.task.laundry.basketReset", note: "溜まった衣類を仕分ける", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),

            PresetTask(id: "balcony_sweep", placeID: "balcony", displayName: "ベランダ掃き", localizedNameKey: "preset.task.balcony.sweep", note: "排水溝まわりも軽く確認する", estimatedMinutes: 10, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "balcony_drain_check", placeID: "balcony", displayName: "排水口確認", localizedNameKey: "preset.task.balcony.drainCheck", note: "落ち葉やごみ詰まりを確認する", tools: "手袋", estimatedMinutes: 5, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "balcony_rail_wipe", placeID: "balcony", displayName: "手すり拭き", localizedNameKey: "preset.task.balcony.railWipe", note: "ほこりを軽く拭く", tools: "雑巾", estimatedMinutes: 8, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "balcony_pole_wipe", placeID: "balcony", displayName: "物干し竿拭き", localizedNameKey: "preset.task.balcony.poleWipe", note: "洗濯前に汚れを確認する", tools: "クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "balcony_outdoor_unit_area", placeID: "balcony", displayName: "室外機まわり確認", localizedNameKey: "preset.task.balcony.outdoorUnitArea", note: "吸排気口をふさがないようにする", tools: "ほうき", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),
            PresetTask(id: "balcony_window_outside", placeID: "balcony", displayName: "窓外側拭き", localizedNameKey: "preset.task.balcony.windowOutside", note: "手の届く範囲だけ。安全優先", tools: "窓用ワイパー", estimatedMinutes: 20, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),

            PresetTask(id: "office_desk_wipe", placeID: "office", displayName: "デスク拭き", localizedNameKey: "preset.task.office.deskWipe", note: "作業面とキーボードまわりを整える", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "office_keyboard_mouse", placeID: "office", displayName: "キーボード・マウス拭き", localizedNameKey: "preset.task.office.keyboardMouse", note: "すき間のほこりを軽く取る", tools: "クロス、エアダスター", estimatedMinutes: 5, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "office_monitor_dust", placeID: "office", displayName: "モニターほこり取り", localizedNameKey: "preset.task.office.monitorDust", note: "やさしく拭く", tools: "画面用クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "office_paper_reset", placeID: "office", displayName: "書類整理", localizedNameKey: "preset.task.office.paperReset", note: "不要紙と保留を分ける", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "office_under_desk_clean", placeID: "office", displayName: "足元掃除", localizedNameKey: "preset.task.office.underDeskClean", note: "ケーブル周りのほこりを取る", tools: "掃除機", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "office_trash_bin_wipe", placeID: "office", displayName: "ゴミ箱拭き", localizedNameKey: "preset.task.office.trashBinWipe", note: "内側とふちを拭く", tools: "掃除シート", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),

            PresetTask(id: "hallway_floor_dust", placeID: "hallway_stairs", displayName: "廊下のほこり取り", localizedNameKey: "preset.task.hallway.floorDust", note: "通り道をさっと整える", tools: "フロアワイパー", estimatedMinutes: 8, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "hallway_stairs_clean", placeID: "hallway_stairs", displayName: "階段掃除", localizedNameKey: "preset.task.hallway.stairsClean", note: "端のほこりを取る", tools: "掃除機、ワイパー", estimatedMinutes: 10, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "hallway_handrail_wipe", placeID: "hallway_stairs", displayName: "手すり拭き", localizedNameKey: "preset.task.hallway.handrailWipe", note: "手が触れる場所を拭く", tools: "クロス", estimatedMinutes: 5, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "hallway_switch_wipe", placeID: "hallway_stairs", displayName: "スイッチ拭き", localizedNameKey: "preset.task.hallway.switchWipe", note: "手あかを拭く", tools: "クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),
            PresetTask(id: "hallway_baseboard_dust", placeID: "hallway_stairs", displayName: "巾木ほこり取り", localizedNameKey: "preset.task.hallway.baseboardDust", note: "目立つ場所だけでOK", tools: "ハンディモップ", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),

            PresetTask(id: "closet_quick_reset", placeID: "closet_storage", displayName: "収納リセット", localizedNameKey: "preset.task.closet.quickReset", note: "出し入れしづらい場所を整える", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "closet_shelf_dust", placeID: "closet_storage", displayName: "棚のほこり取り", localizedNameKey: "preset.task.closet.shelfDust", note: "空いている段だけ拭く", tools: "クロス", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),
            PresetTask(id: "closet_humidity_item", placeID: "closet_storage", displayName: "除湿剤確認", localizedNameKey: "preset.task.closet.humidityItem", note: "水がたまっていたら交換する", tools: "交換用除湿剤", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),
            PresetTask(id: "closet_seasonal_check", placeID: "closet_storage", displayName: "季節もの確認", localizedNameKey: "preset.task.closet.seasonalCheck", note: "使わないものを奥へ移す", estimatedMinutes: 15, priority: .low, intervalRule: IntervalRule(value: 180, unit: .day)),

            PresetTask(id: "other_small_reset", placeID: "other", displayName: "気になる場所のリセット", localizedNameKey: "preset.task.other.smallReset", note: "ひとつだけ気になる場所を整える", estimatedMinutes: 5, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "other_quick_wipe", placeID: "other", displayName: "気になる場所を拭く", localizedNameKey: "preset.task.other.quickWipe", note: "汚れが見える場所だけ拭く", tools: "クロス", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 14, unit: .day)),

            PresetTask(id: "maintenance_ac_filter", placeID: "home_maintenance", displayName: "エアコンフィルター", localizedNameKey: "preset.task.maintenance.acFilter", note: "使用時期だけでOK。フィルターのほこりを取る", tools: "掃除機、ブラシ", estimatedMinutes: 15, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "maintenance_air_purifier_filter", placeID: "home_maintenance", displayName: "空気清浄機フィルター", localizedNameKey: "preset.task.maintenance.airPurifierFilter", note: "外側とフィルターのほこりを取る", tools: "掃除機", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "maintenance_humidifier", placeID: "home_maintenance", displayName: "加湿器掃除", localizedNameKey: "preset.task.maintenance.humidifier", note: "使用時期だけ。タンクとトレーを洗う", tools: "スポンジ", estimatedMinutes: 10, priority: .high, intervalRule: IntervalRule(value: 7, unit: .day)),
            PresetTask(id: "maintenance_vacuum_filter", placeID: "home_maintenance", displayName: "掃除機フィルター掃除", localizedNameKey: "preset.task.maintenance.vacuumFilter", note: "吸引力が落ちる前に整える", tools: "ブラシ、ゴミ袋", estimatedMinutes: 10, intervalRule: IntervalRule(value: 30, unit: .day)),
            PresetTask(id: "maintenance_water_filter", placeID: "home_maintenance", displayName: "浄水器交換", localizedNameKey: "preset.task.maintenance.waterFilter", note: "交換時期を確認する", tools: "交換カートリッジ", estimatedMinutes: 5, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),
            PresetTask(id: "maintenance_mattress_rotate", placeID: "home_maintenance", displayName: "マットレス回転", localizedNameKey: "preset.task.maintenance.mattressRotate", note: "上下や表裏を入れ替える", estimatedMinutes: 10, intervalRule: IntervalRule(value: 90, unit: .day)),
            PresetTask(id: "maintenance_smoke_detector", placeID: "home_maintenance", displayName: "煙探知機確認", localizedNameKey: "preset.task.maintenance.smokeDetector", note: "テストボタンで動作を確認する", estimatedMinutes: 5, intervalRule: IntervalRule(value: 180, unit: .day)),
            PresetTask(id: "maintenance_window_screen", placeID: "home_maintenance", displayName: "網戸掃除", localizedNameKey: "preset.task.maintenance.windowScreen", note: "片面ずつ軽くほこりを取る", tools: "ブラシ、クロス", estimatedMinutes: 20, priority: .low, intervalRule: IntervalRule(value: 90, unit: .day)),
            PresetTask(id: "maintenance_curtain_wash", placeID: "home_maintenance", displayName: "カーテン洗濯", localizedNameKey: "preset.task.maintenance.curtainWash", note: "洗濯表示を確認する", tools: "洗濯ネット", estimatedMinutes: 25, priority: .low, intervalRule: IntervalRule(value: 180, unit: .day)),
            PresetTask(id: "maintenance_shower_head", placeID: "home_maintenance", displayName: "シャワーヘッド洗浄", localizedNameKey: "preset.task.maintenance.showerHead", note: "水あかが気になる時だけ", tools: "クエン酸など", estimatedMinutes: 10, priority: .low, intervalRule: IntervalRule(value: 60, unit: .day))
        ]
    }

    var onboardingPlaces: [PresetPlace] {
        let primaryIDs = ["kitchen", "bathroom", "toilet", "washroom", "living_room", "bedroom", "entryway"]
        return primaryIDs.compactMap { id in
            places.first { $0.id == id }
        }
    }

    var homeMaintenanceTasks: [PresetTask] {
        tasks(for: homeMaintenancePlace.id)
    }

    func place(for id: String) -> PresetPlace? {
        (places + [homeMaintenancePlace]).first { $0.id == id }
    }

    func tasks(for placeID: String) -> [PresetTask] {
        tasks.filter { $0.placeID == placeID }
    }

    func tasks(for placeIDs: Set<String>) -> [PresetTask] {
        tasks.filter { placeIDs.contains($0.placeID) }
    }
}
