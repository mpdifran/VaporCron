import Foundation
import Vapor
import NIOCronScheduler

public struct VaporCron {
    let application: Application
    
    init(application: Application) {
        self.application = application
    }
    
    @discardableResult
    public func schedule<T: VaporCronSchedulable>(_ job: T.Type) throws -> NIOCronJob {
        return try schedule(job.expression) { (application, eventLoop) in
            job.task(on: self.application, eventLoop: eventLoop)
        }
    }
    
    @discardableResult
    public func schedule(_ job: NIOCronSchedulable.Type) throws -> NIOCronJob {
        return try schedule(job.expression) { job.task() }
    }
    
    @discardableResult
    public func schedule(_ expression: String, _ task: @escaping () throws -> Void) throws -> NIOCronJob {
        return try NIOCronScheduler.schedule(expression, on: application.eventLoopGroup.next(), task)
    }
    
    @discardableResult
    public func schedule(_ expression: String, _ task: @escaping (Application, EventLoop) throws -> Void) throws -> NIOCronJob {
        let eventLoop = application.eventLoopGroup.next()
        return try NIOCronScheduler.schedule(expression, on: eventLoop, { try task(self.application, eventLoop) })
    }
}

extension Application {
    public var cron: VaporCron {
        .init(application: self)
    }
}

extension Request {
    public var cron: VaporCron {
        .init(application: application)
    }
}

public protocol VaporCronSchedulable: NIOCronExpressable {
    associatedtype T
    
    @discardableResult
    static func task(on application: Application, eventLoop: EventLoop) -> EventLoopFuture<T>
}
