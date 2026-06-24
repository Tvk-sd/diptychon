import XCTest
@testable import Diptychon

/// Issue 17: scan-friendly date strings. Pure logic against a fixed `now` and a
/// fixed calendar so the assertions don't depend on the wall clock or time zone.
final class FileDateFormatterTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    /// A fixed reference "now": 2026-06-24 12:00 UTC.
    private lazy var now: Date = calendar.date(from: DateComponents(
        year: 2026, month: 6, day: 24, hour: 12, minute: 0))!

    private func string(_ date: Date) -> String {
        FileDateFormatter.string(for: date, now: now, calendar: calendar)
    }

    func testTodayKeepsTime() {
        let earlierToday = calendar.date(byAdding: .hour, value: -3, to: now)!
        XCTAssertTrue(string(earlierToday).hasPrefix("Today "), "got: \(string(earlierToday))")
    }

    func testYesterdayKeepsTime() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        XCTAssertTrue(string(yesterday).hasPrefix("Yesterday "), "got: \(string(yesterday))")
    }

    func testSameYearDropsTimeAndYear() {
        let earlierThisYear = calendar.date(byAdding: .day, value: -30, to: now)! // late May 2026
        let s = string(earlierThisYear)
        XCTAssertFalse(s.contains("Today"))
        XCTAssertFalse(s.contains("Yesterday"))
        XCTAssertFalse(s.contains("2026"), "same-year dates drop the year; got: \(s)")
        XCTAssertFalse(s.contains(":"), "same-year dates drop the time; got: \(s)")
    }

    func testOlderYearShowsYear() {
        let lastYear = calendar.date(byAdding: .day, value: -400, to: now)! // 2025
        XCTAssertTrue(string(lastYear).contains("2025"), "got: \(string(lastYear))")
    }
}
