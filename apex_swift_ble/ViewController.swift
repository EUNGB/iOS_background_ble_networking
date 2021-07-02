//
//  ViewController.swift
//  apex_swift_ble
//
//  Created by Weeds on 2021/07/01.
//

import CoreBluetooth
import CoreLocation
import UIKit
import UserNotifications

import Alamofire

class ViewController: UIViewController {
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    var locationManager: CLLocationManager!
    var manager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    let MINI_BEACON_UUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
    let BEACON_SERVICE_UUID = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    let DEVICE_CHARACTERISTIC_UUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    var bles: [CBPeripheral] = []
    var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager.init()                  // locationManger 초기화
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()                // 위치 권한 받기
        
        locationManager.startUpdatingLocation()                     // 위치 업데이트 시작
        locationManager.allowsBackgroundLocationUpdates = true      // 백그라운드에서 위치 체크
        locationManager.pausesLocationUpdatesAutomatically = false  // 백그라운드에서 멈춤 x
        
        notificationCenter.delegate = self
        requestNotificationAuthorization()
    }
    
    // 알림 권한 요청
    func requestNotificationAuthorization() {
        let authOptions = UNAuthorizationOptions(arrayLiteral: .alert, .badge, .sound)
        
        notificationCenter.requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    // 알림 SEND
    func sendNotification(seconds: Double) {
        let notificationContent = UNMutableNotificationContent()
        
        notificationContent.title = "알림 테스트"
        notificationContent.body = "이것은 알림을 테스트 하는 것이다"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification",
                                            content: notificationContent,
                                            trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
    }
    
    func postNetwork(name: String) {
        let url = "https://ptsv2.com/t/sbgrr-1625107360/post"
        var request = URLRequest(url: URL(string: url)!)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let param = ["name": name, "time": ""] as Dictionary
        
        do {
            try request.httpBody = JSONSerialization.data(withJSONObject: param, options: [])
        } catch {
            print("error")
        }
        
        AF.request(request).responseString { (response) in
            switch response.result {
            case .success:
                print("POST 성공")
                self.startMonitoring()
            case .failure(let error):
                print("🚫 Alamofire Request Error\nCode:\(error._code), Message: \(error.errorDescription!)")
            }
        }
        
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
            // 디바이스가 이미 영역 안에 있거나 앱이 실행되고 있지 않은 상황에서도
            // 영역 내부 안에 들어오면 백그라운드에서 앱을 실행시켜
            // 헤당 노티피케이션을 받을 수 있게 함
            if let uuid = UUID(uuidString:  "cf2409fe-81e4-4e00-5aee-eeff00000000") {
                let beaconRegion = CLBeaconRegion(uuid: uuid, identifier: "ibeacon")
                
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
        
        if state == .inside {
            startMonitoring()
        } else if state == .outside {
            stopMonitoring()
        } else if state == .unknown {
            
        }
    }
    
    func startMonitoring() {
        let uuid = UUID(uuidString:  "cf2409fe-81e4-4e00-5aee-eeff00000000")!
        let constraint = CLBeaconIdentityConstraint(uuid: uuid)
        locationManager.startRangingBeacons(satisfying: constraint)
    }
    
    func stopMonitoring() {
        let uuid = UUID(uuidString:  "cf2409fe-81e4-4e00-5aee-eeff00000000")!
        let constraint = CLBeaconIdentityConstraint(uuid: uuid)
        locationManager.stopRangingBeacons(satisfying: constraint)
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if beacons.count > 0 {
            let nearestBeacon = beacons.first!
            print("비콘 안에 있음2 \(nearestBeacon.uuid)")
            // BLE
            sendNotification(seconds: 1)
            self.manager = CBCentralManager(delegate: self, queue: nil, options: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification(seconds: 1)
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
            let options = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            self.manager.scanForPeripherals(withServices: [MINI_BEACON_UUID], options: options)
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
                index = i
                manager.connect(bles[i], options: nil)
                bles[i].delegate = self
                stopBleScan()
                stopMonitoring() // 연결되면 모니터링 종료
            }
        }
        print(bles)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        
        // 네트워킹
        let name = peripheral.name
        postNetwork(name: name!)
        manager.cancelPeripheralConnection(peripheral)
        self.manager = nil
        bles = []
    }
    
}


extension ViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}
