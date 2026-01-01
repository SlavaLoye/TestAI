//
//  TransportView.swift
//  TEst Ai
//
//  Created by Viacheslav Loie on 7.12.2025.
//

import SwiftUI
import MapKit

struct TransportView: View {
    @StateObject private var vm = TransportViewModel()
    @State private var isShowingSuggestions: Bool = false
    @State private var hideOverlay: Bool = false
    @State private var firstAppearTimestamp: Date? = nil
    @State private var firstReadyTimestamp: Date? = nil

    @State private var regionDebounceWorkItem: DispatchWorkItem? = nil
    @State private var useLightweightBackgrounds: Bool = false // Toggle to compare performance

    private var regionBinding: Binding<MKCoordinateRegion> { $vm.region }
    private var startCoordinate: CLLocationCoordinate2D? { vm.userCoordinate }
    private var endCoordinate: CLLocationCoordinate2D? { vm.destination }
    private var transportType: MKDirectionsTransportType { vm.selectedMode.mkType }

    var body: some View {
        ZStack {
            mapView
                .ignoresSafeArea()
                .task {
                    if firstReadyTimestamp == nil {
                        firstReadyTimestamp = Date()
                        if let start = firstAppearTimestamp, let ready = firstReadyTimestamp {
                            #if DEBUG
                            let dt = ready.timeIntervalSince(start)
                            print("[TransportView] First ready task at: \(ready), time since appear: \(String(format: "%.3f", dt))s")
                            #endif
                        }
                    }
                }

            if !hideOverlay {
                VStack(spacing: 8) {
                    // Панель поиска
                    HStack(spacing: 8) {
                        TextField("Поиск адреса или места", text: $vm.query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(10)
                            .background(
                                useLightweightBackgrounds
                                ? AnyShapeStyle(Color(.systemBackground).opacity(0.7))
                                : AnyShapeStyle(.ultraThinMaterial),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )

                        Button {
                            #if DEBUG
                            let ts = Date()
                            print("[TransportView] Search tapped at: \(ts) query='\(vm.query)' isSearching=\(vm.isSearching)")
                            #endif
                            vm.performSearch()
                            #if DEBUG
                            print("[TransportView] Search requested -> vm.performSearch()")
                            #endif
                        } label: {
                            if vm.isSearching {
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
                        .disabled(vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSearching)

                        if vm.isSearching || !vm.results.isEmpty || !vm.query.isEmpty {
                            Button("Отмена") {
                                #if DEBUG
                                let ts = Date()
                                print("[TransportView] Cancel tapped at: \(ts)")
                                #endif
                                vm.cancelSearch()
                                #if DEBUG
                                print("[TransportView] Search cancelled -> vm.cancelSearch()")
                                #endif
                                hideOverlay = false
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Переключатель типа транспорта
                    Picker("Тип", selection: $vm.selectedMode) {
                        Text(TransportMode.transit.title).tag(TransportMode.transit)
                        Text(TransportMode.automobile.title).tag(TransportMode.automobile)
                        Text(TransportMode.walking.title).tag(TransportMode.walking)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Список результатов поиска
                    if !vm.results.isEmpty {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(vm.results, id: \.self) { item in
                                    ResultRow(item: item) {
                                        #if DEBUG
                                        let ts = Date()
                                        let coord = item.placemark.coordinate
                                        print("[TransportView] Route requested at: \(ts) for: \(item.name ?? "Unnamed") coord=\(coord.latitude),\(coord.longitude)")
                                        #endif
                                        vm.destination = coord
                                        #if DEBUG
                                        print("[TransportView] Route build initiated -> destination set")
                                        #endif
                                        vm.results.removeAll()
                                        isShowingSuggestions = false
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        .background(
                            useLightweightBackgrounds
                            ? AnyShapeStyle(Color(.systemBackground).opacity(0.7))
                            : AnyShapeStyle(.ultraThinMaterial)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Кнопки управления масштабом и центровкой
                    HStack(spacing: 12) {
                        Button {
                            #if DEBUG
                            let ts = Date()
                            print("[TransportView] Center on user tapped at: \(ts) currentCenter=\(vm.region.center.latitude),\(vm.region.center.longitude)")
                            #endif
                            vm.centerOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .padding(10)
                                .background(
                                    useLightweightBackgrounds
                                    ? AnyShapeStyle(Color(.systemBackground).opacity(0.7))
                                    : AnyShapeStyle(.ultraThinMaterial),
                                    in: Circle()
                                )
                        }
                        .accessibilityLabel("Моё местоположение")

                        Button {
                            #if DEBUG
                            let ts = Date()
                            print("[TransportView] Zoom in tapped at: \(ts) currentSpan=\(vm.region.span.latitudeDelta),\(vm.region.span.longitudeDelta)")
                            #endif
                            vm.zoom(by: 0.5)
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.title2)
                                .padding(10)
                                .background(
                                    useLightweightBackgrounds
                                    ? AnyShapeStyle(Color(.systemBackground).opacity(0.7))
                                    : AnyShapeStyle(.ultraThinMaterial),
                                    in: Circle()
                                )
                        }

                        Button {
                            #if DEBUG
                            let ts = Date()
                            print("[TransportView] Zoom out tapped at: \(ts) currentSpan=\(vm.region.span.latitudeDelta),\(vm.region.span.longitudeDelta)")
                            #endif
                            vm.zoom(by: 2.0)
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.title2)
                                .padding(10)
                                .background(
                                    useLightweightBackgrounds
                                    ? AnyShapeStyle(Color(.systemBackground).opacity(0.7))
                                    : AnyShapeStyle(.ultraThinMaterial),
                                    in: Circle()
                                )
                        }
                    }
                    Group {
                        #if DEBUG
                        Toggle("Лёгкие фоны", isOn: $useLightweightBackgrounds)
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        #else
                        EmptyView()
                        #endif
                    }
                    .padding(.bottom, 20)
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .onAppear {
            let now = Date()
            self.firstAppearTimestamp = now
            #if DEBUG
            #if os(iOS)
            let device = UIDevice.current
            print("[TransportView] onAppear at: \(now) device=\(device.model) name=\(device.name) system=\(device.systemName) \(device.systemVersion)")
            #else
            print("[TransportView] onAppear at: \(now)")
            #endif
            #endif
            vm.start()
            hideOverlay = false
        }
        .onDisappear {
            #if DEBUG
            let ts = Date()
            print("[TransportView] onDisappear at: \(ts)")
            #endif
            vm.stop()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProfileView()
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .accessibilityLabel("Профиль")
            }
        }
        .onChange(of: String(format: "%.6f,%.6f,%.6f,%.6f", vm.region.center.latitude, vm.region.center.longitude, vm.region.span.latitudeDelta, vm.region.span.longitudeDelta)) { _ in
            // Debounce region change events to avoid excessive work while panning/zooming
            regionDebounceWorkItem?.cancel()
            let work = DispatchWorkItem { [vm] in
                let ts = Date()
                let center = vm.region.center
                let span = vm.region.span
                #if DEBUG
                print("[TransportView] Region changed at: \(ts) center=\(center.latitude),\(center.longitude) span=\(span.latitudeDelta),\(span.longitudeDelta)")
                #endif
            }
            regionDebounceWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        }
        .onChange(of: vm.destination?.latitude) { newLat in
            #if DEBUG
            let ts = Date()
            if let lat = newLat, let lon = vm.destination?.longitude {
                print("[TransportView] Destination changed at: \(ts) to: lat=\(lat), lon=\(lon)")
            } else {
                print("[TransportView] Destination changed at: \(ts) to: nil")
            }
            #endif
        }
        .onChange(of: vm.destination?.longitude) { newLon in
            #if DEBUG
            let ts = Date()
            if let lon = newLon, let lat = vm.destination?.latitude {
                print("[TransportView] Destination changed at: \(ts) to: lat=\(lat), lon=\(lon)")
            } else {
                print("[TransportView] Destination changed at: \(ts) to: nil")
            }
            #endif
        }
        .onChange(of: vm.selectedMode) { new in
            #if DEBUG
            let ts = Date()
            print("[TransportView] Transport mode changed at: \(ts) to: \(new)")
            #endif
        }
    }

    private var mapView: some View {
        TrafficMapView(
            region: regionBinding,
            showsUserLocation: true,
            startCoordinate: startCoordinate,
            endCoordinate: endCoordinate,
            transportType: transportType,
            isShowingSuggestions: $isShowingSuggestions
        )
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

#Preview {
    NavigationStack { TransportView() }
}

