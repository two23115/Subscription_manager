//
//  SubscriptionManagerTests.swift
//  SubscriptionManagerTests
//
//  Created by Rennji Matsuda on 2026/05/20.
//

import Foundation
import Testing
@testable import SubscriptionManager

struct SubscriptionManagerTests {

    @Test func customBillingCycleCalculatesEquivalentAmounts() {
        let subscription = Subscription(
            price: 3000,
            billingCycle: .custom(months: 3)
        )

        #expect(subscription.monthlyAmount == 1000)
        #expect(subscription.yearlyAmount == 12000)
        #expect(subscription.billingCycle.label == "3ヶ月ごと")
        #expect(subscription.billingCycle.shortLabel == "3ヶ月")
    }

    @Test func billingCycleDecodesExistingStoredValues() throws {
        let decoder = JSONDecoder()

        let monthly = try decoder.decode(BillingCycle.self, from: Data(#""monthly""#.utf8))
        let yearly = try decoder.decode(BillingCycle.self, from: Data(#""yearly""#.utf8))

        #expect(monthly == .monthly)
        #expect(yearly == .yearly)
    }

    @Test func customBillingCycleRoundTripsThroughCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let cycle = BillingCycle.custom(months: 3)

        let data = try encoder.encode(cycle)
        let decodedCycle = try decoder.decode(BillingCycle.self, from: data)

        #expect(String(data: data, encoding: .utf8) == #""custom:3""#)
        #expect(decodedCycle == cycle)
    }
}
