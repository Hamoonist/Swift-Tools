//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

extension Binding {
    @inlinable
    public static func receiveValue<Wrapped>(_ receiveValue: @escaping (Wrapped?) -> ()) -> Binding where Optional<Wrapped> == Value {
        .init(
            get: { nil },
            set: receiveValue
        )
    }
}

extension Binding {
    @inlinable
    public func forceCast<U>(to type: U.Type) -> Binding<U> {
        return .init(
            get: { self.wrappedValue as! U },
            set: { self.wrappedValue = $0 as! Value }
        )
    }
    
    @inlinable
    public func withDefaultValue<T>(_ defaultValue: T) -> Binding<T> where Value == Optional<T> {
        return .init(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

extension Binding {
    @inlinable
    public func beforeSet(_ body: @escaping (Value) -> ()) -> Self {
        return .init(
            get: { self.wrappedValue },
            set: { body($0); self.wrappedValue = $0 }
        )
    }
    
    @inlinable
    public func onSet(_ body: @escaping (Value) -> ()) -> Self {
        return .init(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0; body($0) }
        )
    }
}

extension Binding {
    @inlinable
    public func isNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        .init(
            get: { self.wrappedValue == nil },
            set: { isNil in self.wrappedValue = isNil ? nil : self.wrappedValue  }
        )
    }

    @inlinable
    public func isNotNil<Wrapped>() -> Binding<Bool> where Optional<Wrapped> == Value {
        .init(
            get: { self.wrappedValue != nil },
            set: { isNotNil in self.wrappedValue = isNotNil ? self.wrappedValue : nil  }
        )
    }
}

extension Binding where Value == Bool {
    @inlinable
    public static func && (lhs: Binding, rhs: Bool) -> Binding {
        .init(
            get: { lhs.wrappedValue && rhs },
            set: { lhs.wrappedValue = $0 }
        )
    }
}

extension Binding where Value == Bool? {
    @inlinable
    public static func && (lhs: Binding, rhs: Bool) -> Binding {
        .init(
            get: { lhs.wrappedValue.map({ $0 && rhs }) },
            set: { lhs.wrappedValue = $0 }
        )
    }
}

extension Binding where Value == String {
    @inlinable
    public func takePrefix(_ count: Int) -> Self {
        .init(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                self.wrappedValue = .init($0.prefix(count))
            }
        )
    }
    
    @inlinable
    public func takeSuffix(_ count: Int) -> Self {
        .init(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                self.wrappedValue = .init($0.suffix(count))
            }
        )
    }
}

extension Binding where Value == String? {
    @inlinable
    public func takePrefix(_ count: Int) -> Self {
        .init(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                self.wrappedValue = $0.map({ .init($0.prefix(count)) })
            }
        )
    }
    
    @inlinable
    public func takeSuffix(_ count: Int) -> Self {
        .init(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                self.wrappedValue = $0.map({ .init($0.suffix(count)) })
            }
        )
    }
}
