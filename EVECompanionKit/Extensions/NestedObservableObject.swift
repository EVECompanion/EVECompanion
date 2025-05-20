//
//  NestedObservableObject.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 13.05.24.
//

public import Combine

@propertyWrapper
public struct NestedObservableObject<Value: ObservableObject> {
    
    public static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        
        get {
            if instance[keyPath: storageKeyPath].cancellable == nil, let publisher = instance.objectWillChange as? ObservableObjectPublisher {
                instance[keyPath: storageKeyPath].cancellable =
                    instance[keyPath: storageKeyPath].storage.objectWillChange
                        .receive(on: DispatchQueue.main)
                        .sink { _ in
                            publisher.send()
                    }
            }
            
            return instance[keyPath: storageKeyPath].storage
         }
         set {
             DispatchQueue.main.async {
                 if let cancellable = instance[keyPath: storageKeyPath].cancellable {
                     cancellable.cancel()
                 }
                 if let publisher = instance.objectWillChange as? ObservableObjectPublisher {
                     instance[keyPath: storageKeyPath].cancellable =
                         newValue.objectWillChange.sink { _ in
                                 publisher.send()
                         }
                 }
                 instance[keyPath: storageKeyPath].storage = newValue
             }
         }
    }
    
    @available(*, unavailable,
        message: "This property wrapper can only be applied to classes"
    )
    public var wrappedValue: Value {
        get { fatalError("This property wrapper can only be applied to classes") }
        // swiftlint:disable:next unused_setter_value
        set { fatalError("This property wrapper can only be applied to classes") }
    }
    
    private var cancellable: AnyCancellable?
    private var storage: Value

    public init(wrappedValue: Value) {
        storage = wrappedValue
    }
}
