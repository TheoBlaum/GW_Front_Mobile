//
//  SurfSpotViewModel.swift
//  good-wave
//

import Foundation
import UIKit

@MainActor
class SurfSpotViewModel: ObservableObject {
    @Published var surfSpots: [SurfSpot] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var totalPages = 1
    let pageSize = 10
    
    private let service: SurfSpotService
    private let saveService: SurfSpotSaveService
    
    init(service: SurfSpotService = SurfSpotService(), saveService: SurfSpotSaveService = SurfSpotSaveService()) {
        self.service = service
        self.saveService = saveService
        Task {
            await loadFirstPage()
        }
    }
    
    func loadFirstPage(forceRefresh: Bool = false) async {
        isLoading = true
        error = nil
        do {
            let response = try await service.fetchSurfSpots(page: 1, pageSize: pageSize, forceRefresh: forceRefresh)
            var spots = response.data
            
            // Charger les favoris et mettre à jour le statut saved
            await updateFavoritesStatus(for: &spots)
            
            self.surfSpots = spots
            self.currentPage = response.page
            self.totalPages = response.totalPages
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    // Mettre à jour le statut saved des spots en fonction des favoris
    private func updateFavoritesStatus(for spots: inout [SurfSpot]) async {
        do {
            let favorites = try await saveService.fetchFavorites()
            let favoriteIds = Set(favorites.map { $0.id })
            
            // Mettre à jour le statut saved pour chaque spot
            for i in 0..<spots.count {
                spots[i] = spots[i].withSaved(favoriteIds.contains(spots[i].id))
            }
        } catch {
            print("⚠️ Erreur lors du chargement des favoris: \(error.localizedDescription)")
            // En cas d'erreur, on continue sans mettre à jour les favoris
        }
    }

    func loadNextPage() async {
        guard !isLoading, currentPage < totalPages else { return }
        isLoading = true
        let nextPage = currentPage + 1
        do {
            let response = try await service.fetchSurfSpots(page: nextPage, pageSize: pageSize)
            // Filtre les doublons éventuels
            var newSpots = response.data.filter { newSpot in
                !self.surfSpots.contains(where: { $0.id == newSpot.id })
            }
            
            // Mettre à jour le statut saved pour les nouveaux spots
            await updateFavoritesStatus(for: &newSpots)
            
            self.surfSpots += newSpots
            print("IDs après pagination:", self.surfSpots.map { $0.id })
            self.currentPage = response.page
            self.totalPages = response.totalPages
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func toggleSaved(for spot: SurfSpot) {
        Task {
            do {
                let updatedSaved = !spot.saved
                try await saveService.updateSavedStatus(for: spot.id, saved: updatedSaved)
                
                // Mettre à jour le spot dans la liste
                if let index = surfSpots.firstIndex(where: { $0.id == spot.id }) {
                    surfSpots[index] = spot.withSaved(updatedSaved)
                }
            } catch {
                print("❌ Erreur lors du toggle saved : \(error.localizedDescription)")
                // Optionnel: afficher une alerte à l'utilisateur
                self.error = "Erreur lors de la mise à jour du favori: \(error.localizedDescription)"
            }
        }
    }
    
    func filteredSpots(selectedType: String?, searchText: String) -> [SurfSpot] {
        var spots = surfSpots
        if let selectedType = selectedType {
            spots = spots.filter { $0.surfBreak.contains(selectedType) }
        }
        if !searchText.isEmpty {
            spots = spots.filter {
                $0.destination.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        return spots
    }
}
