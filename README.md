👆🏻 여기 햄버거를 눌러 목차를 확인하세요

# 오픈마켓 프로젝트

#### 프로젝트 기간 - 2021.08.09 - 2021.08.27
#### 프로젝트 팀원 - [Joey](https://github.com/joey-ful), [Soll](https://github.com/soll4u)


## Step1 - 모델/네트워킹 타입 구현

### Mock 객체
#### Mock 객체의 필요성
- 네트워크 통신을 하기 위해 URLSession의 `dataTask(with:completionHandler:)` 메서드를 사용했다. 하지만 서버가 아직 만들어지지 않았거나 당장 인터넷 통신이 불가한 경우 등을 대비해 실제 메서드 대신 mock 객체의 메서드를 활용해 데이터를 받아오는 방법을 구현했다.
  - URLSession을 mocking한 MockURLSesssion 타입을 구현했다.
  - 두 타입을 추상화한 URLSessionProtocol을 구현하고 requirement로 URLSession의 메서드인 `dataTask(with:completionHandler:)` 선언했다.
 
#### 의존성 주입
 - 네트워크 통신을 하는 타입은 URLSession과 MockURLSession을 추상화한 타입을 가지고 있어야 하며 이는 둘 중 어느 것이든 될 수 있기 때문에 인스턴스를 외부에서 주입하는 방식으로 구현했다.
  ```swift
  struct NetworkManager {
      let session: URLSessionProtocol
    
      init(session: URLSessionProtocol) {
          self.session = session
      }
  }
  ```
#### Mock 객체는 실제와 흡사하게 구현
- 그리고 실사용은 주입받은 객체가 무엇인지 관계없이 그대로 `dataTask(with:completionHandler:)` 메서드를 사용한다
```swift
let task: URLSessionDataTaskProtocol = session
    .dataTask(with: request) { data, urlResponse, error in
        //...
    }
task.resume()
```
- 이를 위해 Mock 객체는 실제 객체와 유사하게 작동해야 하며 실제 데이터와 흡사한 가짜 데이터를 전달해줘야 했다. 로컬에 Items와 Item, 두 가지 데이터가 있었고 파일 이름을 각 데이터의 url로 지정했다. 그리고 각 데이터의 url을 넘겨주면 해당하는 데이터를 반환, 다른 url을 넘겨주면 통신에 실패하도록 구현했다.

#### URLSessionDataTask
- 해당 메서드는 URLSessionDataTask 를 반환하는데 Mock 객체에서는 URLSessionDataTask를 상속받는 MockURLSessionDataTask를 반환하도록 했다. 
  - URLSessionDataTask 의 `resume()`를 override하기 위함이다.
  - 하지만 URLSessionDataTask를 초기화하는 init()은 deprecated되었다는 경고 메시지가 떠서 그대로 상속을 받기에 부적절하게 생각되었다.
  - 따라서 이 둘을 추상화하는 URLSessionDataTaskProtocol을 구현했다.
  - 다만 이 경우 `dataTask(with:completionHandler:)` 메서드는 더이상 URLSessionDataTask가 아닌 이를 추상화한 URLSessionDataTaskProtocol 타입을 반환해야 한다.
  - 다음 로직을 추가해 리턴 타입을 수정했다.
  ```swift
  protocol URLSessionProtocol {
      func dataTaskWithRequest(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
    -> URLSessionDataTaskProtocol
      }

  extension URLSession: URLSessionProtocol {
      func dataTaskWithRequest(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
    -> URLSessionDataTaskProtocol {
          dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTaskProtocol
          }
      }
  ```
  
---

### Result 타입
- Unit Test를 할 함수는 리턴타입을 Result타입으로 구현했다.
- 리턴할 때는 switch문을 사용해 성공과 실패 시 값을 따로 반환했다.
  ```swift
  case .success(let decodedData):
      completion(.success(decodedData))
  case .failure(let error):
      completion(.failure(error))
  }
  ```
