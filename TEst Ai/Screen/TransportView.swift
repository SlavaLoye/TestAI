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

    var body: some View {
        ZStack {
            TrafficMapView(
                region: $vm.region,
                showsUserLocation: true,
                startCoordinate: vm.userCoordinate,
                endCoordinate: vm.destination,
                transportType: vm.selectedMode.mkType
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                // Панель поиска
                HStack(spacing: 8) {
                    TextField("Поиск адреса или места", text: $vm.query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button {
                        vm.performSearch()
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
                            vm.cancelSearch()
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
                                    vm.destination = item.placemark.coordinate
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
                        vm.centerOnUser()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Моё местоположение")

                    Button {
                        vm.zoom(by: 0.5)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title2)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Button {
                        vm.zoom(by: 2.0)
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
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .navigationBarTitleDisplayMode(.inline)
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
