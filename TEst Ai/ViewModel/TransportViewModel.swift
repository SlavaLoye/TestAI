import Foundation
import MapKit
import CoreLocation
import Combine
import SwiftUI

enum TransportMode: Hashable, CaseIterable {
    case transit
    case automobile
    case walking

    var title: String {
        switch self {
        case .transit: return "Транспорт"
        case .automobile: return "Авто"
        case .walking: return "Пешком"
        }
    }

    var mkType: MKDirectionsTransportType {
        switch self {
        case .transit: return .transit
        case .automobile: return .automobile
        case .walking: return .walking
        }
    }
}

@MainActor
final class TransportViewModel: ObservableObject {
    // Начальный регион — Санкт‑Петербург
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.9343, longitude: 30.3351),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    // Локация пользователя
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined

    // Поиск
    @Published var query: String = ""
    @Published var results: [MKMapItem] = []
    @Published var isSearching: Bool = false
    private var activeSearch: MKLocalSearch?

    // Цель маршрута
    @Published var destination: CLLocationCoordinate2D?

    // Тип транспорта (обёртка для Picker)
    @Published var selectedMode: TransportMode = .transit

    // Провайдер локации
    private let locationProvider = LocationProvider()

    // MARK: - Lifecycle
    func start() {
        locationProvider.start { [weak self] status, coordinate in
            guard let self else { return }
            if let status = status {
                self.locationAuthStatus = status
            }
            if let coordinate = coordinate {
                self.userCoordinate = coordinate
            }
        }
    }

    func stop() {
        locationProvider.stop()
        activeSearch?.cancel()
        activeSearch = nil
    }

    // MARK: - Search
    func performSearch() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        isSearching = true
        results = []
        activeSearch?.cancel()

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q
        request.region = region // ограничим текущим регионом карты для релевантности

        let search = MKLocalSearch(request: request)
        activeSearch = search
        search.start { [weak self] response, error in
            guard let self else { return }
            defer {
                Task { @MainActor in
                    self.isSearching = false
                    self.activeSearch = nil
                }
            }
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            let items = response?.mapItems ?? []
            Task { @MainActor in
                self.results = items
            }
        }
    }

    func cancelSearch() {
        activeSearch?.cancel()
        activeSearch = nil
        isSearching = false
        results = []
        query = ""
        // destination НЕ сбрасываем — по текущим требованиям
    }

    // MARK: - Map controls
    func zoom(by factor: Double) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(region.span.latitudeDelta * factor, 0.0005),
            longitudeDelta: max(region.span.longitudeDelta * factor, 0.0005)
        )
        region.span = newSpan
    }

    func centerOnUser() {
        if let coord = userCoordinate {
            withAnimation {
                region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
            return
        }

        // Одноразовый запрос координаты, затем центрируемся
        locationProvider.requestOneShot { [weak self] coord in
            guard let self else { return }
            guard let coord = coord else { return }
            Task { @MainActor in
                self.userCoordinate = coord
                withAnimation {
                    self.region = MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                }
            }
        }
    }
}

// Вспомогательный провайдер локации для получения координат
private final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var onUpdate: ((CLAuthorizationStatus?, CLLocationCoordinate2D?) -> Void)?
    private var oneShotCompletion: ((CLLocationCoordinate2D?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start(onUpdate: @escaping (CLAuthorizationStatus?, CLLocationCoordinate2D?) -> Void) {
        self.onUpdate = onUpdate
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            onUpdate(CLLocationManager.authorizationStatus(), nil)
        }
        manager.requestLocation()
    }

    func requestOneShot(_ completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        oneShotCompletion = completion
        manager.requestLocation()
    }

    func stop() {
        onUpdate = nil
        oneShotCompletion = nil
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        onUpdate?(status, nil)
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coord = locations.last?.coordinate
        onUpdate?(nil, coord)
        if let oneShot = oneShotCompletion {
            oneShot(coord)
            oneShotCompletion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let oneShot = oneShotCompletion {
            oneShot(nil)
            oneShotCompletion = nil
        }
    }
}
