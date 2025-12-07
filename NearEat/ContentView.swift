import SwiftUI        // 🎨 SwiftUI 프레임워크 임포트 (선언형 UI 작성을 위해 필요)
import CoreLocation   // 📍 CLLocation을 직접 다룰 수 있게 임포트

/// 앱의 메인 화면 역할을 하는 뷰
/// - 상단 타이틀/부제목
/// - 검색어 입력
/// - 카테고리 버튼(한식/양식/일식/중식/카페/분식/전체)
/// - 랜덤 추천 카드
/// - 검색 결과 리스트 (카드 스타일)
struct ContentView: View {
    // MARK: - 상태 및 환경 값 정의

    @StateObject private var viewModel = RestaurantSearchViewModel() // 🧠 검색 로직 + 상태를 관리하는 뷰모델
    @StateObject private var locationManager = LocationManager()     // 📍 현재 위치를 받아오기 위한 매니저

    @Environment(\.openURL) var openURL // 🌐 카카오맵 웹 상세 페이지 열 때 사용

    // MARK: - 카테고리 관련 상태

    /// UI에 보여줄 카테고리 목록 (라벨 + 실제 검색어)
    /// - label: 버튼에 보여줄 텍스트 (이모지 포함)
    /// - keyword: 카카오 검색에 사용할 실제 검색어
    private let categories: [(label: String, keyword: String)] = [
        ("🍽 전체", "맛집"),   // 전체: 주변 맛집 전반
        ("🍚 한식", "한식"),   // 한식
        ("🍝 양식", "양식"),   // 양식
        ("🍣 일식", "일식"),   // 일식
        ("🥟 중식", "중식"),   // 중식
        ("☕️ 카페", "카페"),   // 카페
        ("🍢 분식", "분식")    // 분식
    ]

