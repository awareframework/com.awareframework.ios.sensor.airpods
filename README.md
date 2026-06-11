# AWARE: AirPods Motion

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

This sensor module collects motion data from AirPods Pro and AirPods Max via `CMHeadphoneMotionManager` (Core Motion). It captures attitude (Euler angles, quaternion, rotation matrix), rotation rate, gravity, user acceleration, and sensor location (left/right earbud).

> The update rate is controlled by the AirPods firmware and cannot be configured programmatically. Data is delivered at the hardware's native rate (approximately 100 Hz).

[Apple | CMHeadphoneMotionManager](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager)  
[Apple | CMDeviceMotion](https://developer.apple.com/documentation/coremotion/cmdevicemotion)

## Requirements

- iOS 14 or later
- AirPods Pro or AirPods Max
- `NSMotionUsageDescription` key in Info.plist

## Installation

1. Open Package Manager Windows
    * Open `Xcode` → Select `Menu Bar` → `File` → `Add Package Dependencies...`

2. Find the package using the manager
    * Select `Search Package URL` and type `https://github.com/awareframework/com.awareframework.ios.sensor.airpods.git`

3. Import the package into your target.

## Public Functions

### AirPodsMotionSensor

+ `init(config: AirPodsMotionSensor.Config)` : Initializes the sensor with the given configuration.
+ `start()` : Starts motion data collection.
+ `stop()` : Stops motion data collection.
+ `sync(force: Bool)` : Syncs stored data to the configured host.
+ `set(label: String)` : Updates the data label at runtime.

### AirPodsMotionSensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: AirPodsMotionObserver?` : Callback for live data updates. (default = `nil`)
+ `period: Double` : Interval in minutes at which buffered data is saved to the database. (default = `1`)
+ `debug: Bool` : Enable/disable logging to the Xcode console. (default = `false`)
+ `label: String` : Customizable label attached to every data record. (default = `""`)
+ `deviceId: String` : Device UUID associated with the data. (default = system UUID)
+ `dbType: Engine` : Database engine to use. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String` : Path of the database. (default = `"aware_airpods"`)
+ `dbHost: String?` : Host URL for database sync. (default = `nil`)

### AirPodsMotionObserver

```swift
public protocol AirPodsMotionObserver {
    func onDataChanged(data: AirPodsMotionData)
    func onConnected()
    func onDisconnected()
}
```

## Broadcasts

### Fired Broadcasts

+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION` : Fired when motion data is saved to the database after the period ends.
+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_START` : Fired when the sensor starts.
+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_STOP` : Fired when the sensor stops.
+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_CONNECTED` : Fired when AirPods connect.
+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_DISCONNECTED` : Fired when AirPods disconnect.

### Received Broadcasts

+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_START` : Start the sensor.
+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_STOP` : Stop the sensor.
+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_SYNC` : Trigger a database sync.
+ `AirPodsMotionSensor.ACTION_AWARE_AIRPODS_MOTION_SET_LABEL` : Set the data label. Provide the value in `AirPodsMotionSensor.EXTRA_LABEL`.

## Data Representations

### AirPodsMotionData

Contains one sample of AirPods motion data. Table name: `airpods_motion`.

#### Attitude (Euler angles)

| Field | Type   | Description                        |
|-------|--------|------------------------------------|
| roll  | Double | Roll angle in radians              |
| pitch | Double | Pitch angle in radians             |
| yaw   | Double | Yaw angle in radians               |

#### Attitude (Quaternion)

| Field      | Type   | Description            |
|------------|--------|------------------------|
| quaternionX | Double | Quaternion x component |
| quaternionY | Double | Quaternion y component |
| quaternionZ | Double | Quaternion z component |
| quaternionW | Double | Quaternion w component |

#### Attitude (Rotation Matrix, row-major)

| Field            | Type   | Description     |
|------------------|--------|-----------------|
| rotationMatrixM11 | Double | Matrix element (1,1) |
| rotationMatrixM12 | Double | Matrix element (1,2) |
| rotationMatrixM13 | Double | Matrix element (1,3) |
| rotationMatrixM21 | Double | Matrix element (2,1) |
| rotationMatrixM22 | Double | Matrix element (2,2) |
| rotationMatrixM23 | Double | Matrix element (2,3) |
| rotationMatrixM31 | Double | Matrix element (3,1) |
| rotationMatrixM32 | Double | Matrix element (3,2) |
| rotationMatrixM33 | Double | Matrix element (3,3) |

#### Rotation Rate

| Field     | Type   | Description                      |
|-----------|--------|----------------------------------|
| rotationX | Double | Rotation rate around x-axis (rad/s) |
| rotationY | Double | Rotation rate around y-axis (rad/s) |
| rotationZ | Double | Rotation rate around z-axis (rad/s) |

#### Gravity

| Field    | Type   | Description                        |
|----------|--------|------------------------------------|
| gravityX | Double | Gravity vector x component (G)     |
| gravityY | Double | Gravity vector y component (G)     |
| gravityZ | Double | Gravity vector z component (G)     |

#### User Acceleration

| Field     | Type   | Description                                     |
|-----------|--------|-------------------------------------------------|
| userAccX  | Double | User acceleration x component, gravity removed (G) |
| userAccY  | Double | User acceleration y component, gravity removed (G) |
| userAccZ  | Double | User acceleration z component, gravity removed (G) |

#### Metadata

| Field              | Type   | Description                                                      |
|--------------------|--------|------------------------------------------------------------------|
| headphonePlacement | Int    | Source earbud: `0`=default, `1`=left, `2`=right (`CMSensorLocation.rawValue`) |
| label              | String | Customizable label. Useful for data calibration or traceability  |
| deviceId           | String | AWARE device UUID                                                |
| timestamp          | Int64  | Unix time in milliseconds since 1970                             |
| timezone           | Int    | Raw timezone offset of the device                                |
| os                 | String | Operating system of the device (`"iOS"`)                         |
| jsonVersion        | Int    | JSON schema version                                              |

> `headphonePlacement` is derived from `CMDeviceMotion.sensorLocation.rawValue` (iOS 14+):  
> `.default` → `0`, `.headphoneLeft` → `1`, `.headphoneRight` → `2`.

## Example Usage

```swift
import com_awareframework_ios_sensor_airpods

let sensor = AirPodsMotionSensor(AirPodsMotionSensor.Config().apply { config in
    config.debug = true
    config.period = 1.0
    config.sensorObserver = Observer()
})

sensor.start()
```

```swift
class Observer: AirPodsMotionObserver {
    func onDataChanged(data: AirPodsMotionData) {
        print("placement=\(data.headphonePlacement) roll=\(data.roll) pitch=\(data.pitch) yaw=\(data.yaw)")
    }

    func onConnected() {
        print("AirPods connected")
    }

    func onDisconnected() {
        print("AirPods disconnected")
    }
}
```

## Author

Yuuki Nishiyama (The University of Tokyo), nishiyama@csis.u-tokyo.ac.jp

## Related Links

- [Apple | CMHeadphoneMotionManager](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager)
- [Apple | CMDeviceMotion](https://developer.apple.com/documentation/coremotion/cmdevicemotion)
- [Apple | CMAttitude](https://developer.apple.com/documentation/coremotion/cmattitude)

## License

Copyright (c) 2026 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
