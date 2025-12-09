//
//  TrafficMapView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct TrafficMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var showsUserLocation: Bool = true

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)

        // Базовые настройки
        mapView.setRegion(region, animated: false)
        mapView.showsTraffic = true
        mapView.showsBuildings = true
        mapView.pointOfInterestFilter = .includingAll

        // Элементы управления
        mapView.showsCompass = true
        mapView.showsScale = true

        // Локация пользователя (потребует NSLocationWhenInUseUsageDescription в Info.plist)
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = showsUserLocation ? .follow : .none

        mapView.delegate = context.coordinator

        // Запросить авторизацию геолокации
        context.coordinator.requestLocationAuthorization()

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.region.center.latitude != region.center.latitude ||
            uiView.region.center.longitude != region.center.longitude ||
            uiView.region.span.latitudeDelta != region.span.latitudeDelta ||
            uiView.region.span.longitudeDelta != region.span.longitudeDelta {
            uiView.setRegion(region, animated: true)
        }
        uiView.showsUserLocation = showsUserLocation
        uiView.showsTraffic = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let parent: TrafficMapView
        private let locationManager = CLLocationManager()

        init(parent: TrafficMapView) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
        }

        func requestLocationAuthorization() {
            locationManager.requestWhenInUseAuthorization()
        }

        // Опционально можно обновлять регион по текущему местоположению
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }
            manager.requestLocation()
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let loc = locations.last else { return }
            let newRegion = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            DispatchQueue.main.async {
                self.parent.region = newRegion
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            // Можно обработать ошибку локации при необходимости
             print("Location error: \(error.localizedDescription)")
        }
    }
}
