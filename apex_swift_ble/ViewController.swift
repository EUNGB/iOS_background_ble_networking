//
//  ViewController.swift
//  apex_swift_ble
//
//  Created by Weeds on 2021/07/01.
//

import CoreBluetooth
import CoreLocation
import UIKit

class ViewController: UIViewController {
    
    var locationManager: CLLocationManager!
    var manager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    let BEACON_SERVICE_UUID = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    let DEVICE_CHARACTERISTIC_UUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    var bles: [CBPeripheral] = []
        
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager.init()                  // locationManger 초기화
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()                // 위치 권한 받기
        
        locationManager.startUpdatingLocation()                     // 위치 업데이트 시작
        locationManager.allowsBackgroundLocationUpdates = true      // 백그라운드에서 위치 체크
        locationManager.pausesLocationUpdatesAutomatically = false  // 백그라운드에서 멈춤 x
    
       
        
    }
}

extension ViewController: CLLocationManagerDelegate {
    // 위치서비스 권한 확인 > monitorBeacons() 호출
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            monitorBeacons()
        }
    }
    
    func monitorBeacons() {
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            // 디바이스가 이미 영역 안에 있거나 앱이 실행되고 있지 않은 상황에서도 영역 내부 안에 들어오면 백그라운드에서 앱을 실행시켜
            // 헤당 노티피케이션을 받을 수 있게 함
            if let uuid = UUID(uuidString: "e2c56db5-dffb-48d2-b060-d0f5a71096e0") {
                
                let beaconRegion = CLBeaconRegion(
                    proximityUUID: uuid,
                    major: 40001,
                    minor: 40766,
                    identifier: "iBeacon")
                
                beaconRegion.notifyEntryStateOnDisplay = true
                beaconRegion.notifyOnExit = true
                beaconRegion.notifyOnEntry = true
                
                locationManager.startMonitoring(for: beaconRegion)
            }
        }else{
            print("CLLocation Monitoring is unavailable")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        let uuid = UUID(uuidString: "e2c56db5-dffb-48d2-b060-d0f5a71096e0")!
        let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 40001, minor: 40766)
        
        if state == .inside {
            locationManager.startRangingBeacons(satisfying: constraint)
        } else if state == .outside {
            locationManager.stopRangingBeacons(satisfying: constraint)
        } else if state == .unknown {
            
        }
    }
    
    func stopMonitoring() {
        let uuid = UUID(uuidString: "e2c56db5-dffb-48d2-b060-d0f5a71096e0")!
        let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 40001, minor: 40766)
        locationManager.stopRangingBeacons(satisfying: constraint)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if beacons.count > 0 {
            let nearestBeacon = beacons.first!
            print("비콘 안에 있음2 \(nearestBeacon.uuid)")
            // BLE
            self.manager = CBCentralManager(delegate: self, queue: nil, options: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // 비콘이 범위 내에 있는 경우
        print("비콘 안에 있음3")
    }
}


extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func stopBleScan() {
        
        let when = DispatchTime.now()
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.manager.stopScan()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("Bluetooth on")
            central.scanForPeripherals(withServices: nil, options: nil)
        } else {
            // 꺼진 경우 설정으로 이동할 수 있는 팝업창 등 구현 가능
            print("Bluetooth not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let name = peripheral.name ?? ""
        if name != "" {
            for i in 0 ..< bles.count {
                if bles[i].name == name {
                    return
                }
            }
            bles.append(peripheral)
        }
        
        for i in 0 ..< bles.count {
            if ( bles[i].name == "MiniBeacon_40766") {
                manager.connect(bles[i], options: nil)
                bles[i].delegate = self
                stopBleScan()
                stopMonitoring()
            }
        }
        print(bles)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        // 네트워킹
        
        
    }
    

    
}
