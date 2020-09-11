import XCTest
import Combine
import Foundation
@testable import Worker
//An example worker
public extension Worker {
    static func Add(value constant:Int) -> Worker<Int, Int> {
        Worker<Int, Int> { input in
            Just(input + constant)
            .eraseToAnyPublisher()
        }
    }

    static func GetFromHTTP<D:Codable>(type:D.Type) -> Worker<D, String>{

        Worker<D, String> { input in

            let url : String = "https://httpbin.org/post"
            var request : URLRequest = URLRequest(url: URL(string:url)!)
            request.httpMethod = "POST"
            request.httpBody = try? JSONEncoder().encode(input)
            return URLSession.shared.dataTaskPublisher(for: request)
                .map { $0.data }
                .replaceError(with: Data())
                .flatMap{Just(String(bytes:$0, encoding: .utf8) ?? "")}
                .eraseToAnyPublisher()
        }
    }
}

final class WorkerTests: XCTestCase {
    
    func testDeliverWorkFlow() {

        let e = XCTestExpectation(description: "Value delivered")

        //Given an input
        let input = 70
        let constant = 30
        let expected = 100

        //We'll make an adder worker that adds
        //30 to all input values of type int
        var adder:Worker = .Add(value:constant)

        //We will handle the finished work like so
        adder.deliver { value in

            print("got:", value)
            XCTAssert(value == expected)
            print("expected:", expected)

            adder.close()
            e.fulfill()
        }

        print("input:", input)
        adder.run(input)
        wait(for: [e], timeout: 1.0)
        let allWork = Workers.allWork()
        XCTAssert(allWork.count == 0)

    }

    struct Foo:Codable {
        var bar:String
        var baz:String
    }
    func testRequestWorkFlow() {
        let e = XCTestExpectation(description: "Value delivered")

        //Given an input
        let input = Foo(bar: "He", baz: "Wo")


        var httpWorker:Worker = .GetFromHTTP(type:Foo.self)

        httpWorker.deliver { value in
            print(value)
            XCTAssert(value.count != 0)
            e.fulfill()
        }
        print("input:", input)
        httpWorker.run(input)
        wait(for: [e], timeout: 20.0)
        httpWorker.close()
        let allWork = Workers.allWork()
        XCTAssert(allWork.count == 0)

    }

    static var allTests = [
        ("testDeliverWorkFlow", testDeliverWorkFlow),
        ("testRequestWorkFlow", testRequestWorkFlow),
    ]
}
