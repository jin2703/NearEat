import Foundation // 🍎 Foundation 프레임워크 임포트 (String, Decodable 같은 기본 타입 사용을 위해 필요)

// MARK: - 카카오 장소 검색 응답 상위 구조체

/// 카카오 로컬 API의 응답 전체 구조 중에서
/// 우리는 documents 배열만 사용하므로, 그 부분만 감싸는 구조체를 정의
struct KakaoSearchResponse: Decodable { // 🔍 JSON 디코딩을 위해 Decodable 프로토콜 채택
    let documents: [Restaurant]         // 📄 실제 음식점(장소) 정보들이 들어 있는 배열
}

// MARK: - 한 개 음식점을 나타내는 모델

/// 카카오 로컬 API에서 내려주는 한 개 장소(음식점) 정보를 Swift에서 다루기 위한 모델
struct Restaurant: Identifiable, Decodable { // 🔑 List에서 ForEach 사용을 위해 Identifiable, JSON 파싱을 위해 Decodable 채택
    let id: String            // 🆔 장소 고유 ID (카카오가 부여)
    let name: String          // 📛 음식점 이름 (place_name)
    let roadAddress: String   // 🛣 도로명 주소 (road_address_name)
    let address: String       // 🏠 지번 주소 (address_name)
    let distance: String?     // 📏 현재 좌표 기준 거리 (미터 단위, 문자열이라 Optional)
    let phone: String?        // ☎️ 전화번호 (없는 경우도 있어 Optional)
    let url: String           // 🔗 카카오맵 상세 페이지 URL (place_url)
    let x: String             // 🌐 경도 (longitude, 문자열)
    let y: String             // 🌐 위도 (latitude, 문자열)

    // JSON에서 오는 key 이름과 Swift 프로퍼티 이름이 다를 때 사용하는 매핑
    enum CodingKeys: String, CodingKey {       // 📦 JSON 키 → Swift 프로퍼티 이름을 연결해주는 열거형
        case id                                // 🆔 JSON의 "id" → id
        case name = "place_name"               // 📛 JSON의 "place_name" → name
        case roadAddress = "road_address_name" // 🛣 JSON의 "road_address_name" → roadAddress
        case address = "address_name"          // 🏠 JSON의 "address_name" → address
        case distance                          // 📏 JSON의 "distance" → distance
        case phone                             // ☎️ JSON의 "phone" → phone
        case url = "place_url"                 // 🔗 JSON의 "place_url" → url
        case x                                 // 🌐 JSON의 "x" → x
        case y                                 // 🌐 JSON의 "y" → y
    }
}
