import Foundation

/// Scan-friendly modification-date strings for the file list (issue 17). Recent
/// files keep their time (when it actually helps); older files drop it to cut
/// column noise — "data drives the form" (`context/dashboard-research.md` §1).
///
/// Pure: callers can pass an explicit `now`/`calendar`, so it's unit-testable
/// without depending on the wall clock or the host time zone.
enum FileDateFormatter {
    private static let time: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short; return f
    }()
    private static let monthDay: DateFormatter = {
        let f = DateFormatter(); f.setLocalizedDateFormatFromTemplate("MMMd"); return f
    }()
    private static let monthDayYear: DateFormatter = {
        let f = DateFormatter(); f.setLocalizedDateFormatFromTemplate("MMMdyyyy"); return f
    }()

    static func string(for date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today \(time.string(from: date))"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday \(time.string(from: date))"
        }
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return monthDay.string(from: date)        // same year → drop the year
        }
        return monthDayYear.string(from: date)
    }
}
