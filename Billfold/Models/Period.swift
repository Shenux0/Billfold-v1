// Period.swift
// The time ranges the Insights screen can show. Each period knows which
// calendar unit it covers and how its bar chart should group the bars.

import Foundation

enum Period: String, CaseIterable, Identifiable {
    case week, month, year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    /// The calendar unit that defines the period, used to find its start and end.
    var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }

    /// One bar per day for a week or month, one bar per month for a year.
    var chartUnit: Calendar.Component {
        switch self {
        case .week, .month: return .day
        case .year: return .month
        }
    }
}
