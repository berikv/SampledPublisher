import XCTest
import Combine
import SampledPublisher

final class SampledPublisherTests: XCTestCase {
    func test_sampleIgnoredWithNoValue() {
        let subject = PassthroughSubject<Int, Never>()
        let samplerSubject = PassthroughSubject<Void, Never>()
        let sampled = subject.sample(samplerSubject)

        var recieved: Int?
        let cancellation = sampled
            .sink {
                value in recieved = value
            }

        samplerSubject.send()
        XCTAssertNil(recieved)
        subject.send(1)
        XCTAssertNil(recieved)
        _ = cancellation
    }

    func test_ignoreNonSampledValue() {
        let subject = PassthroughSubject<Int, Never>()
        let samplerSubject = PassthroughSubject<Void, Never>()
        let sampled = subject.sample(samplerSubject)

        var recieved: Int?
        let cancellation = sampled
            .sink {
                value in recieved = value
            }

        subject.send(1)
        XCTAssertNil(recieved)
        _ = cancellation
    }

    func test_sampleMostRecentValue() {
        let subject = PassthroughSubject<Int, Never>()
        let samplerSubject = PassthroughSubject<Void, Never>()
        let sampled = subject.sample(samplerSubject)

        var recieved: Int?
        let cancellation = sampled
            .sink {
                value in recieved = value
            }

        subject.send(1)
        subject.send(2)
        XCTAssertNil(recieved)
        samplerSubject.send()
        XCTAssertEqual(recieved, 2)
        _ = cancellation
    }

    func test_sampleOnComplete() {
        let subject = PassthroughSubject<Int, Never>()
        let samplerSubject = PassthroughSubject<Void, Never>()
        let sampled = subject.sample(samplerSubject)

        var recieved: Int?
        let cancellation = sampled
            .sink {
                value in recieved = value
            }

        subject.send(1)
        XCTAssertNil(recieved)
        samplerSubject.send()
        XCTAssertEqual(recieved, 1)
        _ = cancellation
    }
}
