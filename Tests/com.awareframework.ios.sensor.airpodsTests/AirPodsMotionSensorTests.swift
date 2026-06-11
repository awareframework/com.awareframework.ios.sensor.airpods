//
//  AirPodsMotionSensorTests.swift
//  com.awareframework.ios.sensor.airpods
//
//  Created by Yuuki Nishiyama on 2026/06/02.
//

import XCTest
@testable import com_awareframework_ios_sensor_airpods

final class AirPodsMotionSensorTests: XCTestCase {

    func testDataModelInit() {
        let data = AirPodsMotionData(
            timestamp: 1000,
            roll: 0.1, pitch: 0.2, yaw: 0.3,
            rotationX: 0.4, rotationY: 0.5, rotationZ: 0.6,
            gravityX: 0.0, gravityY: 0.0, gravityZ: -1.0,
            userAccX: 0.01, userAccY: 0.02, userAccZ: 0.03,
            label: "test"
        )
        XCTAssertEqual(data.timestamp, 1000)
        XCTAssertEqual(data.roll, 0.1)
        XCTAssertEqual(data.label, "test")
    }

    func testDataModelDictionaryRoundtrip() {
        let original = AirPodsMotionData(
            timestamp: 9999,
            roll: 1.0, pitch: 2.0, yaw: 3.0,
            rotationX: 4.0, rotationY: 5.0, rotationZ: 6.0,
            gravityX: 0.0, gravityY: -1.0, gravityZ: 0.0,
            userAccX: 0.1, userAccY: 0.2, userAccZ: 0.3
        )
        let dict = original.toDictionary()
        let restored = AirPodsMotionData(dict)
        XCTAssertEqual(original.timestamp, restored.timestamp)
        XCTAssertEqual(original.roll, restored.roll)
        XCTAssertEqual(original.userAccZ, restored.userAccZ)
    }
}
