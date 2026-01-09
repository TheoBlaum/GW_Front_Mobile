//
//  WorldMapView.swift
//  good-wave
//
//  Created on 2025.
//

import SwiftUI
import MapKit

enum MapType {
    case standard
    case satellite
    case hybrid
    
    var mkMapType: MKMapType {
        switch self {
        case .standard:
            return .standard
        case .satellite:
            return .satellite
        case .hybrid:
            return .hybrid
        }
    }
    
    var icon: String {
        switch self {
        case .standard:
            return "map"
        case .satellite:
            return "globe"
        case .hybrid:
            return "map.fill"
        }
    }
}

struct WorldMapView: View {
    @EnvironmentObject var viewModel: SurfSpotViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
    )
    @State private var spotCoordinates: [String: CLLocationCoordinate2D] = [:]
    @State private var isGeocoding = false
    @State private var selectedSpot: SurfSpot?
    @State private var mapType: MapType = .standard
    @State private var regionUpdateTrigger: UUID = UUID()
    @Binding var showTabBar: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                MapViewWithType(
                    region: $region,
                    annotations: mapAnnotations,
                    mapType: mapType.mkMapType,
                    regionUpdateTrigger: regionUpdateTrigger,
                    onAnnotationTap: { spot in
                        selectedSpot = spot
                    }
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    if spotCoordinates.isEmpty {
                        geocodeAllSpots()
                    }
                }
                .onChange(of: viewModel.surfSpots.count) { _ in
                    // Recharger les coordonnées si de nouveaux spots sont ajoutés
                    let newSpots = viewModel.surfSpots.filter { spotCoordinates[$0.id] == nil }
                    if !newSpots.isEmpty && !isGeocoding {
                        geocodeNewSpots(newSpots)
                    }
                }
                
                if isGeocoding {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Chargement des positions...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                }
                
                // Boutons de contrôle
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Bouton pour changer le type de carte
                            Button(action: {
                                withAnimation {
                                    switch mapType {
                                    case .standard:
                                        mapType = .satellite
                                    case .satellite:
                                        mapType = .hybrid
                                    case .hybrid:
                                        mapType = .standard
                                    }
                                }
                            }) {
                                Image(systemName: mapType.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(22)
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
                            }
                            
                            // Bouton pour recentrer sur tous les spots
                            Button(action: {
                                if spotCoordinates.isEmpty && !viewModel.surfSpots.isEmpty {
                                    geocodeAllSpots()
                                } else {
                                    recenterOnAllSpots()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("All Spots")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedSpot) { spot in
                ContentView(spot: spot, viewModel: viewModel)
            }
            .onAppear {
                withAnimation {
                    showTabBar = true
                }
            }
        }
    }
    
    private var mapAnnotations: [MapAnnotationItem] {
        viewModel.surfSpots.compactMap { spot in
            guard let coordinate = spotCoordinates[spot.id] else { return nil }
            return MapAnnotationItem(spot: spot, coordinate: coordinate)
        }
    }
    
    private func geocodeAllSpots() {
        guard !isGeocoding else { return }
        isGeocoding = true
        
        let spots = viewModel.surfSpots
        guard !spots.isEmpty else {
            isGeocoding = false
            return
        }
        
        let coordinatesQueue = DispatchQueue(label: "coordinates.queue")
        var coordinates: [String: CLLocationCoordinate2D] = [:]
        let semaphore = DispatchSemaphore(value: 3) // Limiter à 3 requêtes simultanées
        let group = DispatchGroup()
        let geocodingQueue = DispatchQueue(label: "geocoding.queue", attributes: .concurrent)
        
        for spot in spots {
            group.enter()
            geocodingQueue.async {
                semaphore.wait()
                let address = !spot.address.isEmpty ? spot.address : spot.destination
                let geocoder = CLGeocoder()
                
                geocoder.geocodeAddressString(address) { placemarks, error in
                    defer {
                        semaphore.signal()
                        group.leave()
                    }
                    
                    if let location = placemarks?.first?.location {
                        coordinatesQueue.async {
                            coordinates[spot.id] = location.coordinate
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            coordinatesQueue.sync {
                self.spotCoordinates = coordinates
            }
            self.isGeocoding = false
            
            // Ajuster la région pour afficher tous les spots
            if !self.spotCoordinates.isEmpty {
                self.adjustRegionToFitAllSpots(coordinates: self.spotCoordinates)
            }
        }
    }
    
    private func geocodeNewSpots(_ spots: [SurfSpot]) {
        guard !isGeocoding else { return }
        isGeocoding = true
        
        let coordinatesQueue = DispatchQueue(label: "coordinates.queue")
        var newCoordinates: [String: CLLocationCoordinate2D] = [:]
        let semaphore = DispatchSemaphore(value: 3)
        let group = DispatchGroup()
        let geocodingQueue = DispatchQueue(label: "geocoding.queue", attributes: .concurrent)
        
        for spot in spots {
            group.enter()
            geocodingQueue.async {
                semaphore.wait()
                let address = !spot.address.isEmpty ? spot.address : spot.destination
                let geocoder = CLGeocoder()
                
                geocoder.geocodeAddressString(address) { placemarks, error in
                    defer {
                        semaphore.signal()
                        group.leave()
                    }
                    
                    if let location = placemarks?.first?.location {
                        coordinatesQueue.async {
                            newCoordinates[spot.id] = location.coordinate
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            coordinatesQueue.sync {
                self.spotCoordinates.merge(newCoordinates) { (_, new) in new }
            }
            self.isGeocoding = false
            
            // Ajuster la région si nécessaire
            if !self.spotCoordinates.isEmpty {
                self.adjustRegionToFitAllSpots(coordinates: self.spotCoordinates)
            }
        }
    }
    
    private func recenterOnAllSpots() {
        guard !spotCoordinates.isEmpty else { return }
        adjustRegionToFitAllSpots(coordinates: spotCoordinates)
    }
    
    private func adjustRegionToFitAllSpots(coordinates: [String: CLLocationCoordinate2D]) {
        let allCoordinates = Array(coordinates.values)
        
        guard !allCoordinates.isEmpty else { return }
        
        let minLat = allCoordinates.map { $0.latitude }.min() ?? 0
        let maxLat = allCoordinates.map { $0.latitude }.max() ?? 0
        let minLon = allCoordinates.map { $0.longitude }.min() ?? 0
        let maxLon = allCoordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let latDelta = max((maxLat - minLat) * 1.3, 20.0) // Au moins 20 degrés
        let lonDelta = max((maxLon - minLon) * 1.3, 20.0) // Au moins 20 degrés
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(
                    latitudeDelta: min(latDelta, 180),
                    longitudeDelta: min(lonDelta, 360)
                )
            )
            // Forcer la mise à jour de la région
            regionUpdateTrigger = UUID()
        }
    }
}

// Extension pour les coins arrondis personnalisés
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let spot: SurfSpot
    let coordinate: CLLocationCoordinate2D
}

// Vue MapKit avec support du type de carte
struct MapViewWithType: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [MapAnnotationItem]
    let mapType: MKMapType
    let regionUpdateTrigger: UUID
    let onAnnotationTap: (SurfSpot) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.region = region
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Mettre à jour les annotations dans le coordinator
        context.coordinator.annotations = annotations
        
        // Mettre à jour le type de carte (sans affecter la région)
        let mapTypeChanged = mapView.mapType != mapType
        if mapTypeChanged {
            mapView.mapType = mapType
        }
        
        // Vérifier si le trigger a changé (force la mise à jour)
        if context.coordinator.lastRegionUpdateTrigger != regionUpdateTrigger {
            context.coordinator.lastRegionUpdateTrigger = regionUpdateTrigger
            mapView.setRegion(region, animated: true)
        } else if !mapTypeChanged {
            // Mettre à jour la région seulement si elle a changé ET que ce n'est pas juste un changement de type de carte
            let latDiff = abs(mapView.region.center.latitude - region.center.latitude)
            let lonDiff = abs(mapView.region.center.longitude - region.center.longitude)
            let spanLatDiff = abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta)
            let spanLonDiff = abs(mapView.region.span.longitudeDelta - region.span.longitudeDelta)
            
            if latDiff > 0.001 || lonDiff > 0.001 || spanLatDiff > 0.001 || spanLonDiff > 0.001 {
                mapView.setRegion(region, animated: true)
            }
        }
        // Si mapTypeChanged est true, on ne met pas à jour la région pour préserver le zoom actuel
        
        // Mettre à jour les annotations seulement si elles ont changé
        let currentAnnotationCount = mapView.annotations.filter { !($0 is MKUserLocation) }.count
        if currentAnnotationCount != annotations.count {
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            let mkAnnotations = annotations.map { item -> MKPointAnnotation in
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.coordinate
                annotation.title = item.spot.destination
                return annotation
            }
            mapView.addAnnotations(mkAnnotations)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(onAnnotationTap: onAnnotationTap)
        coordinator.annotations = annotations
        return coordinator
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let onAnnotationTap: (SurfSpot) -> Void
        var annotations: [MapAnnotationItem] = []
        var lastRegionUpdateTrigger: UUID = UUID()
        
        init(onAnnotationTap: @escaping (SurfSpot) -> Void) {
            self.onAnnotationTap = onAnnotationTap
        }
        
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "SurfSpotAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Trouver le spot correspondant
            if let pointAnnotation = annotation as? MKPointAnnotation,
               let spot = annotations.first(where: { $0.coordinate.latitude == pointAnnotation.coordinate.latitude && $0.coordinate.longitude == pointAnnotation.coordinate.longitude }) {
                
                let markerView = annotationView as? MKMarkerAnnotationView
                markerView?.markerTintColor = .red
                markerView?.glyphImage = UIImage(systemName: "mappin.circle.fill")
                
                // Ajouter un bouton d'info
                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? MKPointAnnotation else { return }
            
            if let spot = annotations.first(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                onAnnotationTap(spot.spot)
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MKPointAnnotation else { return }
            
            if let spot = annotations.first(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                // Optionnel: action immédiate au tap
            }
        }
    }
}

#Preview {
    WorldMapView(showTabBar: .constant(true))
        .environmentObject(SurfSpotViewModel())
}