- 대신 리턴값을 사용하거나 테스트할 때에도 성공과 실패를 구분해서 값을 벗겨야 했다.
  ```swift
  case .success(let data):
      outcome = data.title
  case .failture(let error):
      print(error)
  case .none:
      print("none")
  }
  ```
  
---

### 비동기 Unit Test
- XCTTestExpection을 생성한다.
- 비동기 작업이 완료된 시점에 해당 expectation의 `fulfill()` 메서드로 비동기 작업이 완료됨을 알린다.
- 비동기 작업을 호출한 함수에서는 `wait(for: [expectation], timeout: 5.0)` 로 expectation이 충족되기를 기다린다.
  - expectation이 fulfill되거나 5초가 지날 때까지 기다린다.
  - 혹시 비동기 작업이 너무 오래 걸리면 기다리지 않는다. 시간을 정해두면 비동기 작업에 실패하는 경우 5초를 초과하여 기다리지 않아도 되는 이점이 있다.
  ```swift
  // given
  let urlString = MockURL.mockItem.description
  let url = try XCTUnwrap(URL(string: urlString))
  var outcome: String?
  let expectation = XCTestExpectation(description: expectationDescription)
  let expectedValue = "MacBook Pro"

  // when
  sutNetworkManager?.fetchData(url: url) { (result: Result<Item, Error>) in
      switch result {
      case .success(let data):
          outcome = data.title
      default:
          XCTFail()
      }
      expectation.fulfill()
  }
  wait(for: [expectation], timeout: 5.0)

  // then
  XCTAssertEqual(outcome, expectedValue)
  ```

### multipart/form-data
POST와 PATCH 요청을 보내기 위해 메서드의 httpBody를 multipart/form-data 로 지정하면 된다. multipart/form-data 형식이 무엇인지 간단하게 알아보기 위해 title=choco, price=9000 이라는 정보를 보낼 수 있는 형식들을 예를 들어보면 다음과 같다.

