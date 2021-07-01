# iOS_background_ble_networking
iOS 백그라운드에서 비콘 스캔 및 BLE Connect, Network 통신 기술 검토


## 프로세스
1. iBeacon을 백그라운드에서 Scan 시작
2. iBeacon의 신호를 받으면 BLE Scan 시작
3. 특정 Device를 발견하고 Connect 시도
4. Connect 되는 경우 Networking 시작 
5. Networking이 성공하면 다시 iBeacon Monitoring 시작


### 유의사항
백그라운드에서 BLE 스캔을 원하는 경우 Device의 Service UUID가 필요함.
