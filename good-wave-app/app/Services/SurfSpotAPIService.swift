//
//  SurfSpotAPIService.swift
//  good-wave
//

import Foundation

enum SurfSpotServiceError: Error, LocalizedError {
    case networkUnavailable
    case invalidURL
    case invalidResponse(Int)
    case decodingError(Error)
    case serverUnreachable
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Connexion réseau indisponible"
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse(let statusCode):
            return "Réponse serveur invalide: \(statusCode)"
        case .decodingError:
            return "Erreur de format de données"
        case .serverUnreachable:
            return "Serveur inaccessible. Vérifiez que le serveur Laravel est en cours d'exécution sur http://127.0.0.1:8000"
        }
    }
}

class SurfSpotService {
    private let baseURL = APIConfig.baseURL
    
    func fetchSurfSpots(page: Int = 1, pageSize: Int = 10, forceRefresh: Bool = false) async throws -> PaginatedResponse<SurfSpot> {
        // Construire l'URL avec les paramètres de pagination
        // Laravel utilise 'per_page' par défaut, mais le backend peut accepter 'pageSize'
        var urlComponents = URLComponents(string: "\(baseURL)/spots")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)) // Le backend accepte pageSize selon la doc
        ]
        
        guard let url = urlComponents?.url else {
            throw SurfSpotServiceError.invalidURL
        }
        
        print("🌐 Requête API: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SurfSpotServiceError.serverUnreachable
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Erreur HTTP: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Réponse: \(errorString)")
                }
                throw SurfSpotServiceError.invalidResponse(httpResponse.statusCode)
            }
            
            // Afficher le JSON reçu pour débogage
            if let jsonString = String(data: data, encoding: .utf8) {
                print("✅ JSON reçu (premiers 1000 caractères):")
                print(String(jsonString.prefix(1000)))
                print("---")
            }
            
            // Essayer de parser le JSON pour voir sa structure
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("📋 Structure JSON détectée:")
                print("Clés disponibles: \(jsonObject.keys.joined(separator: ", "))")
                if let dataArray = jsonObject["data"] as? [Any] {
                    print("✅ 'data' trouvé avec \(dataArray.count) éléments")
                }
                if jsonObject["meta"] != nil {
                    print("✅ 'meta' trouvé")
                } else {
                    print("⚠️ 'meta' absent")
                }
                if jsonObject["links"] != nil {
                    print("✅ 'links' trouvé")
                } else {
                    print("⚠️ 'links' absent")
                }
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let paginatedResponse = try decoder.decode(PaginatedResponse<SurfSpot>.self, from: data)
                print("✅ \(paginatedResponse.data.count) spots chargés (page \(paginatedResponse.page)/\(paginatedResponse.totalPages))")
                return paginatedResponse
            } catch {
                print("❌ Erreur lors du décodage: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Clé manquante: \(key.stringValue) - \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: \(type) - \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Valeur non trouvée: \(type) - \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Données corrompues: \(context.debugDescription)")
                    @unknown default:
                        print("Erreur de décodage inconnue")
                    }
                }
                throw SurfSpotServiceError.decodingError(error)
            }
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    throw SurfSpotServiceError.networkUnavailable
                case .cannotConnectToHost, .cannotFindHost:
                    throw SurfSpotServiceError.serverUnreachable
                default:
                    print("URLError non géré: \(urlError)")
                    throw error
                }
            } else if error is SurfSpotServiceError {
                throw error
            } else {
                print("Erreur inattendue: \(error)")
                throw SurfSpotServiceError.serverUnreachable
            }
        }
    }
    
    func fetchSurfSpot(id: String) async throws -> SurfSpot {
        guard let url = URL(string: "\(baseURL)/spots/\(id)") else {
            throw SurfSpotServiceError.invalidURL
        }
        
        print("🌐 Requête API: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SurfSpotServiceError.serverUnreachable
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SurfSpotServiceError.invalidResponse(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let spot = try decoder.decode(SurfSpot.self, from: data)
            return spot
        } catch {
            throw SurfSpotServiceError.decodingError(error)
        }
    }
}