> [참고 stackoverflow](https://stackoverflow.com/questions/3508338/what-is-the-boundary-in-multipart-form-data)

- `aplication/x-www-form-urlencoded` 방식

    ```json
    title=choco&price=9000
    ```

- `multipart/form-data` 방식

    [multipart/form-data](https://developer.mozilla.org/en-US/docs/Web/API/FormData) 방식은 key/value 쌍을 쉽게 표현하는 형식

    ```json
    --XXX
    Content-Disposition: form-data; name="title"

    choco
    --XXX
    Content-Disposition: form-data; name="price"

    9000
    --XXX--
    ```

#### boundary
httpBody와 그 내부의 각 정보들은 boundary로 감싸져 있다.
- boundary는 내용들은 모두 **같은 요청에 관한 내용**임을 알리기 위한 고유 문자열이다.
- 따라서 **같은 요청**에서는 **같은 boundary**를 사용해야 한다.
- 고유 문자열은 UUIDString으로 랜덤하게 생성할 수 있다.`"Boundary-\(UUID().uuidString)"`
```json
--Boundary-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
Content-Disposition: form-data; name=\"title\"

choco
--Boundary-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
Content-Disposition: form-data; name=\"price\"

9000
--Boundary-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX--
```

#### 실제로 생성한 httpBody 출력해보기
multipart/form-dat 형식의 httpBody를 만들어 출력해보면 다음과 같다.
- httpBody를 먼저 디코딩해준다

```swift
String(decoding: request.httpBody!, as: UTF8.self)
```

- 실제 출력한 결과물 
  - httpBody에는 다음 세 가지 정보를 담았다 - `title: choco`, `price: 9000`, `image: jpeg 파일`
  - 이미지 데이터는 사람이 알아볼 수 없는 형식으로 출력된다.

```json
--Boundary-265B324D-9628-4D91-AC7A-31C6E93020B7
Content-Disposition: form-data; name="title"

choco
--Boundary-265B324D-9628-4D91-AC7A-31C6E93020B7
Content-Disposition: form-data; name="price"

9000
--Boundary-265B324D-9628-4D91-AC7A-31C6E93020B7
Content-Disposition: form-data; name="images[]"; filename="photo1602058207.jpeg"
Content-Type: image/jpeg

// 이미지 데이터 내용인데 알아볼 수 없는 형식
// ���J�;ى�	;�Ȧ8@#?N��.w?\����Q�Lcp��������� 등의 문자들로 이루어진 데이터
--Boundary-265B324D-9628-4D91-AC7A-31C6E93020B7--
```

---

### application/json content-type
DELETE 요청은 httpBody를 application/json content-type으로 보내면 된다.
- parameters를 바로 Data형식으로 변환해서 httpBody에 담을 수 있다.
> [참고 StackOverflow](https://stackoverflow.com/questions/49683960/http-request-delete-and-put)

```swift
func deleteData(url: URL, parameters: [String:String]) {
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let dataBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
    request.httpBody = dataBody!
    
    sessionDataTaskAndPrintResults(with: request)
}
```
---

### Decodable extension 에 디코딩 함수 구현
디코딩하는 메서드에 **디코딩할 데이터를 인자로 넣어주는 방법 대신** Decodable 타입에 디코딩 메서드를 추가했다. 즉, Decodable한 data에 `parse(type:)` 메서드를 적용하면 data 자체가 디코딩된다. 메서드에서 따로 data를 받을 필요가 없다는 뜻.

```swift
// data: Decodable
let parsedResult = data.parse(type: T.self)
```

- 추가해준 parse 메서드

```swift
extension Decodable {
    func parse<T: Decodable>(type: T.Type) -> Result<T, Error> {
        let decoder = JSONDecoder()
        if let data = self as? Data,
           let decodedData = try? decoder.decode(type, from: data) {
            return .success(decodedData)
        }
        return .failure(NetworkError.failToDecode)
    }
}
```


## Step2 - 상품 목록 화면 구현

### UICollectionView

상품의 목록을 UICollectionView를 통해 2단 그리드 형식으로 구현했다. viewDidLoad()가 실행되면 Model인 `items`에 데이터가 들어가도록 초기화하는 메서드 `initializedItems()`를 구현했다.
네트워킹을 하는 `NetworkManager` 의 메서드를 이용해 데이터를 fetch하고, 데이터가 성공적으로 받아와지면 메인스레드에서 컬렉션 뷰를 업데이트하도록 했다.
`GridItemCollectionViewCell` 클래스를 이용해 컬렉션 뷰에 들어가는 셀의 커스터마이징을 관리하도록 만들었다.

<img src="https://user-images.githubusercontent.com/52592748/130812553-d3137c84-0c3f-433d-98e0-24644753aed6.png" width="300"/>

---

### Lazy Loading

셀들의 이미지를 한 번에 받아오면 부하가 크기 때문에 당장 필요한 셀들의 이미지만 다운받도록 지연 로딩을 적용했다. `collectionView(_:cellForItemAt:)` 에서 셀을 dequeue한 뒤 바로 ImageLoader라는 타입을 통해 셀의 이미지를 업데이트 했다. 

<details>
<summary> <b> ImageLoader 코드 </b>  </summary>
<div markdown="1">

ImageLoader는 셀에 업데이트해야하는 이미지가 캐시에 있으면 캐시의 이미지로 업데이트하고 캐시에 없으면 비동기로 다운을 받아 업데이트 한다. 이때, 셀의 이미지뷰 업데이트는 main 스레드에서 실행해준다.

```swift
class ImageLoader {
    
    static let shared = ImageLoader()
    let cache = URLCache.shared
    
    private init() {}
    
    func loadImage(from urlString: String,
                   completion: @escaping (UIImage) -> Void) {
        
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        if let response = self.cache.cachedResponse(for: request),
           let imageData = UIImage(data: response.data) {
            DispatchQueue.main.async {
                completion(imageData)
            }
        } else {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil else { return }
                guard let response = response,
                      let statusCode = (response as? HTTPURLResponse)?.statusCode,
                      (200...299).contains(statusCode) else { return }
                guard let data = data else { return }
                
                guard let imageData = UIImage(data: data) else { return }
                
                self.cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                
                DispatchQueue.main.async {
                    completion(imageData)
                }
            }.resume()
        }
    }
}
```

</div>
</details>
<br>


이미지를 다운받는 작업은 비동기로 이루어지며 작업 시간이 길어질 수 있다. 만약 이미지가 다 다운되지 않았는데 사용자가 스크롤을 한다면 처음 이미지를 요청했던 셀의 위치가 변경된다. 즉, 같은 위치에 있는 셀이 다른 이미지를 요청하게 될 수도 있다. 

⚠️ 이 경우, 셀이 이동한 후 이미지를 다운받아 업데이트하게되면 이미지가 **갑자기 다른 이미지로 바뀌는 깜빡임 현상이 발생**하거나 아니면 **아예 잘못된 이미지가 들어가는 문제가 발생**할 수 있다.
이런 문제를 방지하기 위해 셀의 특정 정보를 비교해서 이미지를 업데이트 했다. 

#### 로직1 - indexPath 비교하기

첫 구현은 셀의 indexPath를 비교했다. 셀을 dequeue했을 당시의 indexPath와 이미지가 모두 다운로드되었을 때의 indexPath를 비교해서 둘이 같은 경우에만 이미지를 업데이트해준다.

```swift
// self = cell
ImageLoader.shared.loadImage(from: currentURLString) { imageData in
    if indexPath == collectionView.indexPath(for: self) {
        self.thumbnailImageView?.image = imageData
    }
}
```

위 로직을 추가해 이미지를 업데이트하면 더이상 이미지가 깜빡이며 바뀌거나 이상한 셀에 들어가는 문제는 발생하지 않았다.


⚠️ 하지만 위 로직은 컬렉션뷰의 Estimate Size를 None으로 설정하면 제대로 작동하지 않는다.

- UICollectionViewFlowLayout의 `collectionView(_:layout:sizeForItemAt:` 이나 itemSize 프로퍼티를 활용해 직접 계산한 셀 크기를 사용하는 경우 컬렉션뷰의 **Estimate Size를 None**으로 지정해야 계산한 크기대로 셀이 표시된다. 
- 하지만 이렇게 하는 경우 이미지의 다운이 완료된 셀의 indexPath가 nil이 나올 때가 다수 발생했다. `collectionView.indexPath(for: self)` 를 출력해보니 여러차례 nil이 출력됐다. 
- 이유는 알 수 없었지만 일단 해결을 하기 위해 두 번째 방법을 사용했다.

#### 로직2 - 셀의 프로퍼티 비교하기

위와 거의 동일한 방법인데 이번에는 indexPath대신 셀의 프로퍼티를 비교하는 로직을 구현했다. 셀이미지의 url주소를 프로퍼티로 저장해둔 후 해당 값이 같은 경우에만 이미지를 업데이트를 하도록 했다.

```swift
// self = cell
ImageLoader.shared.loadImage(from: currentURLString) { imageData in
    if self.urlString == currentURLString {
        self.thumbnailImageView?.image = imageData
    }
}
```

🥊 컬렉션뷰의 셀 크기를 직접 계산한 값으로 표시하고 싶다면 Estimate Size를 None으로 해야하는데 이 경우 지연 로딩 구현시 셀의 indexPath 비교 대신 프로퍼티 비교를 활용해야 한다.

---

### itemSize vs collectionView(_:layout:sizeForItemAt:)

- itemSize: delegate가 `collectionView(_:layout:sizeForItemAt:)`메서드를 구현하지 않는 경우 이 프로퍼티의 값을 사용해 각 셀의 크기를 설정한다. flow layout 객체가 컨텐츠의 모양을 구성하기 위해 제공하는 프로퍼티이며 모든 셀에 동일한 크기를 적용한다. 기본 크기 값은 (50.0, 50.0)이다.
- `collectionView(_:layout:sizeForItemAt:)`: 고정된 크기 집합을 반환하거나 셀의 내용에 따라 크기를 동적으로 조정할 수 있다. 각각의 셀마다 다른 크기를 지정하기 위해 이 메서드를 사용한다.

--

```swift
extension ItemsGridViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // itemSize를 지정하는 로직 구현
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
```

처음에는 `collectionView(_:layout:sizeForItemAt:)`메서드를 사용해서 구현을 했었는데, 모든 셀의 크기가 고정인 점을 고려하여 `itemSize`로 구현하도록 수정했다.


#### 작은 디바이스에서 row가 1개로 나오는 이슈

<img src="https://user-images.githubusercontent.com/52592748/130812437-eed85ccd-abe5-4605-8ec8-7177bfafaa98.png" width="300"/>


`UICollectionViewFlowLayout`을 생성해 `itemSize`의 `width`를 컬렉션 뷰의 `sectionInset`을 뺀 값의 2로 나누어서 반환하는 메서드를 구현했다.
이 과정에서 `Main.storyboard`의 디바이스와 시뮬레이터 디바이스가 다를 경우, `collectionView.bounds.width`가 다르게 나오는 이슈가 있었다.

```
(lldb) po (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
▿ (194.0, 329.8)
  - width : 194.0
  - height : 329.8

(lldb) po collectionView.bounds.width
414.0
```
위는 스토리보드에서 iPhone11로 설정하고, 시뮬레이터를 iPhone SE로 실행했을 때 `collectionView`의 `bounds.width`가 414.0으로 나온 것을 기록한 것이다.

이를 해결하기 위해서 `layoutIfNeeded()` 메서드를 이용했다.

#### `layoutIfNeeded()`를 이용한 해결
⇒ `layoutSubViews()` : **View의 값을 호출한 즉시 변경시켜주는 메서드**, 시스템에 의해 View의 값이 재계산되어야 하는 적절한 시점에 자동으로 호출된다. 이를 유도할 수 있는 여러 방법이 있고, update cycle에서 layoutSubVies()의 호출을 예약하는 행위이다.

`layoutSubViews()` 메서드를 **수동으로 예약할 수 있는 메서드**가 `setNeedsLayout()`과 `layoutIfNeeded()` 이다.

둘의 차이점은 비동기냐 동기냐의 차이이다. `layoutIfNeeded()`는 동기적으로 동작하는 메서드이기 때문에 **즉시 값이 변경되어야하는 애니메이션에서 많이 사용**한다고 한다. [출처](https://baked-corn.tistory.com/105)
```swift
func configureItemSize() -> UICollectionViewFlowLayout {
    collectionView.layoutIfNeeded() // 뷰의 값을 업데이트하기 위해 메서드 호출
    
    // itemSize를 지정하는 로직 구현
    
    layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
    
    return layout
}
```

---

### UICollectionViewFlowLayout

- flow layout은 컬렉션 뷰 레이아웃의 타입이다. 컬렉션 뷰의 아이템은 스크롤 방향에 따라 한 행이나 열에서 다름 행으로 흘러 배치된다. 각 행에는 들어갈 수 있는 수만큼의 셀이 표시된다.
- delegate object를 사용하여 레이아웃 정보를 동적으로 조정할 수 있다. 
- 각 섹션에는 고유한 사용자 지정 머리글과 바닥글이 있을 수 있다.

---

### NSCache
NSCache는 흔히 생성 비용이 크지만 단기적으로만 필요한 객체를 임시 저장하기 위해 사용한다. 해당 프로젝트에서는 한번 다운받은 이미지는 다시 다운받지 않도록 NSCache를 활용했다. 이미지의 url과 UIImage를 key, value로 갖는 딕셔너리 형태로 매핑을 해서 이미지를 가져오도록 했다. 하지만 일반 딕셔너리 대신 NSCache 타입을 활용해 이미지를 캐싱했다. 

#### NSCache의 장점
- NSCache는 다른 어플리케이션에서 메모리를 필요로 할 때 내부 아이템을 일부 삭제하는 기능이 있어 시스템의 메모리를 너무 많이 차지하지 않음을 보장한다.
- NSCache는 thread-safe하기 때문에 여러 스레드에서 해당 캐시에 항목을 추가하거나 제거할 수 있다.
- NSMutableDictionary와 다르게 항목을 추가할 때 객체를 복사하지 않는다고 한다.

### NSCache vs URLCache
네트워크 통신의 request와 response를 매핑하는 URLCache를 접하게 되어 사용해봤다. 네트워크 데이터는 다음 이유로 URLCache를 사용하는 것이 더 좋다고 한다:
- NSCache는 메모리를 일부 비워주긴하지만 다 비워주지는 않기 때문에 `didReceiveMemoryWarning()` 을 오버라이드해 메모리를 직접 flush해줘야 한다.
- NSCache가 메모리를 일부 비워주는 방법이 체계적이지 않다고 한다.
- URLCache는 in-memory이자 on-disk 캐시라고 한다. 큰 메모리 덩어리를 할당하는 것이 아니라 더 유연한 구조라고 한다. in-memory와 on-disk는 메인메모리와 하드디스크로 속도, 용량, 휘발성에서 차이가 있는 저장구조.
  - **속도** - **in-memory** 데이터베이스는 모든 자료가 메인 메모리에 저장되기 때문에 데이터를 읽거나 수정할 때 디스트 입출력 작업이 필요하지 않아 **더 빠르다.**
  - **용량** - **in-memory** 데이터베이스의 용량은 **메인 메모리 용량으로 한정된다.**
  - **휘발성** - in-memory는 데이터베이스 제품에 따라 휘발성일 수도 있고 아닐 수도 있는 반면 **on-disk는 휘발성이지 않다.**

> 참고 자료
> [To `NSCache` or not to `NSCache`, what is the `URLCache`](https://medium.com/@master13sust/to-nscache-or-not-to-nscache-what-is-the-urlcache-35a0c3b02598)
> [Swift: Loading Images Asynchronously and storing with NSCache and NSURLCache](https://www.youtube.com/watch?v=BIgqHLTZ_a4)

URLCache도 잘 작동되는지 확인하기 위해 셀마다 용량이 평균 2MB의 매우 큰 이미지를 로딩하도록 구현해봤다. 결론은, NSCache는 잘 작동되는 반면 URLCache는 캐싱이 잘 되는데도 화면이 매우 버벅거렸다.

#### NSCache

NSCache는 용량이 큰 이미지들도 캐싱이 잘 되어 스크롤이 매끄럽다.

<img src="https://user-images.githubusercontent.com/52592748/130787527-ec399933-7ab7-4519-b0f2-019cab06d6d3.gif"/>


#### URLCache

<details>
<summary> <b> 구현 방법 </b>  </summary>
<div markdown="1">

### URLCache 용량 키우기

URLCache는 기본 용량이 크지 않기 때문에 용량이 큰 이미지들을 캐싱하고 싶으면 용량을 키워줘야 한다.
용량은 다음 방식으로 확인해볼 수 있다. (단위는 byte)

```swift
URLCache.shared.memoryCapacity
URLCache.shared.diskCapacity
// URLSession.shared.configuration.urlCache?.memoryCapacity
// URLSession.shared.configuration.urlCache?.diskCapacity
```

memoryCapacity와 diskCapacity를 넉넉하게 각각 500MB로 설정해줬다. 둘 다 크기를 키워주면 두 곳에 저장되고 한 곳만 키워주면 한 곳에만 저장된다. (memory는 메인메모리, disk는 하드디스크)
- 두 곳에 모두 저장할때나 한 곳에만 저장할 때나 속도 차이는 느끼지 못 했다.

```swift
URLCache.shared = {
    let cacheDirectory = (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as String).appendingFormat("/\(Bundle.main.bundleIdentifier ?? "cache")/" )

    return URLCache(memoryCapacity: 500*1024*1024,
                    diskCapacity: 500*1024*1024,
                    diskPath: cacheDirectory)
}()
```

AppDelegate.swift의 `application(_:didFinishLaunchingWithOptions:)`에서 해줬는데 다른데서 해줘도 별 상관은 없는 것 같다.

### URLCache 사용하기
다음 두 메서드로 request에 해당하는 response를 캐싱하고 꺼내왔다.
```swift
if let data = cache.cachedResponse(for: request)?.data {}
self.cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
```
  
![image](https://user-images.githubusercontent.com/52592748/130792567-bd20c890-b4d8-46c2-b314-3c87bac6de8a.png)

- 실제 적용한 코드

```swift
class ImageLoader {
    
    static let shared = ImageLoader()
    var cache = URLCache.shared
    
    private init() {}
    
    func loadImage(from urlString: String,
                   completion: @escaping (UIImage) -> Void) {
        
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        if let data = cache.cachedResponse(for: request)?.data,
           let imageData = UIImage(data: data) {
            DispatchQueue.main.async {
                completion(imageData)
            }
        } else {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil else { return }
                guard let response = response,
                      let statusCode = (response as? HTTPURLResponse)?.statusCode,
                      (200...299).contains(statusCode) else { return }
                guard let data = data else { return }
                
                guard let imageData = UIImage(data: data) else { return }
                self.cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                DispatchQueue.main.async {
                    completion(imageData)
                }
            }.resume()
        }
    }
}
```

</div>
</details>
<br>

하지만 URLCache는 이미지 용량이 커지자 스크롤이 매우 버벅이고 일부 이미지는 다시 다운받는 것처럼 깜빡인다. 디버깅을 해보니 캐싱은 잘 되는 것을 두 가지로 확인할 수 있었다:
- 이미지들을 한 차례 다 로딩한 후에는 이미지들을 가져올 때 계속 캐시에서 빼내오는 코드가 실행됐다.
- 이미지가 캐싱될 때마다 사용되고 있는 캐시의 용량이 늘어남을 확인했다.그리고 최종적으로 캐시된 용량을 확인해보니 실제 이미지들의 용량의 합인 31MB과 같았다.

  ![image](https://user-images.githubusercontent.com/52592748/130788590-c73166a7-e079-4841-bba0-4563fd2d1d9a.png)

캐싱이 잘 되는데도 버벅이는 문제가 발생하는 것으로 봐서 두 가지 문제가 의심됐다:
- 캐시에서 response를 꺼내올 때 오래 걸리지 않을까 의심됐다.
- NSCache는 value를 UIImage로 저장하는 반면 URLCache는 URLResponse 타입으로 저장하기 때문에 매번 response의 데이터를 UIImage로 변환하는 작업이 필요하다. UIImage로 변환하는 작업이 오래 걸리지 않을까 의심됐다.

URLCache는 request, response를 키값 형태로 저장하기 때문에 이미지 캐싱보다는 다른 용도로 사용하는 것이 아닐까 하는 생각도 들었다. 일단은 네트워크 통신용 캐시라고 생각해서 NSCache가 아닌 URLCache를 사용했지만 이미지가 너무 큰 경우 버벅이는 문제가 발생하기 때문에 URLCache를 정말 네트워크에서 받은 이미지 캐싱에 사용해도 되는지 더 알아볼 필요가 있을 것 같다. (작은 크기의 이미지들은 잘 캐싱된다.)

<img src="https://user-images.githubusercontent.com/52592748/130786012-d97761de-741b-43e3-b38e-ef1300700313.gif"/>

---

### Infinite scrolling
<img src="https://user-images.githubusercontent.com/52592748/130784840-30002440-a81e-47f3-830a-739efa933333.gif" width="300"/>

컬렉션 뷰는 컨텐츠에 cell을 추가하기 전에 `collectionView(_:willDisplay:forItemAt:)` 메서드를 호출한다. 

`isNotLoading` Bool타입 프로퍼티를 이용해 현재 추가적인 데이터를 더 로딩중인지 아닌지를 체크하고, `indexPath.row`가 전체 데이터보다 4개정도 적을 때 data를 추가로 fetch하도록 `loadMoreData()` 메서드를 구현했다.

---

### UIActivityIndicator

- 작업이 진행 중일때 보여줄 수 있는 뷰이다. UIKit에 들어 있다.
- `startAnimating()`으로 시작되게 할 수 있고, `stopAnimating()`으로 멈추게 할 수 있다. 
- `hideWhenStopped` 프로퍼티를 `true`로 설정하면 통해 멈췄을 때 숨겨지도록 할 수 있다.

스토리보드에서 Activity Indicator View를 추가하고 IBOutlet으로 View contoller와 연결했다. 앱을 처음 실행하자마자 컬렉션 뷰를 로딩하기 위해 기다려야 하므로 스토리보드에서 Attributes inspector - Behavior의 Animating을 체크해주었다.

![image](https://user-images.githubusercontent.com/52592748/130813203-fd745b8b-90a2-4663-90a8-eab8ca38f491.png)

Indicator가 사라지는 시점은 data의 첫번째 로딩이 완료된 시점이라고 생각했다. Data가 fetch 된 후 collection view를 `reloadData()`하고 `stopAnimating()` 을 호출했다.

---

### NumberFormatter currency
이번 프로젝트에서 화폐 단위를 ISO4217 코드로 표기했다. 달러는 USD, 원화는 KRW 코드로 표기하는 것이다. NumberFormatter에 ISO4217 코드를 지정하면 numberStyle에 따라 코드가 출력되기도 하고 심볼이 출력되기도 했다.

- currencyCode를 원화를 나타내는 KRW 코드로 지정

```swift
let numberFormatter = NumberFormatter()
numberFormatter.currencyCode = "KRW"
```

#### numberStyle `.currencyISOCode`
금액 앞에 `KRW` 이 붙는다. 알아서 decimal 스타일이 적용된다

```swift
numberFormatter.numberStyle = .currencyISOCode
let a = numberFormatter.string(from: 1234567)
// KRW 1,234,567
```

#### numberStyle `.currency`
금액 앞에 `₩` 심볼이 붙는다. 알아서 decimal 스타일이 적용된다
```swift
numberFormatter.numberStyle = .currency
let b = numberFormatter.string(for: 1234567)
// ₩1,234,567
```

---

### NSAttributedString

- 텍스트 일부에 대한 관련 속성(예: 스타일, 하이퍼링크, 접근성 데이터 등)이 있는 문자열이다.
- 이 객체는 개별 문자열 또는 문자열의 범위에 적용되는 속성(예: 글꼴, 커닝)에 관한 세트를 관리한다.

#### NSAttributedString.Key
속성 문자열의 텍스트에 적용할 수 있는 속성이다.
attachment, backroundColor, font, forgroundColor, shadow 등의 프로퍼티를 갖고 있다.


```swift
let attributes: [NSAttributedString.Key: Any] = [
    .foregroundColor: UIColor.red,
    .strikethroughStyle: true
]

self.label.attributedText = NSAttributedString(string: "Hello", attributes: attributes)

```
위의 코드는 label에 Hello 문자열을 넣고, 빨간색의 취소선이 그어져 있는 attributedText를 적용한다.

---

### isHidden

- 뷰가 숨겨져 있는지 여부를 결정하는 Bool 값이다.
- true로 설정하면 receiver가 숨겨지고, false로 설정하면 receiver가 표시된다. 기본값은 false이다.
- 숨겨진 view는 window에서 사라지고 입력 이벤트를 수신하지 않는다. 하지만 superview의 subview목록에 남아있고, 오토리사이징에 관여한다.
- 숨겨지면 자손 하위뷰들도 숨기는 효과가 있다.

코드에 적용하면서 `discountedPrice` 값이 nil이면 해당 UILabel을 숨겨야 했다. stack view를 이용해 label들을 배치해놓고 `discountedPriceLabel`의 `isHidden`을 true로 바꾸니 text만 사라지는 것이 아니라 view가 완전히 사라진 것을 볼 수 있었다.

![image](https://user-images.githubusercontent.com/52592748/130813360-29169f35-efb5-47e1-b043-553951fc7a3b.png)

스토리보드

![image](https://user-images.githubusercontent.com/52592748/130813387-390b4aeb-2753-4bd3-a885-02c3b7b22c40.png)

실제 데이터 반영
