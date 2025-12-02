import SwiftUI        // 🎨 SwiftUI 프레임워크 임포트 (선언형 UI 작성을 위해 필요)
import CoreLocation   // 📍 CLLocation을 직접 다룰 수 있게 임포트

/// 앱의 메인 화면 역할을 하는 뷰
/// - 검색어 입력 → 현재 위치 기준 음식점 검색 → 리스트 표시
struct ContentView: View {
    // MARK: - 상태 및 환경 값 정의

    // ViewModel을 StateObject로 보관 → 뷰가 새로 그려져도 같은 인스턴스를 유지
    @StateObject private var viewModel = RestaurantSearchViewModel() // 🧠 검색 로직 + 상태를 관리하는 뷰모델

    // LocationManager도 StateObject로 보관 → 위치 정보 관리
    @StateObject private var locationManager = LocationManager()     // 📍 현재 위치를 받아오기 위한 매니저

    // openURL: SwiftUI에서 외부 브라우저(사파리 등)로 URL을 여는 기능을 제공하는 환경 값
    @Environment(\.openURL) var openURL // 🌐 카카오맵 상세 페이지 열 때 사용

    var body: some View { // 🧱 뷰의 실제 UI 구조를 정의하는 부분
        NavigationView { // 🧭 상단에 내비게이션 바(타이틀 등)를 제공하는 컨테이너
            VStack(spacing: 16) { // 📦 세로 방향으로 뷰들을 쌓는 레이아웃, 요소 간 간격 16
                // MARK: - 검색 영역

                HStack { // ➖ 가로 방향 레이아웃: TextField + 버튼
                    TextField(
                        "먹고 싶은 메뉴를 입력하세요", // 💬 플레이스홀더 텍스트
                        text: $viewModel.query                           // 🔗 ViewModel의 query와 양방향 바인딩
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle()) // 🎨 기본 둥근 테두리 스타일 적용
                    .submitLabel(.search)                           // ⌨️ 키보드 리턴 키를 "검색" 아이콘으로 변경
                    .onSubmit {                                    // 🔔 사용자가 키보드에서 검색을 눌렀을 때 호출되는 클로저
                        searchWithCurrentLocation()                // 📌 현재 위치 기반 검색 실행
                    }

                    Button {                 // 🔘 "검색" 버튼 정의
                        searchWithCurrentLocation() // 👉 버튼 탭 시 동일하게 현재 위치 기반 검색 수행
                    } label: {              // 🔖 버튼에 표시될 뷰 정의
                        Text("검색")        // 🏷 "검색" 텍스트 표시
                    }
                }

                // MARK: - 로딩 상태 표시

                if viewModel.isLoading { // ⏳ ViewModel에서 isLoading이 true일 때
                    ProgressView("주변 음식점을 찾는 중입니다...") // 🌀 로딩 인디케이터 + 설명 문구
                }

                // MARK: - 에러 메시지 표시

                if let errorMessage = viewModel.errorMessage { // ❗ 에러 메시지가 존재할 때만 표시
                    Text(errorMessage)                        // ⚠️ 에러 내용 텍스트
                        .foregroundColor(.red)                // 🔴 빨간색 텍스트로 강조
                        .font(.footnote)                      // 🔡 작은 폰트 사이즈
                        .multilineTextAlignment(.center)      // 📏 여러 줄 중앙 정렬
                }

                // MARK: - 검색 결과 리스트

                List(viewModel.restaurants) { restaurant in // 📋 Restaurant 배열을 리스트로 표시
                    VStack(alignment: .leading, spacing: 4) { // 📦 각 셀을 세로로 정렬, 왼쪽 정렬
                        // 음식점 이름
                        Text(restaurant.name)         // 🍽 음식점 이름 텍스트
                            .font(.headline)          // 🔠 헤드라인(굵은) 폰트 스타일

                        // 도로명 주소가 있으면 우선 사용, 없으면 지번 주소 사용
                        Text(
                            restaurant.roadAddress.isEmpty
                            ? restaurant.address
                            : restaurant.roadAddress
                        )
                        .font(.subheadline)           // 🔡 서브헤드라인 폰트
                        .foregroundColor(.secondary)  // 🎨 흐린 색상으로 표시

                        // 거리 정보가 있을 때만 표시
                        if let distance = restaurant.distance, !distance.isEmpty {
                            Text("거리: 약 \(distance) m") // 📏 대략적인 거리 정보
                                .font(.caption)          // 🔡 작은 캡션 폰트
                                .foregroundColor(.gray)  // 🌫 회색
                        }

                        // 전화번호가 있을 때만 표시
                        if let phone = restaurant.phone, !phone.isEmpty {
                            Text("전화: \(phone)")       // ☎️ 전화번호 표시
                                .font(.caption)          // 🔡 캡션 폰트
                                .foregroundColor(.gray)  // 🌫 회색
                        }
                    }
                    .padding(.vertical, 4) // 📏 각 셀 위아래 여백
                    .onTapGesture {        // 👆 셀을 탭했을 때 동작 정의
                        // 카카오에서 내려준 place_url을 URL로 변환 후 openURL로 열기
                        if let url = URL(string: restaurant.url) { // 🔗 문자열 → URL 변환
                            openURL(url)                          // 🌐 사파리 또는 카카오맵 앱에서 열기
                        }
                    }
                }
            }
            .padding()                      // 📏 전체 VStack에 패딩(여백) 부여
            .navigationTitle("주변 음식점 추천") // 🧭 네비게이션 바 타이틀 설정
        }
    }

    // MARK: - 현재 위치 기반 검색 실행 함수

    /// LocationManager에서 현재 위치를 가져와, ViewModel의 검색 메서드를 호출하는 헬퍼 함수
    private func searchWithCurrentLocation() {
        // 위치 정보가 아직 없는 경우 처리
        guard let location = locationManager.lastLocation else { // ❓ lastLocation이 nil이면
            viewModel.errorMessage = "현재 위치 정보를 가져오는 중입니다. 잠시 후 다시 시도해주세요." // ⚠️ 사용자에게 안내
            return                                               // 🚪 함수 종료
        }

        // 현재 위치에서 위도와 경도 추출
        let latitude = location.coordinate.latitude    // 🌐 위도 값
        let longitude = location.coordinate.longitude  // 🌐 경도 값

        // Swift의 비동기 작업 컨텍스트(Task)에서 ViewModel의 async 메서드 호출
        Task { // 🧵 새로운 비동기 작업 시작
            await viewModel.searchRestaurantsNearMe(latitude: latitude, longitude: longitude) // 🔍 실제 검색 수행
        }
    }
}

// MARK: - 미리보기 (Xcode Canvas용)

struct ContentView_Previews: PreviewProvider { // 🖼 Xcode의 Canvas에서 이 뷰를 미리 보기 위한 구조체
    static var previews: some View {           // 👀 미리보기에서 보여줄 뷰 정의
        ContentView()                          // 📱 ContentView를 그대로 미리보기로 렌더링
    }
}
