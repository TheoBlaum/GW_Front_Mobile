//
//  SurfSpotSaveService.swift
//  good-wave
//

import Foundation

enum FavoriteServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse(let statusCode):
            return "Erreur serveur: \(statusCode)"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        }
    }
}

class SurfSpotSaveService {
    private let baseURL = APIConfig.baseURL
    private let userId = APIConfig.userId
    
    // Ajouter un spot aux favoris
    func addFavorite(spotId: String) async throws {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/favorites/\(spotId)") else {
            throw FavoriteServiceError.invalidURL
        }
        
        print("❤️ Ajout favori: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Pas de body pour POST favorite selon la doc
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FavoriteServiceError.invalidResponse(0)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Erreur serveur: \(errorString)")
                }
                throw FavoriteServiceError.invalidResponse(httpResponse.statusCode)
            }
            
            print("✅ Favori ajouté avec succès")
        } catch {
            if let urlError = error as? URLError {
                throw FavoriteServiceError.networkError(urlError)
            } else if error is FavoriteServiceError {
                throw error
            } else {
                throw FavoriteServiceError.networkError(error)
            }
        }
    }
    
    // Retirer un spot des favoris
    func removeFavorite(spotId: String) async throws {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/favorites/\(spotId)") else {
            throw FavoriteServiceError.invalidURL
        }
        
        print("💔 Suppression favori: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FavoriteServiceError.invalidResponse(0)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Erreur serveur: \(errorString)")
                }
                throw FavoriteServiceError.invalidResponse(httpResponse.statusCode)
            }
            
            print("✅ Favori supprimé avec succès")
        } catch {
            if let urlError = error as? URLError {
                throw FavoriteServiceError.networkError(urlError)
            } else if error is FavoriteServiceError {
                throw error
            } else {
                throw FavoriteServiceError.networkError(error)
            }
        }
    }
    
    // Récupérer la liste des favoris
    func fetchFavorites() async throws -> [SurfSpot] {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/favorites") else {
            throw FavoriteServiceError.invalidURL
        }
        
        print("📋 Récupération favoris: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FavoriteServiceError.invalidResponse(0)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Erreur serveur: \(errorString)")
                }
                throw FavoriteServiceError.invalidResponse(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let favorites = try decoder.decode([SurfSpot].self, from: data)
                print("✅ \(favorites.count) favoris récupérés")
                return favorites
            } catch {
                print("❌ Erreur décodage favoris: \(error)")
                throw FavoriteServiceError.networkError(error)
            }
        } catch {
            if let urlError = error as? URLError {
                throw FavoriteServiceError.networkError(urlError)
            } else if error is FavoriteServiceError {
                throw error
            } else {
                throw FavoriteServiceError.networkError(error)
            }
        }
    }
    
    // Méthode générique pour toggle (utilisée par le ViewModel)
    func updateSavedStatus(for spotId: String, saved: Bool) async throws {
        if saved {
            try await addFavorite(spotId: spotId)
        } else {
            try await removeFavorite(spotId: spotId)
        }
    }
}
