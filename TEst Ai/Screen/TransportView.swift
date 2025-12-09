//
//  TransportView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct TransportView: View {
    // Начальный регион — Санкт‑Петербург
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.9343, longitude: 30.3351),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    @State private var userCoordinate: CLLocationCoordinate2D?
    @State private var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    private let locationProvider = LocationProvider()

    var body: some View {
        ZStack {
            TrafficMapView(region: $region, showsUserLocation: true)
                .ignoresSafeArea()

            VStack {
                Spacer()
                HStack(spacing: 12) {
                    // Кнопка "Моё местоположение"
                    Button {
                        centerOnUser()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Моё местоположение")

                    // Кнопка приблизить
                    Button {
                        zoom(by: 0.5)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title2)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    // Кнопка отдалить
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
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func zoom(by factor: Double) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(region.span.latitudeDelta * factor, 0.0005),
            longitudeDelta: max(region.span.longitudeDelta * factor, 0.0005)
        )
        region.span = newSpan
    }

    private func centerOnUser() {
        // Если у нас уже есть координата пользователя — центрируемся
        if let coord = userCoordinate {
            withAnimation {
                region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
            return
        }

        // Иначе — запросим одноразово обновление и центрируемся при получении
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
        // Запрашиваем разрешение, если ещё не выдано
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            // Сразу передадим текущий статус
            onUpdate(CLLocationManager.authorizationStatus(), nil)
        }
        // Запрашиваем текущую локацию
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
        // Можно логировать ошибку при необходимости
        if let oneShot = oneShotCompletion {
            oneShot(nil)
            oneShotCompletion = nil
        }
    }
}

#Preview {
    NavigationStack { TransportView() }
}
