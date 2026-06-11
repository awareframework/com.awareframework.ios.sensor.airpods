//
//  AirPodsMotionSensor.swift
//  com.awareframework.ios.sensor.airpods
//
//  Created by Yuuki Nishiyama on 2026/06/02.
//

import CoreMotion
import Foundation
import GRDB
import com_awareframework_ios_core

extension Notification.Name {
    public static let actionAwareAirPodsMotion = Notification.Name(
        AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION)
    public static let actionAwareAirPodsMotionStart = Notification.Name(
        AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_START)
    public static let actionAwareAirPodsMotionStop = Notification.Name(
        AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_STOP)
    public static let actionAwareAirPodsMotionSetLabel = Notification.Name(
        AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_SET_LABEL)
    public static let actionAwareAirPodsMotionSync = Notification.Name(
        AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_SYNC)
    public static let actionAwareAirPodsMotionSyncCompletion = Notification.Name(
        AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_SYNC_COMPLETION)
    public static let actionAwareAirPodsMotionConnected = Notification.Name(
        AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_CONNECTED)
    public static let actionAwareAirPodsMotionDisconnected = Notification.Name(
        AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_DISCONNECTED)
}

public protocol AirPodsMotionObserver {
    func onDataChanged(data: AirPodsMotionData)
    func onConnected()
    func onDisconnected()
}

extension AirPodsMotionSensor {
    public static let ACTION_AWARE_AIRPODS_MOTION = "com.awareframework.ios.sensor.airpods"
    public static let ACTION_AWARE_AIRPODS_MOTION_START =
        "com.awareframework.ios.sensor.airpods.ACTION_START"
    public static let ACTION_AWARE_AIRPODS_MOTION_STOP =
        "com.awareframework.ios.sensor.airpods.ACTION_STOP"
    public static let ACTION_AWARE_AIRPODS_MOTION_SET_LABEL =
        "com.awareframework.ios.sensor.airpods.ACTION_SET_LABEL"
    public static let ACTION_AWARE_AIRPODS_MOTION_SYNC =
        "com.awareframework.ios.sensor.airpods.ACTION_SYNC"
    public static let ACTION_AWARE_AIRPODS_MOTION_SYNC_COMPLETION =
        "com.awareframework.ios.sensor.airpods.ACTION_SYNC_COMPLETION"
    public static let ACTION_AWARE_AIRPODS_MOTION_CONNECTED =
        "com.awareframework.ios.sensor.airpods.ACTION_CONNECTED"
    public static let ACTION_AWARE_AIRPODS_MOTION_DISCONNECTED =
        "com.awareframework.ios.sensor.airpods.ACTION_DISCONNECTED"
    public static var EXTRA_LABEL = "label"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    public static let TAG = "com.awareframework.ios.sensor.airpods"
}

/// Collects motion data from AirPods Pro / AirPods Max via CMHeadphoneMotionManager.
/// Requires Info.plist key NSMotionUsageDescription.
public class AirPodsMotionSensor: AwareSensor {

    public var CONFIG = AirPodsMotionSensor.Config()

    private let headphoneMotion = CMHeadphoneMotionManager()
    private var dataBuffer: [AirPodsMotionData] = []
    private var LAST_SAVE: Double = 0.0

