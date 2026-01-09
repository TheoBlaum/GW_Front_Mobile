import Foundation

// Format de pagination Laravel standard
struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let links: Links?
    let meta: Meta?
    
    struct Links: Decodable {
        let first: String?
        let last: String?
        let prev: String?
        let next: String?
        
        // Laravel retourne links comme un array d'objets avec url, label, active
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            var items: [LinkItem] = []
            
            while !container.isAtEnd {
                let item = try container.decode(LinkItem.self)
                items.append(item)
            }
            
            // Extraire les URLs depuis l'array
            // Laravel retourne généralement: [First, Previous, ..., Next, Last]
            self.first = items.first?.url
            self.last = items.last?.url
            
            // Chercher Previous et Next dans l'array
            self.prev = items.first(where: { 
                $0.label.contains("Previous") || $0.label.contains("&laquo;") || $0.label == "&laquo; Previous"
            })?.url
            
            self.next = items.first(where: { 
                $0.label.contains("Next") || $0.label.contains("&raquo;") || $0.label == "Next &raquo;"
            })?.url
        }
        
        // Structure pour les items de l'array links
        struct LinkItem: Decodable {
            let url: String?
            let label: String
            let active: Bool
        }
    }
    
    struct Meta: Decodable {
        let currentPage: Int
        let from: Int?
        let lastPage: Int
        let path: String
        let perPage: Int
        let to: Int?
        let total: Int
        
        enum CodingKeys: String, CodingKey {
            case currentPage = "current_page"
            case from
            case lastPage = "last_page"
            case path
            case perPage = "per_page"
            case to
            case total
        }
    }
    
    // Propriétés calculées pour compatibilité avec le code existant
    var page: Int { meta?.currentPage ?? 1 }
    var pageSize: Int { meta?.perPage ?? data.count }
    var totalPages: Int { meta?.lastPage ?? 1 }
    var totalItems: Int { meta?.total ?? data.count }
    
    // Initialiseur personnalisé pour gérer les cas où meta/links sont absents
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // data est toujours présent
        data = try container.decode([T].self, forKey: .data)
        
        // links et meta sont optionnels
        links = try container.decodeIfPresent(Links.self, forKey: .links)
        meta = try container.decodeIfPresent(Meta.self, forKey: .meta)
    }
    
    enum CodingKeys: String, CodingKey {
        case data
        case links
        case meta
    }
}