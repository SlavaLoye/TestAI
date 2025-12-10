//
//  TransportView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI
import CoreLocation
import MapKit

private enum TransportMode: Hashable, CaseIterable {
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

struct TransportView: View {
    // Начальный регион — Санкт‑Петербург
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.9343, longitude: 30.3351),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    // Локация пользователя
    @State private var userCoordinate: CLLocationCoordinate2D?
    @State private var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    private let locationProvider = LocationProvider()

    // Поиск
    @State private var query: String = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching: Bool = false
    @State private var activeSearch: MKLocalSearch?

    // Цель маршрута
    @State private var destination: CLLocationCoordinate2D?

    // Тип транспорта (обёртка для Picker)
    @State private var selectedMode: TransportMode = .transit

    var body: some View {
        ZStack {
            TrafficMapView(
                region: $region,
                showsUserLocation: true,
                startCoordinate: userCoordinate,
                endCoordinate: destination,
                transportType: selectedMode.mkType
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                // Панель поиска
                HStack(spacing: 8) {
                    TextField("Поиск адреса или места", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button {
                        performSearch()
                    } label: {
                        if isSearching {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(width: 20, height: 20)
                                .padding(10)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            Text("Найти")
                                .font(.callout.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)

                    // Кнопка отмены поиска (сбрасывает результаты и очищает поле)
                    if isSearching || !results.isEmpty || !query.isEmpty {
                        Button("Отмена") {
                            cancelSearch()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Переключатель типа транспорта
                Picker("Тип", selection: $selectedMode) {
                    Text(TransportMode.transit.title).tag(TransportMode.transit)
                    Text(TransportMode.automobile.title).tag(TransportMode.automobile)
                    Text(TransportMode.walking.title).tag(TransportMode.walking)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Список результатов поиска
                if !results.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(results, id: \.self) { item in
                                ResultRow(item: item) {
                                    // Маршрут от текущей локации до выбранного места
                                    destination = item.placemark.coordinate
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal)
                }

                Spacer()

                // Кнопки управления масштабом и центровкой
                HStack(spacing: 12) {
                    Button {
                        centerOnUser()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Моё местоположение")

                    Button {
                        zoom(by: 0.5)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title2)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Button {
                        zoom(by: 2.0)
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.title2)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.bottom, 20)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            locationProvider.start { status, coordinate in
                if let status = status {
                    locationAuthStatus = status
                }
                if let coordinate = coordinate {
                    userCoordinate = coordinate
                }
            }
        }
        .onDisappear {
            locationProvider.stop()
            activeSearch?.cancel()
            activeSearch = nil
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Search

    private func performSearch() {
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
        search.start { response, error in
            defer {
                isSearching = false
                activeSearch = nil
            }
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            results = response?.mapItems ?? []
        }
    }

    private func cancelSearch() {
        activeSearch?.cancel()
        activeSearch = nil
        isSearching = false
        results = []
        query = ""
        // destination НЕ трогаем по вашему запросу
    }

    // MARK: - Map controls

    private func zoom(by factor: Double) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(region.span.latitudeDelta * factor, 0.0005),
            longitudeDelta: max(region.span.longitudeDelta * factor, 0.0005)
        )
        region.span = newSpan
    }

    private func centerOnUser() {
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
        locationProvider.requestOneShot { coord in
            guard let coord = coord else { return }
            userCoordinate = coord
            withAnimation {
                region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
        }
    }
}

// MARK: - Вспомогательные представления

private struct ResultRow: View {
    let item: MKMapItem
    let onRouteFromMe: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(.red)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Место")
                    .font(.headline)
                if let subtitle = item.placemark.title {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button(action: onRouteFromMe) {
                Text("Маршрут от меня")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// Вспомогательный провайдер локации для получения координат в SwiftUI
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

#Preview {
    NavigationStack { TransportView() }
}
