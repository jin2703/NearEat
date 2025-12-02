import Foundation        // 🍎 URL, URLRequest, JSONDecoder 등을 사용하기 위한 Foundation
import CoreLocation      // 📍 CLLocation을 사용할 수 있게 임포트
import Combine           // 🔁 ObservableObject, @Published 동작과 관련된 Combine

/// 음식점 검색과 관련된 모든 상태와 로직을 관리하는 ViewModel
/// SwiftUI 뷰에서 이 객체를 구독하면서 UI를 갱신하게 됨
class RestaurantSearchViewModel: ObservableObject {
    // MARK: - 뷰와 바인딩되는 상태 값들

    @Published var query: String = ""           // 🔤 사용자가 입력한 검색어 (예: "치킨", "파스타")
    @Published var restaurants: [Restaurant] = [] // 📦 검색 결과로 받아온 음식점 리스트
    @Published var isLoading: Bool = false      // ⏳ 현재 네트워크 요청 중인지 여부
    @Published var errorMessage: String? = nil  // ❗ 사용자에게 보여줄 에러 메시지 (없으면 nil)

    // MARK: - 카카오 API 관련 설정

    /// 카카오 REST API 키 (⚠️ 실제 키를 여기에 넣어야 함)
    /// - 실제 배포 앱에서는 코드에 직접 넣지 않고, 서버나 안전한 저장소에 보관하는 것이 권장됨
    private let kakaoRESTAPIKey: String = "Your API KEY" // 🔑 반드시 수정 필요

    // MARK: - 공용 검색 메서드 (현재 위치 기준)

    /// 현재 위치(위도, 경도)를 기준으로 카카오 로컬 API에 요청을 보내 음식점 목록을 가져오는 비동기 함수
    /// - Parameters:
    ///   - latitude: 현재 위치 위도
    ///   - longitude: 현재 위치 경도
    @MainActor
    func searchRestaurantsNearMe(latitude: Double, longitude: Double) async {
        // MainActor: UI 상태를 안전하게 변경하기 위해 사용 (isLoading, errorMessage, restaurants 등)

        // 🔄 검색을 시작하므로, 에러 초기화 + 로딩 상태 on
        errorMessage = nil  // ❌ 이전 에러 메시지 초기화
        isLoading = true    // ⏳ 로딩 중 표시

        // MARK: - URL 구성

        var components = URLComponents()          // 🧱 URL을 파라미터와 함께 안전하게 만들기 위한 도우미
        components.scheme = "https"               // 🌐 HTTPS 프로토콜 사용
        components.host = "dapi.kakao.com"        // 🏢 카카오 로컬 API 서버 주소
        components.path = "/v2/local/search/keyword.json" // 🛣 키워드 장소 검색 엔드포인트

        // 쿼리 스트링으로 전달할 파라미터들을 정의
        components.queryItems = [
            URLQueryItem(name: "query", value: query),               // 🔤 검색어 (사용자 입력)
            URLQueryItem(name: "x", value: "\(longitude)"),          // 🌐 경도 (문자열로 변환)
            URLQueryItem(name: "y", value: "\(latitude)"),           // 🌐 위도 (문자열로 변환)
            URLQueryItem(name: "radius", value: "1000"),             // 📏 반경 1000m(1km) 이내 검색
            URLQueryItem(name: "category_group_code", value: "FD6"), // 🍽 FD6 = 음식점 카테고리 코드
            URLQueryItem(name: "sort", value: "distance")            // 📌 거리순 정렬
        ]

        // URLComponents로부터 실제 URL 생성 (실패하면 에러 처리 후 종료)
        guard let url = components.url else { // ❓ URL 생성 실패 시
            errorMessage = "검색 URL을 만드는 데 실패했습니다." // ⚠️ 개발/테스트용 메시지
            isLoading = false                                   // ⏹ 로딩 상태 해제
            return                                              // 🚪 함수 종료
        }

        // MARK: - URLRequest 구성

        var request = URLRequest(url: url)                      // 📮 요청 객체 생성
        request.httpMethod = "GET"                              // 📬 GET 방식으로 요청
        // Authorization 헤더에 KakaoAK + REST API 키를 넣어 인증
        request.addValue("KakaoAK \(kakaoRESTAPIKey)", forHTTPHeaderField: "Authorization") // 🔑 카카오 인증 헤더

        // MARK: - 네트워크 요청 실행

        do {
            // URLSession의 비동기 data(for:) 메서드를 사용해 요청을 보내고 응답을 기다림
            let (data, response) = try await URLSession.shared.data(for: request) // 🌐 서버로부터 데이터 + 응답 수신

            // 응답을 HTTPURLResponse로 캐스팅해서 상태 코드 확인
            if let httpResponse = response as? HTTPURLResponse, // 📄 HTTP 응답 객체로 변환 시도
               httpResponse.statusCode != 200 {                 // ✅ 200이 아니면 에러로 판단
                errorMessage = "서버 응답 에러: \(httpResponse.statusCode)" // ❗ 상태 코드 기반 에러 메시지
                isLoading = false                               // ⏹ 로딩 상태 해제
                return                                          // 🚪 함수 종료
            }

            // MARK: - JSON 디코딩

            // 내려온 JSON 데이터를 KakaoSearchResponse 구조체로 디코딩
            let decoded = try JSONDecoder().decode(KakaoSearchResponse.self, from: data) // 🧬 JSON → Swift 구조체 변환

            // 성공적으로 파싱되었으므로, restaurants에 결과 반영
            restaurants = decoded.documents // 📦 음식점 리스트 업데이트
            isLoading = false              // ⏹ 로딩 상태 해제
        } catch {
            // 네트워크 오류 또는 디코딩 오류 발생 시
            errorMessage = "데이터를 불러오는 중 오류가 발생했습니다: \(error.localizedDescription)" // ❗ 구체적인 에러 메시지 저장
            isLoading = false // ⏹ 로딩 상태 해제
        }
    }
}
