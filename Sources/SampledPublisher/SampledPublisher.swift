
import Combine

extension Publisher {

    /// Sample this publisher's output when the given publisher sends or completes.
    ///
    /// This example shows how to sample the value from a "temperature publisher" every
    /// 60 seconds.
    /// The temperature sensor may send many values while the timer sends one value
    /// exectly every 60 seconds. By sampling the timer, the resulting Publisher
    /// emits the most recent temperature measurement every 60 seconds.
    ///
    /// Note that a value is not sampled twice.
    ///
    /// If the temperature sensor does not emit a value during for a complete minute,
    /// no value is send by the sampled publisher.
    ///
    /// ```
    ///     let timer = Timer.publish(every: 60, on: RunLoop.main, in: .default)
    ///     temperature
    ///         .sample(timer)
    ///         .sink { temperature in print("The temperature is \(temperature)" }
    /// ```
    /// 
    public func sample<P>(_ sampler: P) -> SampledPublisher<Self, P> {
        SampledPublisher(upstream: self, sampler: sampler)
    }
}

public class SampledPublisher<Upstream, Sampler>
where Upstream: Publisher, Sampler: Publisher {

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
    where S : Subscriber,
          Upstream.Failure == S.Failure,
          Upstream.Output == S.Input
    {
        let samplerSubscriber = SamplerSubscriber<Sampler.Output, Sampler.Failure>()

        let subscription = Subscription(
            subscriber: subscriber,
            samplerSubscriber: samplerSubscriber)

        subscriber.receive(subscription: subscription)
        upstream.receive(subscriber: subscription)
        sampler.receive(subscriber: samplerSubscriber)
    }
}

extension SampledPublisher {
    final class Subscription<Downstream, SamplerOutput, SamplerFailure>
    where Downstream: Subscriber,
          Downstream.Input == Output,
          Downstream.Failure == Failure,
          SamplerFailure: Error
    {
        private var subscriber: Downstream?
        private var samplerSubscriber: SamplerSubscriber<SamplerOutput, SamplerFailure>?

        private var lastValue: Output?
        private var demand: Subscribers.Demand = .none

        init(
            subscriber: Downstream,
            samplerSubscriber: SamplerSubscriber<SamplerOutput, SamplerFailure>
        ) {
            self.subscriber = subscriber
            self.samplerSubscriber = samplerSubscriber

            samplerSubscriber.onReceive = { [weak self] in
                self?.sample()
            }
        }

        func sample() {
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
        samplerSubscriber = nil
    }
}

extension SampledPublisher.Subscription: Subscriber {
    typealias Input = Downstream.Input
    typealias Failure = Downstream.Failure

    func receive(subscription: Subscription) {
        subscription.request(demand)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        // Receive input from the Publisher that is being sampled
        // Great place for a breakpoint when debugging

        lastValue = input
        return demand
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        subscriber?.receive(completion: completion)
    }
}


extension SampledPublisher {
    final class SamplerSubscriber<Input, Failure>: Subscriber where Failure: Error {

        var onReceive: (() -> ())?

        func receive(subscription: Combine.Subscription) {
            subscription.request(.unlimited)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            onReceive?()
            return .unlimited
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            onReceive?()
        }
    }
}
