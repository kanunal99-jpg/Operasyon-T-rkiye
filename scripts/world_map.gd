extends Node

const MISSIONS := [
    {"id": 1, "region": "MARMARA", "title": "Boğaz Hattı", "location": "İstanbul çevresi", "objective": "Düşman keşif ekibini etkisiz hale getir.", "difficulty": 1},
    {"id": 2, "region": "EGE", "title": "Kıyı Görevi", "location": "İzmir hattı", "objective": "İletişim merkezini güvence altına al.", "difficulty": 2},
    {"id": 3, "region": "AKDENİZ", "title": "Liman Operasyonu", "location": "Mersin hattı", "objective": "Liman bölgesindeki tehdidi temizle.", "difficulty": 2},
    {"id": 4, "region": "İÇ ANADOLU", "title": "Kritik Konvoy", "location": "Ankara çevresi", "objective": "Konvoyu koru ve hedef bölgeye ulaştır.", "difficulty": 3},
    {"id": 5, "region": "KARADENİZ", "title": "Sis Hattı", "location": "Samsun çevresi", "objective": "Gözetleme noktasını geri al.", "difficulty": 3},
    {"id": 6, "region": "DOĞU ANADOLU", "title": "Dağ Geçidi", "location": "Erzurum hattı", "objective": "Geçidi aç ve ileri ekibe yol ver.", "difficulty": 4},
    {"id": 7, "region": "GÜNEYDOĞU", "title": "Sınır Görevi", "location": "Şanlıurfa hattı", "objective": "İleri karakolu savun.", "difficulty": 4},
    {"id": 8, "region": "FİNAL", "title": "Son Operasyon", "location": "Türkiye genel operasyon bölgesi", "objective": "Ana tehdidi ortadan kaldır ve görevi tamamla.", "difficulty": 5}
]

var unlocked_mission := 1

func get_mission(id: int) -> Dictionary:
    for mission in MISSIONS:
        if mission.id == id:
            return mission
    return {}

func complete_mission(id: int) -> void:
    if id >= unlocked_mission and id < MISSIONS.size():
        unlocked_mission = id + 1

func is_unlocked(id: int) -> bool:
    return id <= unlocked_mission
