//
//  AirPodsMotionData.swift
//  com.awareframework.ios.sensor.airpods
//
//  Created by Yuuki Nishiyama on 2026/06/02.
//

import Foundation
import GRDB
import com_awareframework_ios_core

public struct AirPodsMotionData: BaseDbModelSQLite {
    public var id: Int64?
    public var timestamp: Int64 = 0
    public var deviceId: String = AwareUtils.getCommonDeviceId()
    public var label: String = ""
    public var timezone: Int = AwareUtils.getTimeZone()
    public var os: String = "iOS"
    public var jsonVersion: Int = 1

    public static let TABLE_NAME = "ios_airpods_motion"
    public static let databaseTableName = TABLE_NAME

    // Attitude (Euler angles in radians)
    public var roll: Double = 0.0
    public var pitch: Double = 0.0
    public var yaw: Double = 0.0

    // Rotation rate (rad/s)
    public var rotationX: Double = 0.0
    public var rotationY: Double = 0.0
    public var rotationZ: Double = 0.0

    // Gravity vector (g)
    public var gravityX: Double = 0.0
    public var gravityY: Double = 0.0
    public var gravityZ: Double = 0.0

    // User acceleration (g, gravity removed)
    public var userAccX: Double = 0.0
    public var userAccY: Double = 0.0
    public var userAccZ: Double = 0.0

    // Quaternion (from attitude.quaternion)
    public var quaternionX: Double = 0.0
    public var quaternionY: Double = 0.0
    public var quaternionZ: Double = 0.0
    public var quaternionW: Double = 0.0

    // Rotation matrix (from attitude.rotationMatrix, row-major)
    public var rotationMatrixM11: Double = 0.0
    public var rotationMatrixM12: Double = 0.0
    public var rotationMatrixM13: Double = 0.0
    public var rotationMatrixM21: Double = 0.0
    public var rotationMatrixM22: Double = 0.0
    public var rotationMatrixM23: Double = 0.0
    public var rotationMatrixM31: Double = 0.0
    public var rotationMatrixM32: Double = 0.0
    public var rotationMatrixM33: Double = 0.0

    // Headphone placement (CMSensorLocation.rawValue: 0=default, 1=left, 2=right)
    public var headphonePlacement: Int = 0

    public init() {}

    public init(
        timestamp: Int64,
        roll: Double, pitch: Double, yaw: Double,
        rotationX: Double, rotationY: Double, rotationZ: Double,
        gravityX: Double, gravityY: Double, gravityZ: Double,
        userAccX: Double, userAccY: Double, userAccZ: Double,
        quaternionX: Double = 0, quaternionY: Double = 0, quaternionZ: Double = 0,
        quaternionW: Double = 0,
        rotationMatrixM11: Double = 0, rotationMatrixM12: Double = 0, rotationMatrixM13: Double = 0,
        rotationMatrixM21: Double = 0, rotationMatrixM22: Double = 0, rotationMatrixM23: Double = 0,
        rotationMatrixM31: Double = 0, rotationMatrixM32: Double = 0, rotationMatrixM33: Double = 0,
        headphonePlacement: Int = 0,
        label: String = ""
    ) {
        self.timestamp = timestamp
        self.roll = roll
        self.pitch = pitch
        self.yaw = yaw
        self.rotationX = rotationX
        self.rotationY = rotationY
        self.rotationZ = rotationZ
        self.gravityX = gravityX
        self.gravityY = gravityY
        self.gravityZ = gravityZ
        self.userAccX = userAccX
        self.userAccY = userAccY
        self.userAccZ = userAccZ
        self.quaternionX = quaternionX
        self.quaternionY = quaternionY
        self.quaternionZ = quaternionZ
        self.quaternionW = quaternionW
        self.rotationMatrixM11 = rotationMatrixM11
        self.rotationMatrixM12 = rotationMatrixM12
        self.rotationMatrixM13 = rotationMatrixM13
        self.rotationMatrixM21 = rotationMatrixM21
        self.rotationMatrixM22 = rotationMatrixM22
        self.rotationMatrixM23 = rotationMatrixM23
        self.rotationMatrixM31 = rotationMatrixM31
        self.rotationMatrixM32 = rotationMatrixM32
        self.rotationMatrixM33 = rotationMatrixM33
        self.headphonePlacement = headphonePlacement
        self.label = label
    }