    /// 카테고리 그리드 레이아웃 (3컬럼 → 3×2로 배치)
    private let categoryGridColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 10), // 📏 폭을 균등 분배하는 컬럼
        count: 3                                       // 👉 한 줄에 최대 3개
    )

    /// 현재 선택된 카테고리 라벨 (버튼 하이라이트용)
    @State private var selectedCategoryLabel: String? = nil // 🎯 사용자가 누른 카테고리 상태

    // MARK: - 랜덤 추천 관련 상태

    /// 랜덤으로 선택된 음식점
    @State private var randomRestaurant: Restaurant? = nil // 🎲 랜덤 추천 음식점 1개

    /// 랜덤 추천을 알림(Alert)로 보여줄지 여부
    @State private var showRandomAlert: Bool = false // 🔔 Alert 표시 여부

    var body: some View { // 🧱 뷰의 실제 UI 구조를 정의하는 부분
        NavigationView { // 🧭 상단에 네비게이션 바(타이틀 등)를 제공하는 컨테이너
            VStack(spacing: 16) { // 📦 세로 방향으로 뷰들을 쌓는 레이아웃, 요소 간 간격 16

                // MARK: - 상단 타이틀 영역

                VStack(alignment: .leading, spacing: 4) { // 📦 타이틀/부제목을 세로로 배치
                    Text("NearEat")                    // 🏷 앱 이름 또는 서비스 이름
                        .font(.largeTitle.bold())      // 🔠 큰 제목 + 굵게 스타일

                    Text("지금 이 근처, 뭐 먹을지 고민될 때") // 💬 부제목/설명 문구
                        .font(.subheadline)           // 🔡 작은 보조 텍스트
                        .foregroundColor(.secondary)  // 🎨 흐린 색상으로 표시
                }
                .frame(maxWidth: .infinity, alignment: .leading) // 📏 왼쪽 정렬 유지

                // MARK: - 검색 박스 (검색창 + 카테고리 버튼 카드)

                VStack(alignment: .leading, spacing: 12) { // 📦 검색과 카테고리를 하나의 카드로 묶기

                    // 🔍 검색 영역 (텍스트 검색)
                    HStack {
                        TextField(
                            "먹고 싶은 메뉴를 입력하세요 (예: 치킨, 파스타)", // 💬 플레이스홀더 텍스트
                            text: $viewModel.query                           // 🔗 ViewModel의 query와 양방향 바인딩
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle()) // 🎨 둥근 테두리 스타일 적용
                        .submitLabel(.search)                           // ⌨️ 키보드 리턴 키를 "검색" 아이콘으로 변경
                        .onSubmit {                                    // 🔔 사용자가 키보드에서 검색을 눌렀을 때 호출되는 클로저
                            selectedCategoryLabel = nil               // 🎯 카테고리 선택 해제 (순수 키워드 검색 의미)
                            searchWithCurrentLocation()                // 📌 현재 위치 기반 검색 실행
                        }

                        Button {                 // 🔘 "검색" 버튼
                            selectedCategoryLabel = nil               // 🎯 카테고리 선택 해제
                            searchWithCurrentLocation()               // 👉 버튼 탭 시 동일하게 검색 실행
                        } label: {
                            Text("검색")                              // 🏷 버튼 텍스트
                                .padding(.horizontal, 10)             // 📏 좌우 여백
                                .padding(.vertical, 6)                // 📏 상하 여백
                                .background(Color.blue.opacity(0.1))  // 🎨 옅은 파란 배경
                                .cornerRadius(8)                      // 🔲 둥근 모서리
                        }
                    }

                    // MARK: - 🍽 카테고리 버튼 영역 (3줄 레이아웃)

                    // 1️⃣ 첫 번째 줄: "전체" 버튼을 가로로 길게 한 줄 배치
                    if let first = categories.first {
                        Button {
                            // "전체" 선택 → 해당 카테고리 키워드로 검색
                            selectedCategoryLabel = first.label
                            searchByCategory(keyword: first.keyword)
                        } label: {
                            Text(first.label)                         // 🍽 전체
                                .font(.headline)                     // 🔠 조금 더 강조된 폰트
                                .frame(maxWidth: .infinity)          // 📏 가로 전체 폭 사용
                                .padding(.vertical, 10)              // 📏 상하 여백
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            selectedCategoryLabel == first.label
                                            ? Color.blue.opacity(0.2) // ✅ 선택 시 파란 톤
                                            : Color.gray.opacity(0.15) //  기본은 옅은 회색
                                        )
                                )
                                .foregroundColor(.primary)           // 🎨 텍스트 색상
                        }
                        .padding(.horizontal, 4)                      // 📏 좌우 약간의 여백
                    }

                    // 2️⃣ 두 번째/세 번째 줄: 나머지 6개 카테고리를 3×2 그리드로 배치
                    LazyVGrid(columns: categoryGridColumns, spacing: 10) {
                        ForEach(Array(categories.dropFirst()), id: \.label) { item in
                            Button {
                                // 개별 카테고리 선택 시
                                selectedCategoryLabel = item.label
                                searchByCategory(keyword: item.keyword)
                            } label: {
                                Text(item.label)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)      // 📏 셀 안에서 가로 꽉 채우기
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                selectedCategoryLabel == item.label
                                                ? Color.blue.opacity(0.2)
                                                : Color.gray.opacity(0.15)
                                            )
                                    )
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.top, 4)                                 // 📏 상단 여백 약간
                }
                .padding(12)                                           // 📏 카드 안쪽 여백
                .background(Color(.secondarySystemBackground))         // 🎨 시스템 보조 배경색
                .cornerRadius(14)                                      // 🔲 둥근 모서리
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2) // 🌫 약한 그림자

                // MARK: - 랜덤 추천 영역

                VStack(alignment: .leading, spacing: 8) { // 📦 랜덤 추천 전체 래퍼
                    HStack {
                        Text("랜덤 추천")                 // 🏷 섹션 제목
                            .font(.headline)

                        Spacer()                          // 📏 우측으로 버튼 밀기

                        Button {
                            randomRecommend()             // 🎲 랜덤 추천 실행
                        } label: {
                            HStack(spacing: 4) {         // ➖ 아이콘 + 텍스트를 가로로 배치
                                Image(systemName: "dice") // 🎲 주사위 아이콘
                                Text("다시 뽑기")        // 🏷 다시 추천 버튼
                            }
                            .font(.caption)              // 🔡 작은 폰트
                            .padding(.horizontal, 10)    // 📏 좌우 여백
                            .padding(.vertical, 6)       // 📏 상하 여백
                            .background(Color.blue.opacity(0.1)) // 🎨 옅은 파란색 배경
                            .cornerRadius(10)            // 🔲 둥근 모서리
                        }
                    }

                    // 랜덤 추천된 음식점 카드
                    if let random = randomRestaurant { // 🎲 랜덤 음식점이 존재할 때만 표시
                        VStack(alignment: .leading, spacing: 4) { // 📦 카드 레이아웃
                            Text(random.name)                     // 🍽 음식점 이름
                                .font(.headline)

                            Text(
                                random.roadAddress.isEmpty
                                ? random.address
                                : random.roadAddress
                            )                                     // 🏠 주소
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                            if let distance = random.distance, !distance.isEmpty { // 📏 거리 정보가 있을 때만 표시
                                Text("거리: 약 \(distance) m")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(10)                                       // 📏 카드 안쪽 여백
                        .background(Color(.secondarySystemBackground))     // 🎨 카드 배경색
                        .cornerRadius(10)                                  // 🔲 둥근 모서리
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1) // 🌫 은은한 그림자
                        .onTapGesture {                                    // 👆 카드 탭 시 해당 식당 상세(웹) 열기
                            if let url = URL(string: random.url) {        // 🔗 문자열 → URL 변환
                                openURL(url)                               // 🌐 브라우저에서 열기
                            }
                        }
                    } else {
                        // 아직 랜덤 추천이 없을 때 간단한 안내 텍스트
                        Text("검색 결과가 있을 때 랜덤 추천을 받을 수 있어요.") // 💬 안내 문구
                            .font(.caption)
                            .foregroundColor(.secondary)
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

                // MARK: - 결과 없을 때 Empty State 처리

                if !viewModel.isLoading && viewModel.restaurants.isEmpty {
                    // 검색이 끝났는데 결과가 없을 때 보여줄 화면
                    VStack(spacing: 8) {                       // 📦 중앙 정렬된 빈 상태 뷰
                        Image(systemName: "fork.knife")        // 🍴 포크/나이프 아이콘
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))

                        Text("조건에 맞는 음식점을 찾지 못했어요.") // 💬 안내 메시지
                            .font(.body)
                        Text("다른 카테고리나 키워드로 다시 검색해보는 건 어떨까요?") // 💬 추가 안내
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 📏 남는 공간 전체 차지
                } else {
                    // MARK: - 검색 결과 리스트 (카드 스타일)

                    List(viewModel.restaurants) { restaurant in // 📋 Restaurant 배열을 리스트로 표시
                        ZStack { // 🧱 카드 느낌을 위해 배경 위에 올리기
                            // 카드 배경
                            RoundedRectangle(cornerRadius: 12)               // 🔲 둥근 사각형
                                .fill(Color(.secondarySystemBackground))     // 🎨 카드 배경색
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1) // 🌫 약한 그림자

                            // 카드 내용
                            VStack(alignment: .leading, spacing: 6) { // 📦 카드 내부 레이아웃
                                // 상단: 음식점 이름
                                Text(restaurant.name)                 // 🍽 음식점 이름
                                    .font(.headline)

                                // 중간: 주소
                                Text(
                                    restaurant.roadAddress.isEmpty
                                    ? restaurant.address
                                    : restaurant.roadAddress
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                                // 하단: 거리 + 전화번호
                                HStack(spacing: 12) { // ➖ 거리/전화 정보를 가로로 배치
                                    if let distance = restaurant.distance, !distance.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin.and.ellipse") // 📍 핀 아이콘
                                            Text("\(distance) m")                   // 📏 거리
                                        }
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    }

                                    if let phone = restaurant.phone, !phone.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "phone.fill")         // ☎️ 전화 아이콘
                                            Text(phone)                            // 번호
                                        }
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(12) // 📏 카드 안쪽 여백
                        }
                        .listRowInsets(EdgeInsets()) // 📏 기본 인셋 제거 → 카드가 꽉 차게
                        .padding(.vertical, 4)       // 📏 카드 사이 간격
                        .onTapGesture {              // 👆 셀(카드)을 탭했을 때 동작 정의
                            // 카카오에서 내려준 place_url을 URL로 변환 후 openURL로 열기 (웹 브라우저)
                            if let url = URL(string: restaurant.url) { // 🔗 문자열 → URL 변환
                                openURL(url)                          // 🌐 사파리 또는 브라우저에서 열기
                            }
                        }
                    }
                    .listStyle(.plain) // 📋 기본 그룹 스타일 대신 심플한 리스트 스타일 사용
                }
            }
            .padding()                      // 📏 전체 VStack에 패딩(여백) 부여
            .navigationTitle("주변 음식점 추천") // 🧭 네비게이션 바 타이틀 설정
            .navigationBarTitleDisplayMode(.inline) // 🔠 타이틀을 크게 말고 인라인으로 표시
            // 랜덤 추천을 알림(Alert)으로도 보여주고 싶으면 여기 사용 (현재는 카드만으로도 충분해서 유지/삭제 선택 가능)
            .alert("랜덤 추천 결과", isPresented: $showRandomAlert) { // 🔔 showRandomAlert가 true일 때 알림 표시
                Button("닫기", role: .cancel) { } // ❌ 닫기 버튼
            } message: {
                if let random = randomRestaurant { // 🎲 추천 음식점이 있을 때
                    Text("\(random.name)\n\(random.roadAddress.isEmpty ? random.address : random.roadAddress)")
                } else {
                    Text("랜덤 추천할 음식점이 없습니다. 먼저 검색을 해주세요.")
                }
            }
        }
    }

    // MARK: - 현재 위치 기반 검색 실행 함수 (기존 LocationManager 사용 그대로 유지)

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

    // MARK: - 카테고리 기반 검색 함수

    /// 카테고리 검색어(한식, 양식 등)를 기반으로 query를 설정하고 현재 위치 기준 검색을 실행
    private func searchByCategory(keyword: String) {
        viewModel.query = keyword     // 🔤 카테고리에 해당하는 검색어를 그대로 사용
        viewModel.errorMessage = nil  // ❌ 이전 에러 메시지 초기화
        searchWithCurrentLocation()   // 📌 위치 기반 검색 실행
    }

    // MARK: - 랜덤 추천 로직

    /// 검색된 음식점 리스트에서 1개를 랜덤으로 선택하는 함수
    private func randomRecommend() {
        // 검색 결과가 비어 있으면 안내 메시지 설정 후 리턴
        guard !viewModel.restaurants.isEmpty else { // ❓ 아무 결과도 없을 때
            viewModel.errorMessage = "랜덤 추천은 검색 결과가 있을 때만 가능합니다. 먼저 검색해 주세요." // ⚠️ 안내 메시지
            randomRestaurant = nil              // 🎲 선택된 음식점 초기화
            return                              // 🚪 함수 종료
        }

        // 배열에서 랜덤 요소 하나를 뽑기
        if let picked = viewModel.restaurants.randomElement() { // 🎲 randomElement로 한 개 선택
            randomRestaurant = picked                          // 🎯 상태에 저장
            // 카드만으로도 충분하지만, Alert도 함께 띄우고 싶다면 아래 플래그 유지
            showRandomAlert = false                            // 🔔 Alert 사용을 줄이고 싶으면 false로 유지
        }
    }
}

// MARK: - 미리보기 (Xcode Canvas용)

struct ContentView_Previews: PreviewProvider { // 🖼 Xcode의 Canvas에서 이 뷰를 미리 보기 위한 구조체
    static var previews: some View {           // 👀 미리보기에서 보여줄 뷰 정의
        ContentView()                          // 📱 ContentView를 그대로 미리보기로 렌더링
    }
}
