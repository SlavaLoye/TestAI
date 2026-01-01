//
//  TrafficMapView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct TrafficMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var showsUserLocation: Bool = true

    // Новые параметры для маршрута
    var startCoordinate: CLLocationCoordinate2D?
    var endCoordinate: CLLocationCoordinate2D?
    var transportType: MKDirectionsTransportType = .transit // .automobile, .walking, .transit

    // Управление подсказками и клавиатурой
    @Binding var isShowingSuggestions: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)

        // Базовые настройки
        mapView.setRegion(region, animated: false)
        mapView.showsTraffic = true
        mapView.showsBuildings = true

        // Включаем только нужные POI
        var categories: [MKPointOfInterestCategory] = [
            .publicTransport,
            .airport,
            .evCharger,
            .parking,
            .restaurant
        ]
        mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)

        // Элементы управления
        mapView.showsCompass = true
        mapView.showsScale = true

        // Локация пользователя (потребует NSLocationWhenInUseUsageDescription в Info.plist)
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = showsUserLocation ? .follow : .none

        mapView.delegate = context.coordinator

        // Тап по пустой области карты — скрыть клавиатуру и подсказки
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap))
        tap.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tap)

        // Запросить авторизацию геолокации
        context.coordinator.requestLocationAuthorization()

        // Построить маршрут, если есть обе точки
        context.coordinator.rebuildRouteIfNeeded(on: mapView,
                                                 start: startCoordinate,
                                                 end: endCoordinate,
                                                 type: transportType)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Обновить регион, если изменился
        if uiView.region.center.latitude != region.center.latitude ||
            uiView.region.center.longitude != region.center.longitude ||
            uiView.region.span.latitudeDelta != region.span.latitudeDelta ||
            uiView.region.span.longitudeDelta != region.span.longitudeDelta {
            uiView.setRegion(region, animated: true)
        }

        uiView.showsUserLocation = showsUserLocation
        uiView.showsTraffic = true

        // Если изменились входные точки или тип транспорта — перестроить маршрут
        context.coordinator.rebuildRouteIfNeeded(on: uiView,
                                                 start: startCoordinate,
                                                 end: endCoordinate,
                                                 type: transportType)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, isShowingSuggestions: $isShowingSuggestions)
    }

    final class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        private let parent: TrafficMapView
        private let locationManager = CLLocationManager()
        private var isShowingSuggestions: Binding<Bool>

        init(parent: TrafficMapView, isShowingSuggestions: Binding<Bool>) {
            self.parent = parent
            self.isShowingSuggestions = isShowingSuggestions
            super.init()
            locationManager.delegate = self
        }

        func requestLocationAuthorization() {
            locationManager.requestWhenInUseAuthorization()
        }

        // MARK: - UI helpers
        @objc func handleMapTap() {
            // Скрыть клавиатуру
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            // Скрыть подсказки
            isShowingSuggestions.wrappedValue = false
        }

        // MARK: - Routing

        func rebuildRouteIfNeeded(on mapView: MKMapView,
                                  start: CLLocationCoordinate2D?,
                                  end: CLLocationCoordinate2D?,
                                  type: MKDirectionsTransportType) {
            // Проверим, есть ли обе точки
            guard let start, let end else {
                // Если точек нет — очистим оверлеи/аннотации маршрута
                clearRoute(on: mapView)
                lastStart = nil
                lastEnd = nil
                lastType = []
                return
            }

            // Если параметры не изменились — ничего не делаем
            if lastStart?.latitude == start.latitude &&
                lastStart?.longitude == start.longitude &&
                lastEnd?.latitude == end.latitude &&
                lastEnd?.longitude == end.longitude &&
                lastType == type {
                return
            }

            // Обновим кэш
            lastStart = start
            lastEnd = end
            lastType = type

            buildRoute(on: mapView, start: start, end: end, type: type)
        }

        private func buildRoute(on mapView: MKMapView,
                                start: CLLocationCoordinate2D,
                                end: CLLocationCoordinate2D,
                                type: MKDirectionsTransportType) {
            // Отменим предыдущий запрос
            activeDirections?.cancel()
            activeDirections = nil

            // Очистим прежний маршрут
            clearRoute(on: mapView)

            // Аннотации старта/финиша
            let startAnnotation = MKPointAnnotation()
            startAnnotation.title = "Старт"
            startAnnotation.coordinate = start

            let endAnnotation = MKPointAnnotation()
            endAnnotation.title = "Финиш"
            endAnnotation.coordinate = end

            mapView.addAnnotations([startAnnotation, endAnnotation])

            // Запрос Directions
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
            request.transportType = type
            request.requestsAlternateRoutes = true

            let directions = MKDirections(request: request)
            activeDirections = directions

            directions.calculate { [weak self, weak mapView] response, error in
                guard let self, let mapView else { return }
                if let error = error {
                    print("Directions error: \(error.localizedDescription)")
                    return
                }
                guard let route = response?.routes.first else {
                    print("Directions: no routes found")
                    return
                }

                // Добавим polyline
                mapView.addOverlay(route.polyline)

                // Подгоним видимую область под маршрут + аннотации
                let rect = route.polyline.boundingMapRect
                let edgeInsets = UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40)
                mapView.setVisibleMapRect(rect, edgePadding: edgeInsets, animated: true)
            }
        }

        private func clearRoute(on mapView: MKMapView) {
            let overlays = mapView.overlays
            if !overlays.isEmpty {
                mapView.removeOverlays(overlays)
            }
            // Удаляем только аннотации, которые мы добавляли (Старт/Финиш)
            let toRemove = mapView.annotations.filter {
                guard let title = $0.title ?? nil else { return false }
                return title == "Старт" || title == "Финиш"
            }
            if !toRemove.isEmpty {
                mapView.removeAnnotations(toRemove)
            }
        }

        // MARK: - CLLocationManagerDelegate

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
            print("Location error: \(error.localizedDescription)")
        }

        // MARK: - MKMapViewDelegate (renderer)

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                // Цвет/стили в зависимости от типа транспорта
                switch lastType {
                case .automobile:
                    renderer.strokeColor = UIColor.systemBlue
                case .walking:
                    renderer.strokeColor = UIColor.systemGreen
                case .transit:
                    renderer.strokeColor = UIColor.systemPurple
                default:
                    renderer.strokeColor = UIColor.systemTeal
                }
                renderer.lineWidth = 5
                renderer.lineJoin = .round
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // Кэш последних параметров, чтобы не перестраивать маршрут лишний раз
        private var lastStart: CLLocationCoordinate2D?
        private var lastEnd: CLLocationCoordinate2D?
        private var lastType: MKDirectionsTransportType = []

        // Храним активный MKDirections, чтобы отменять при повторных вызовах
        private var activeDirections: MKDirections?
    }
}