    private let motionQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.awareframework.ios.sensor.airpods.motion.queue"
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInitiated
        return q
    }()

    public class Config: SensorConfig {
        /// Requested UI/config value. CMHeadphoneMotionManager controls its own delivery interval.
        public var frequency: Int = 50
        /// Save-to-DB interval in minutes.
        public var period: Double = 1
        public var sensorObserver: AirPodsMotionObserver?

        public override init() {
            super.init()
            self.dbTableName = AirPodsMotionData.TABLE_NAME
            self.dbPath = "aware_airpods"
        }

        public override func set(config: [String: Any]) {
            super.set(config: config)
            if let frequency = config["frequency"] as? Int {
                self.frequency = frequency
            }
            if let period = config["period"] as? Double {
                self.period = period
            }
        }

        public func apply(closure: (_ config: AirPodsMotionSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }

    public init(_ config: AirPodsMotionSensor.Config) {
        super.init()
        self.CONFIG = config
        self.initializeDbEngine(config: config)
        self.initializeTable()

        super.syncConfig = DbSyncConfig().apply(closure: { cfg in
            cfg.serverType = self.CONFIG.serverType
            cfg.debug = self.CONFIG.debug
            cfg.batchSize = 1000
            cfg.dispatchQueue = DispatchQueue(
                label: "com.awareframework.ios.sensor.airpods.sync.queue")
            cfg.compactDataFormat = true
            cfg.completionHandler = { (status, error) in
                var userInfo: [String: Any] = [AirPodsMotionSensor.EXTRA_STATUS: status]
                if let e = error {
                    userInfo[AirPodsMotionSensor.EXTRA_ERROR] = e
                }
                self.notificationCenter.post(
                    name: .actionAwareAirPodsMotionSyncCompletion, object: self, userInfo: userInfo)
            }
        })

        headphoneMotion.delegate = self

        if CONFIG.debug { print(AirPodsMotionSensor.TAG, "AirPods Motion sensor created.") }
    }

    public override func start() {
        guard headphoneMotion.isDeviceMotionAvailable else {
            if CONFIG.debug {
                print(
                    AirPodsMotionSensor.TAG,
                    "CMHeadphoneMotionManager not available on this device.")
            }
            return
        }
        guard !headphoneMotion.isDeviceMotionActive else { return }

        headphoneMotion.startDeviceMotionUpdates(to: motionQueue) { [weak self] motionData, error in
            guard let self, let motionData else { return }

            let now = Date().timeIntervalSince1970
            let rm = motionData.attitude.rotationMatrix
            let q = motionData.attitude.quaternion
            let data = AirPodsMotionData(
                timestamp: Int64(now * 1000),
                roll: motionData.attitude.roll,
                pitch: motionData.attitude.pitch,
                yaw: motionData.attitude.yaw,
                rotationX: motionData.rotationRate.x,
                rotationY: motionData.rotationRate.y,
                rotationZ: motionData.rotationRate.z,
                gravityX: motionData.gravity.x,
                gravityY: motionData.gravity.y,
                gravityZ: motionData.gravity.z,
                userAccX: motionData.userAcceleration.x,
                userAccY: motionData.userAcceleration.y,
                userAccZ: motionData.userAcceleration.z,
                quaternionX: q.x, quaternionY: q.y, quaternionZ: q.z, quaternionW: q.w,
                rotationMatrixM11: rm.m11, rotationMatrixM12: rm.m12, rotationMatrixM13: rm.m13,
                rotationMatrixM21: rm.m21, rotationMatrixM22: rm.m22, rotationMatrixM23: rm.m23,
                rotationMatrixM31: rm.m31, rotationMatrixM32: rm.m32, rotationMatrixM33: rm.m33,
                headphonePlacement: motionData.sensorLocation.rawValue,
                label: self.CONFIG.label
            )

            if let observer = self.CONFIG.sensorObserver {
                DispatchQueue.main.async { observer.onDataChanged(data: data) }
            }

            self.dataBuffer.append(data)

            if now < self.LAST_SAVE + (self.CONFIG.period * 60) { return }

            let batch = Array(self.dataBuffer)
            self.dataBuffer.removeAll()
            self.LAST_SAVE = now

            OperationQueue().addOperation {
                self.dbEngine?.save(batch) { error in
                    if let error {
                        if self.CONFIG.debug { print(AirPodsMotionSensor.TAG, error) }
                        return
                    }
                    DispatchQueue.main.async {
                        self.notificationCenter.post(name: .actionAwareAirPodsMotion, object: self)
                    }
                }
            }
        }

        if CONFIG.debug {
            print(AirPodsMotionSensor.TAG, "AirPods Motion sensor active: \(CONFIG.frequency) Hz")
        }
        notificationCenter.post(name: .actionAwareAirPodsMotionStart, object: self)
    }

    public override func stop() {
        guard headphoneMotion.isDeviceMotionActive else { return }
        headphoneMotion.stopDeviceMotionUpdates()
        motionQueue.cancelAllOperations()
        if CONFIG.debug { print(AirPodsMotionSensor.TAG, "AirPods Motion sensor stopped.") }
        notificationCenter.post(name: .actionAwareAirPodsMotionStop, object: self)
    }

    public override func sync(force: Bool = false) {
        notificationCenter.post(name: .actionAwareAirPodsMotionSync, object: self)
        if let engine = dbEngine, let syncConfig = super.syncConfig {
            engine.startSync(syncConfig)
        }
    }

    public override func set(label: String) {
        self.CONFIG.label = label
        notificationCenter.post(
            name: .actionAwareAirPodsMotionSetLabel, object: self,
            userInfo: [AirPodsMotionSensor.EXTRA_LABEL: label])
    }

    private func initializeTable() {
        guard let sqliteEngine = dbEngine as? SQLiteEngine,
            let queue = sqliteEngine.getSQLiteInstance()
        else { return }
        do {
            try AirPodsMotionData.createTable(queue: queue)
        } catch {
            if CONFIG.debug { print(AirPodsMotionSensor.TAG, error) }
        }
    }
}

extension AirPodsMotionSensor: CMHeadphoneMotionManagerDelegate {
    public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        if CONFIG.debug { print(AirPodsMotionSensor.TAG, "AirPods connected.") }
        notificationCenter.post(name: .actionAwareAirPodsMotionConnected, object: self)
        CONFIG.sensorObserver?.onConnected()
    }

    public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        if CONFIG.debug { print(AirPodsMotionSensor.TAG, "AirPods disconnected.") }
        notificationCenter.post(name: .actionAwareAirPodsMotionDisconnected, object: self)
        CONFIG.sensorObserver?.onDisconnected()
    }
}