    public init(_ dict: [String: Any]) {
        self.timestamp = dict["timestamp"] as? Int64 ?? 0
        self.deviceId = dict["deviceId"] as? String ?? AwareUtils.getCommonDeviceId()
        self.label = dict["label"] as? String ?? ""
        self.roll = dict["roll"] as? Double ?? 0.0
        self.pitch = dict["pitch"] as? Double ?? 0.0
        self.yaw = dict["yaw"] as? Double ?? 0.0
        self.rotationX = dict["rotationX"] as? Double ?? 0.0
        self.rotationY = dict["rotationY"] as? Double ?? 0.0
        self.rotationZ = dict["rotationZ"] as? Double ?? 0.0
        self.gravityX = dict["gravityX"] as? Double ?? 0.0
        self.gravityY = dict["gravityY"] as? Double ?? 0.0
        self.gravityZ = dict["gravityZ"] as? Double ?? 0.0
        self.userAccX = dict["userAccX"] as? Double ?? 0.0
        self.userAccY = dict["userAccY"] as? Double ?? 0.0
        self.userAccZ = dict["userAccZ"] as? Double ?? 0.0
        self.quaternionX = dict["quaternionX"] as? Double ?? 0.0
        self.quaternionY = dict["quaternionY"] as? Double ?? 0.0
        self.quaternionZ = dict["quaternionZ"] as? Double ?? 0.0
        self.quaternionW = dict["quaternionW"] as? Double ?? 0.0
        self.rotationMatrixM11 = dict["rotationMatrixM11"] as? Double ?? 0.0
        self.rotationMatrixM12 = dict["rotationMatrixM12"] as? Double ?? 0.0
        self.rotationMatrixM13 = dict["rotationMatrixM13"] as? Double ?? 0.0
        self.rotationMatrixM21 = dict["rotationMatrixM21"] as? Double ?? 0.0
        self.rotationMatrixM22 = dict["rotationMatrixM22"] as? Double ?? 0.0
        self.rotationMatrixM23 = dict["rotationMatrixM23"] as? Double ?? 0.0
        self.rotationMatrixM31 = dict["rotationMatrixM31"] as? Double ?? 0.0
        self.rotationMatrixM32 = dict["rotationMatrixM32"] as? Double ?? 0.0
        self.rotationMatrixM33 = dict["rotationMatrixM33"] as? Double ?? 0.0
        self.headphonePlacement = dict["headphonePlacement"] as? Int ?? 0
    }

    public static func createTable(queue: DatabaseQueue) throws {
        try queue.write { db in
            try db.create(table: databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("deviceId", .text).notNull()
                t.column("timestamp", .integer).notNull()
                t.column("label", .text).notNull()
                t.column("timezone", .integer).notNull()
                t.column("os", .text).notNull()
                t.column("jsonVersion", .integer).notNull()
                t.column("roll", .double).notNull()
                t.column("pitch", .double).notNull()
                t.column("yaw", .double).notNull()
                t.column("rotationX", .double).notNull()
                t.column("rotationY", .double).notNull()
                t.column("rotationZ", .double).notNull()
                t.column("gravityX", .double).notNull()
                t.column("gravityY", .double).notNull()
                t.column("gravityZ", .double).notNull()
                t.column("userAccX", .double).notNull()
                t.column("userAccY", .double).notNull()
                t.column("userAccZ", .double).notNull()
                t.column("quaternionX", .double).notNull()
                t.column("quaternionY", .double).notNull()
                t.column("quaternionZ", .double).notNull()
                t.column("quaternionW", .double).notNull()
                t.column("rotationMatrixM11", .double).notNull()
                t.column("rotationMatrixM12", .double).notNull()
                t.column("rotationMatrixM13", .double).notNull()
                t.column("rotationMatrixM21", .double).notNull()
                t.column("rotationMatrixM22", .double).notNull()
                t.column("rotationMatrixM23", .double).notNull()
                t.column("rotationMatrixM31", .double).notNull()
                t.column("rotationMatrixM32", .double).notNull()
                t.column("rotationMatrixM33", .double).notNull()
                t.column("headphonePlacement", .integer).notNull()
            }
        }
    }

    public func toDictionary() -> [String: Any] {
        return [
            "id": id ?? -1,
            "timestamp": timestamp,
            "deviceId": deviceId,
            "label": label,
            "roll": roll,
            "pitch": pitch,
            "yaw": yaw,
            "rotationX": rotationX,
            "rotationY": rotationY,
            "rotationZ": rotationZ,
            "gravityX": gravityX,
            "gravityY": gravityY,
            "gravityZ": gravityZ,
            "userAccX": userAccX,
            "userAccY": userAccY,
            "userAccZ": userAccZ,
            "quaternionX": quaternionX,
            "quaternionY": quaternionY,
            "quaternionZ": quaternionZ,
            "quaternionW": quaternionW,
            "rotationMatrixM11": rotationMatrixM11,
            "rotationMatrixM12": rotationMatrixM12,
            "rotationMatrixM13": rotationMatrixM13,
            "rotationMatrixM21": rotationMatrixM21,
            "rotationMatrixM22": rotationMatrixM22,
            "rotationMatrixM23": rotationMatrixM23,
            "rotationMatrixM31": rotationMatrixM31,
            "rotationMatrixM32": rotationMatrixM32,
            "rotationMatrixM33": rotationMatrixM33,
            "headphonePlacement": headphonePlacement,
        ]
    }
}
