import Foundation      // 🍎 Foundation 기본 라이브러리
import CoreLocation    // 📍 위치 정보를 다루기 위해 CoreLocation 프레임워크 임포트
import Combine         // 🔁 ObservableObject와 @Published 사용 시 내부적으로 Combine 사용 (명시해두면 좋음)

/// 사용자의 현재 위치를 가져와서 SwiftUI에서 사용할 수 있게 해주는 매니저 클래스
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // @Published: 값이 변경될 때마다 SwiftUI 뷰가 새로 그려질 수 있도록 알림을 보내는 속성 래퍼
    @Published var lastLocation: CLLocation? = nil // 🗺️ 마지막으로 받은 위치 정보를 저장 (위도/경도 포함)

    private let manager = CLLocationManager()      // ⚙️ 실제 위치 서비스를 담당하는 시스템 객체

    override init() {                     // 🧱 LocationManager가 생성될 때 호출되는 이니셜라이저
        super.init()                      // 🧩 NSObject 초기화
        manager.delegate = self           // 🤝 위치 변경 이벤트를 이 객체에서 받도록 delegate 설정
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters // 🎯 100m 정도의 정확도로 요청 (배터리 절약 + 충분한 정확도)
        manager.requestWhenInUseAuthorization()    // 🔐 앱 사용 중 위치 접근 권한 요청 (Info.plist에 설명 필요)
        manager.startUpdatingLocation()            // 📡 위치 업데이트 시작 요청
    }

    // MARK: - CLLocationManagerDelegate 구현

    /// 위치가 변경될 때마다 시스템이 호출해주는 메서드
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // locations 배열 중 가장 마지막(가장 최신) 위치를 lastLocation에 저장
        lastLocation = locations.last // 🧷 최신 위치를 보관 → SwiftUI에서 이 값을 사용해 주변 검색 가능
    }

    /// 위치 업데이트 중 오류가 발생했을 때 호출되는 메서드
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 에러 내용을 콘솔에 출력 (디버깅용)
        print("위치 업데이트 실패: \(error.localizedDescription)") // 🪵 실제 앱에서는 사용자에게 알림을 띄우는 식으로 확장 가능
    }
}
