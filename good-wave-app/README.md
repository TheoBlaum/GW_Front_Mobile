# Good Wave 🌊

Une application iOS moderne pour les surfeurs, permettant de découvrir et suivre les meilleurs spots de surf à travers le monde.

## Fonctionnalités

- 📍 Découverte de spots de surf avec pagination
- 🌟 Système de notation de difficulté (1 à 5 étoiles)
- 📅 Suivi des saisons optimales
- 🔍 Recherche de spots par localisation ou nom
- 🗺️ Carte mondiale interactive avec géolocalisation
- ❤️ Système de favoris pour sauvegarder vos spots préférés
- 🌤️ Météo en temps réel pour chaque spot
- 📱 Interface utilisateur intuitive et moderne

## Prérequis

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- Backend Laravel en cours d'exécution sur `http://127.0.0.1:8000`

## Installation

1. Clonez le repository :
```bash
git clone https://github.com/votre-username/good-wave-app.git
```

2. Ouvrez le fichier `good-wave.xcodeproj` dans Xcode

3. Configurez vos clés API :
   - Copiez `Config.xcconfig.example` vers `Config.xcconfig`
   - Remplissez vos clés API :
     - `API_KEY` : Clé API pour le backend Laravel
     - `WEATHER_API_KEY` : Clé API pour WeatherAPI (https://www.weatherapi.com/)

4. Assurez-vous que le backend Laravel est en cours d'exécution sur `http://127.0.0.1:8000`

5. Compilez et exécutez l'application

## Architecture

L'application suit une architecture MVVM (Model-View-ViewModel) :

- **Models/** : Structures de données et modèles
- **Views/** : Interface utilisateur SwiftUI
- **ViewModels/** : Logique métier et gestion d'état
- **App/** : Configuration de l'application

## Structure du Projet

```
good-wave-app/
├── Models/              # Modèles de données (SurfSpot, PaginatedResponse)
├── views/               # Vues SwiftUI
│   ├── components/      # Composants réutilisables
│   ├── ContentView.swift    # Vue de détail d'un spot
│   ├── ListView.swift       # Vue principale avec liste des spots
│   ├── WorldMapView.swift   # Carte mondiale interactive
│   ├── SavedView.swift      # Vue des favoris
│   └── ProfileView.swift   # Vue de profil
├── viewModels/          # ViewModels (SurfSpotViewModel)
├── app/                 # Configuration de l'app
│   └── Services/        # Services API (SurfSpotAPIService, SurfSpotSaveService)
├── assets/              # Ressources graphiques
├── Config.xcconfig      # Configuration API (non versionné)
├── Config.xcconfig.example  # Template de configuration
└── Tests/               # Tests unitaires et UI
```

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## Configuration API

L'application nécessite deux clés API :

1. **API_KEY** : Clé d'authentification pour le backend Laravel
2. **WEATHER_API_KEY** : Clé pour l'API WeatherAPI (météo en temps réel)

Ces clés doivent être configurées dans `Config.xcconfig` (voir `Config.xcconfig.example` pour le format).

⚠️ **Important** : Le fichier `Config.xcconfig` est dans `.gitignore` et ne sera pas commité sur GitHub.

## Backend

L'application se connecte à un backend Laravel qui doit être en cours d'exécution sur `http://127.0.0.1:8000`.

Les endpoints utilisés :
- `GET /spots` : Liste paginée des spots de surf
- `GET /spots/{id}` : Détails d'un spot
- `GET /favorites` : Liste des favoris de l'utilisateur
- `POST /favorites` : Ajouter/retirer un favori

## Développeurs

- Théo Butz

