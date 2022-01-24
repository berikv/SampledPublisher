
import Combine

public class SampledPublisher<Upstream, Sampler>
where Upstream: Publisher, Sampler: Publisher, Upstream.Failure == Sampler.Failure {

    let upstream: Upstream
    let sampler: Sampler

    public init(upstream: Upstream, sampler: Sampler) {
        self.upstream = upstream
        self.sampler = sampler
    }
}

extension SampledPublisher: Publisher {
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    public func receive<S>(subscriber: S)
    where S : Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
        let subscription = Subscription<S, Sampler.Output>(subscriber: subscriber)

        let samplerSubscriber = SamplerSubscriber<Sampler.Output, Failure> {
            subscription.trigger()
        }

        // storage
        subscription.samplerSubscriber = samplerSubscriber

        sampler.receive(subscriber: samplerSubscriber)

        subscriber.receive(subscription: subscription)
        upstream.receive(subscriber: subscription)
    }
}

extension SampledPublisher {
    final class Subscription<Downstream, SamplerOutput>
    where Downstream: Subscriber,
          Downstream.Input == Output,
          Downstream.Failure == Failure
    {
        private var subscriber: Downstream?
        private var lastValue: Output?
        private var demand: Subscribers.Demand = .none
        var samplerSubscriber: SamplerSubscriber<SamplerOutput, Failure>?

        init(subscriber: Downstream) {
            self.subscriber = subscriber
        }

        func trigger() {
            if let lastValue = lastValue {
                self.lastValue = nil
                demand = subscriber?.receive(lastValue) ?? .none
            }
        }
    }
}

extension SampledPublisher.Subscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
    }

    func cancel() {
        subscriber = nil
    }
}

extension SampledPublisher.Subscription: Subscriber {
    typealias Input = Downstream.Input
    typealias Failure = Downstream.Failure

    func receive(subscription: Subscription) {
        subscription.request(demand)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        lastValue = input
        return demand
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        subscriber?.receive(completion: completion)
    }
}


extension SampledPublisher {
    final class SamplerSubscriber<Input, Failure>: Subscriber where Failure: Error {

        private var demand: Subscribers.Demand = .unlimited
        private var trigger: () -> ()
        init(trigger: @escaping () -> ()) {
            self.trigger = trigger
        }

        func receive(subscription: Combine.Subscription) {
            subscription.request(demand)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            trigger()
            return .unlimited
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            trigger()
        }
    }
}

extension Publisher {
    public func sample<P>(_ sampler: P) -> SampledPublisher<Self, P> {
        SampledPublisher(upstream: self, sampler: sampler)
    }
}
