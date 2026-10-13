// HomeViewModel.swift
import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    @Published var currentTime: Date = Date()
    @Published var expandedAttractionID: UUID? = nil
    @Published var expandedGroupID: UUID? = nil

    private var timer: AnyCancellable?

    init() {
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] t in self?.currentTime = t }
    }

    var isMuseumOpen: Bool { MuseumSchedule.isOpen(at: currentTime) }
    var minutesUntilNextShow: Int { MuseumSchedule.minutesUntilNextShow(from: currentTime) }

    var greetingKey: String {
        let h = Calendar.current.component(.hour, from: currentTime)
        if h < 12 { return L.greetingMorning }
        else if h < 19 { return L.greetingAfternoon }
        else { return L.greetingEvening }
    }

    func toggleGroup(_ id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            expandedGroupID = (expandedGroupID == id) ? nil : id
            expandedAttractionID = nil
        }
    }

    func toggleExpanded(_ id: UUID) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            expandedAttractionID = (expandedAttractionID == id) ? nil : id
        }
    }

    func isShowSoon(attraction: Attraction) -> Bool {
        !attraction.availableAllDay && minutesUntilNextShow <= 15
    }
}
