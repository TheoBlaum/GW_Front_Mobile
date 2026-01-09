//
//  SurfSpot.swift
//  good-wave
//

import Foundation

struct SurfSpot: Identifiable, Codable, Equatable {
    // Format Laravel
    private let laravelId: Int
    let name: String
    let location: String
    let type: String
    let level: String
    let ambiance: String?
    let accessibilityParking: Bool?
    let accessibilityRamp: Bool?
    let accessibilityDistance: Int?
    let ecologyZoneProtected: Bool?
    let createdAt: String?
    let updatedAt: String?
    
    // Propriétés calculées pour compatibilité avec l'UI existante
    var id: String { String(laravelId) }
    var destination: String { name }
    var country: String { location }
    var surfBreak: [String] { [type] }
    var difficultyLevel: Int {
        switch level.lowercased() {
        case "beginner":
            return 1
        case "intermediate":
            return 3
        case "advanced":
            return 5
        default:
            return 3
        }
    }
    var photoURL: String { "" } // Pas de photo dans le format Laravel actuel
    var peakSeasonBegins: String { "2025-01-01" } // Pas dans le format Laravel actuel
    var peakSeasonEnds: String { "2025-12-31" } // Pas dans le format Laravel actuel
    var address: String { location }
    var forecastURL: String? { nil } // Pas dans le format Laravel actuel
    var geocode: String? { nil } // Pas dans le format Laravel actuel
    var saved: Bool = false // Sera géré via l'API favorites
    
    var formattedPeakSeasonBegins: String {
        return formatDate(peakSeasonBegins)
    }
    
    var formattedPeakSeasonEnds: String {
        return formatDate(peakSeasonEnds)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        isoFormatter.locale = Locale(identifier: "en_US")
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM d"
        displayFormatter.locale = Locale(identifier: "en_US")
        
        if let date = isoFormatter.date(from: dateString) {
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    enum CodingKeys: String, CodingKey {
        case laravelId = "id"
        case name
        case location
        case type
        case level
        case ambiance
        case accessibilityParking = "accessibility_parking"
        case accessibilityRamp = "accessibility_ramp"
        case accessibilityDistance = "accessibility_distance"
        case ecologyZoneProtected = "ecology_zone_protected"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var title: String { destination }
    
    // Init manuel pour compatibilité
    init(
        id: String,
        photoURL: String = "",
        destination: String,
        country: String,
        peakSeasonBegins: String = "2025-01-01",
        peakSeasonEnds: String = "2025-12-31",
        surfBreak: [String],
        difficultyLevel: Int,
        address: String = "",
        forecastURL: String? = nil,
        geocode: String? = nil,
        saved: Bool = false
    ) {
        self.laravelId = Int(id) ?? 0
        self.name = destination
        self.location = country
        self.type = surfBreak.first ?? "beach"
        self.level = {
            switch difficultyLevel {
            case 1...2: return "beginner"
            case 3: return "intermediate"
            case 4...5: return "advanced"
            default: return "intermediate"
            }
        }()
        self.ambiance = nil
        self.accessibilityParking = nil
        self.accessibilityRamp = nil
        self.accessibilityDistance = nil
        self.ecologyZoneProtected = nil
        self.createdAt = nil
        self.updatedAt = nil
        self.saved = saved
    }
    
    // Init depuis le format Laravel
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        laravelId = try container.decode(Int.self, forKey: .laravelId)
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        type = try container.decode(String.self, forKey: .type)
        level = try container.decode(String.self, forKey: .level)
        ambiance = try container.decodeIfPresent(String.self, forKey: .ambiance)
        accessibilityParking = try container.decodeIfPresent(Bool.self, forKey: .accessibilityParking)
        accessibilityRamp = try container.decodeIfPresent(Bool.self, forKey: .accessibilityRamp)
        accessibilityDistance = try container.decodeIfPresent(Int.self, forKey: .accessibilityDistance)
        ecologyZoneProtected = try container.decodeIfPresent(Bool.self, forKey: .ecologyZoneProtected)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        saved = false // Sera mis à jour via l'API favorites
    }
    
    // Init avec saved personnalisé
    init(
        laravelId: Int,
        name: String,
        location: String,
        type: String,
        level: String,
        ambiance: String? = nil,
        accessibilityParking: Bool? = nil,
        accessibilityRamp: Bool? = nil,
        accessibilityDistance: Int? = nil,
        ecologyZoneProtected: Bool? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        saved: Bool = false
    ) {
        self.laravelId = laravelId
        self.name = name
        self.location = location
        self.type = type
        self.level = level
        self.ambiance = ambiance
        self.accessibilityParking = accessibilityParking
        self.accessibilityRamp = accessibilityRamp
        self.accessibilityDistance = accessibilityDistance
        self.ecologyZoneProtected = ecologyZoneProtected
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.saved = saved
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(laravelId, forKey: .laravelId)
        try container.encode(name, forKey: .name)
        try container.encode(location, forKey: .location)
        try container.encode(type, forKey: .type)
        try container.encode(level, forKey: .level)
        try container.encodeIfPresent(ambiance, forKey: .ambiance)
        try container.encodeIfPresent(accessibilityParking, forKey: .accessibilityParking)
        try container.encodeIfPresent(accessibilityRamp, forKey: .accessibilityRamp)
        try container.encodeIfPresent(accessibilityDistance, forKey: .accessibilityDistance)
        try container.encodeIfPresent(ecologyZoneProtected, forKey: .ecologyZoneProtected)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // Fonction pour mettre à jour le statut saved
    func withSaved(_ saved: Bool) -> SurfSpot {
        return SurfSpot(
            laravelId: laravelId,
            name: name,
            location: location,
            type: type,
            level: level,
            ambiance: ambiance,
            accessibilityParking: accessibilityParking,
            accessibilityRamp: accessibilityRamp,
            accessibilityDistance: accessibilityDistance,
            ecologyZoneProtected: ecologyZoneProtected,
            createdAt: createdAt,
            updatedAt: updatedAt,
            saved: saved
        )
    }
}
