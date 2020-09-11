import Foundation
import Combine


public struct Worker<Input, Output> {

    private var inputSubject = PassthroughSubject<Input, Never>()
    private var tasks:Set<AnyCancellable> = []
    private var subject = PassthroughSubject<Output, Never>()
    lazy var output: AnyPublisher<Output, Never> = {self.subject.share().eraseToAnyPublisher()}()

    init(handler:@escaping (Input) -> AnyPublisher<Output, Never>) {
        let s = subject
        inputSubject.flatMap(handler)
            .sink { (out) in
                s.send(out)
        }
        .store(in: &tasks)

    }
    ///Adds work to the pipeline and sends it out via the output publisher
    ///or the deliver handler.
    public func run(_ input:Input) {


        inputSubject.send(input)
    }

    ///Creates a handler to deliver output to
    ///
    public mutating func deliver(handler: @escaping (Output) -> Void) {
        let task = output
            .sink(receiveValue: handler)
        Workers.work.insert(task)
        tasks.insert(task)

    }
    public mutating func close() {
        Workers.work.subtract(tasks)
        tasks = []
    }
    


}
class Workers {
    static var work:Set<AnyCancellable> = []

    static func cancelAll() {
        work = []
    }
    static func allWork() -> Set<AnyCancellable> {
        work
    }
    
}


