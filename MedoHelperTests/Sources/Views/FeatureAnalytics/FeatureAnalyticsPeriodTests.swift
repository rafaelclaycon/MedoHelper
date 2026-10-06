//
//  FeatureAnalyticsPeriodTests.swift
//  MedoHelperTests
//
//  Created by Claude on 06/10/26.
//

import XCTest
@testable import MedoHelper

final class FeatureAnalyticsPeriodTests: XCTestCase {

    private typealias Period = FeatureAnalyticsView.Period

    private let iso = ISO8601DateFormatter()

    func testFirstRoundCoversTheCountFrom17hTo3hBrasilia() throws {
        let window = try XCTUnwrap(Period.firstRound.seriesWindow())
        XCTAssertEqual(window.since, iso.date(from: "2026-10-04T20:00:00Z"))
        XCTAssertEqual(window.until, iso.date(from: "2026-10-05T06:00:00Z"))
        XCTAssertEqual(Period.firstRound.startDate(), window.since)
    }

    func testSecondRoundCoversTheCountFrom17hTo3hBrasilia() throws {
        let window = try XCTUnwrap(Period.secondRound.seriesWindow())
        XCTAssertEqual(window.since, iso.date(from: "2026-10-25T20:00:00Z"))
        XCTAssertEqual(window.until, iso.date(from: "2026-10-26T06:00:00Z"))
        XCTAssertEqual(Period.secondRound.startDate(), window.since)
    }

    func testRollingPeriodsEndNowAndFitTheSeriesLimit() throws {
        let now = try XCTUnwrap(iso.date(from: "2026-10-06T15:00:00Z"))
        for period in [Period.today, .last24Hours] {
            let window = try XCTUnwrap(period.seriesWindow(now: now))
            XCTAssertEqual(window.until, now)
            XCTAssertLessThanOrEqual(window.until.timeIntervalSince(window.since), 48 * 60 * 60)
        }
        // "Hoje" starts at midnight in Brasília: 03:00 UTC.
        XCTAssertEqual(Period.today.seriesWindow(now: now)?.since, iso.date(from: "2026-10-06T03:00:00Z"))
    }

    func testSevenDaysKeepsTheHourlyCharts() {
        XCTAssertNil(Period.last7Days.seriesWindow())
    }

    func testBucketDatesParseWithAndWithoutFractionalSeconds() {
        func bucket(_ start: String) -> ElectionLiveSeriesBucket {
            ElectionLiveSeriesBucket(start: start, startBrasilia: "", starters: 0, newStarters: 0, cumulativeStarters: 0, stoppers: 0, watchingEstimate: 0)
        }
        XCTAssertEqual(bucket("2026-10-04T20:10:00.000Z").date, iso.date(from: "2026-10-04T20:10:00Z"))
        XCTAssertEqual(bucket("2026-10-04T20:10:00Z").date, iso.date(from: "2026-10-04T20:10:00Z"))
        XCTAssertNil(bucket("ontem").date)
    }
}
