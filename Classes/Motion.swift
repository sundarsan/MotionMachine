//
//  Motion.swift
//  MotionMachine
//
//  Created by Brett Walker on 4/19/16.
//  Copyright © 2016 Poet & Mountain, LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public typealias MotionUpdateClosure = (motion: Motion) -> Void

/**
 *  This notification closure should be called when the `start` method starts a motion operation. If a delay has been specified, this closure is called after the delay is complete.
 *
 *  - seealso: start
 */
public typealias MotionStarted = MotionUpdateClosure

/**
 *  This notification closure should be called when the `stop` method starts a motion operation.
 *
 *  - seealso: stop
 */
public typealias MotionStopped = MotionUpdateClosure


/**
 *  This notification closure should be called when the `update(withTimeInterval:)` method is called while a `Moveable` object is currently moving.
 *
 *  - seealso: update(withTimeInterval:)
 */
public typealias MotionUpdated = MotionUpdateClosure


/**
 *  This notification closure should be called when a motion operation reverses its movement direction.
 *
 */
public typealias MotionReversed = MotionUpdateClosure

/**
 *  This notification closure should be called when a motion has started a new motion cycle.
 *
 */
public typealias MotionRepeated = MotionUpdateClosure

/**
 *  This notification closure should be called when calling the `pause` method pauses a motion operation.
 *
 */
public typealias MotionPaused = MotionUpdateClosure

/**
 *  This notification closure should be called when calling the `resume` method resumes a motion operation.
 *
 */
public typealias MotionResumed = MotionUpdateClosure

/**
 *  This notification closure should be called when a motion operation has fully completed.
 *
 *  - remark: This closure should only be executed when all activity related to the motion has ceased. For instance, if a Moveable class allows a motion to be repeated multiple times, this closure should be called when all repetitions have finished.
 *
 */
public typealias MotionCompleted = MotionUpdateClosure


/**
 *  Motion handles a single motion operation on one or more properties, interpolating between specified starting and ending values.
 */
public class Motion: Moveable, Additive, TempoDriven, PropertyDataDelegate {
    
    // MARK: - Public Properties
    
    ///-------------------------------------
    /// Setting Up a Motion
    ///-------------------------------------
    
    /**
     *  The delay, in seconds, before a motion operation begins.
     *
     *  - warning: Setting this parameter after a motion operation has begun has no effect.
     */
    public var delay: NSTimeInterval = 0.0
    
    /**
     *  The duration of a motion operation, in seconds, as it moves from its starting property values to its ending values. (read-only)
     *
     *  - remark: If the `Motion` is `reversing` or `repeating`, the total duration will be increased by multiples of this duration. If `reversing` is set to `true`, the duration of a total motion cycle will be twice this amount as there will be two separate movements (forwards and back).
     *
     *  - warning: Do not set this parameter while a motion operation is in progress.
     */
    public var duration: NSTimeInterval = 0.0
    
    /**
     *  A Boolean which determines whether a motion operation should repeat. When set to `true`, the motion operation repeats for the number of times specified by the `repeatCycles` property. The default value is `false`.
     *
     *  - note: By design, setting this value to `true` without changing the `repeatCycles` property from its default value will cause the motion to repeat infinitely.
     *  - seealso: repeatCycles
     */
    public var repeating: Bool = false
    
    
    /**
     *  The number of motion cycle operations to repeat.
     *
     *  - remark: This property is only used when `repeating` is set to `true`. Assigning `REPEAT_INFINITE` to this property signals an infinite amount of motion cycle repetitions. The default value is `REPEAT_INFINITE`.
     *
     *  - seealso: repeating
     */
    public var repeatCycles: UInt = REPEAT_INFINITE
    
    
    
    /**
     *  An object conforming to the `ValueAssistant` protocol which acts as an interface for retrieving and updating value types.
     *
     *  - remark: By default, Motion will assign an instance of the `ValueAssistantGroup` class with value assistants for CoreFoundation structs and some color classes (CIColor, and UIColor for platforms which support it). You may add your own custom type assistants to this group, or replace it with your own custom `ValueAssistant` implementation.
     */
    public var valueAssistant: ValueAssistant = ValueAssistantGroup(assistants: [CGStructAssistant()]) {
        didSet {
            valueAssistant.additive = _additive
            valueAssistant.additiveWeighting = additiveWeighting
        }
    }
    
    
    
    // MARK: Additive protocol properties

    
    /**
     *  A Boolean which determines whether this Motion should change its object values additively. Additive animation allows multiple motions to produce a compound effect, creating smooth transitions and blends between different ending value targets. Additive animation is the default behavior for UIKit animations as of iOS 8 and is great for making user interface animations fluid and responsive. MotionMachine uses its own implementation of additive movement, so you can use additive motions on any supported object properties.
     *
     *   By default, each Motion will apply a strong influence on the movement of a property towards its ending value. This means that two Motion objects with the same duration and moving the same object property to different ending values will fight, and the "winning" value will be the last Motion to start its movement. If the durations or starting times are different, a transition between the values will occur. This transition occurs because the most recent additive Motion will assign the ending value of the last additive Motion as its starting position. If you wish to create additive motions that apply weighted value updates, you can adjust the `additiveWeighting` property. Setting values to that property that are less than 1.0 will create composite additive motions that are blends of each Motion object's ending values.
     *
     *  - remark: The `start` value of `PropertyData` objects are ignored for additive animations, and will instead combine with the current value of the properties being moved.
     *
     *  - warning: Please be aware that because of the composite nature of additive movements, values can temporarily move past a `PropertyData`'s specified `end` value. This can have unintended consequences if the property value you are moving is clamped to a limited range. Also note that additive movements may not work well with compound motions that are comprised of sequences, reversing, or repeating, and will not behave correctly when other Motion objects moving the same properties are not using the additive mode. Because of these caveats, the default value is `false`.
     *
     *  - seealso: additiveWeighting
     *
     */
    public var additive: Bool {
        get {
            return _additive
        }
        
        set(newValue) {
            _additive = newValue
            valueAssistant.additive = additive
        }

    }
    private var _additive: Bool = false
    
    /**
     *  A weighting between 0.0 and 1.0 which is applied to this Motion's object value updates when it is using an additive movement. The higher the weighting amount, the more its additive updates apply to the properties being moved. A value of 1.0 will mean the motion will reach the specific `end` value of each `PropertyData` being moved, while a value of 0.0 will not move towards the `end` value at all. When multiple Motions in `additive` mode are moving the same object properties, adjusting this weighting on each Motion can create complex composite motions.
     *
     *  - note: This value only has an effect when `additive` is set to `true`. The default value is 1.0.
     *  - seealso: additive
     */
    public var additiveWeighting: Double = 1.0 {
        didSet {
            // constrain weighting to range of 0.0 - 1.0
            additiveWeighting = max(min(additiveWeighting, 1.0), 0.0)
            valueAssistant.additiveWeighting = additiveWeighting
        }
    }
    

    
    /**
     *  An operation ID is assigned to a Motion instance when it is moving an object's property and its motion operation is currently in progress. (read-only)
     *
     *  - remark: This value returns 0 if no ID is currently assigned.
     */
    private(set) public var operationID: UInt = 0
    
    
    // MARK: PropertyCollection methods
    
    /**
     *  The collection of `PropertyData` instances, representing the object's properties being moved.
     *
     *  - remark: The `path` property of each `PropertyData` must be a valid KVC-compliant keyPath of `targetObject`.
     *  - seealso: targetObject
     */
    private(set) public var properties: [PropertyData] = []
    



    
    // MARK: Easing update closures
    
    /**
     *  A `EasingUpdateClosure` closure which performs easing calculations for the motion operation.
     *
     *  - note: By default, Motion will use `EasingLinear.easeNone()` for its easing equation if no easing closure is assigned.
     *  - seealso: reverseEasingBlock
     */
    public var easing: EasingUpdateClosure
    
    
    /**
     *  An optional `EasingUpdateClosure` closure which performs easing calculations for a motion operation that is reversing.
     *
     *  - remark: If not set, the easing closure defined by the `easing` property is used while reversing.
     *
     *  - seealso: easingBlock
     */
    public var reverseEasing: EasingUpdateClosure?
    
    
    // MARK: Motion state properties
    
    /// The target object whose property should be moved.
    private(set) public var targetObject: NSObject?
    
    /// A `MotionState` enum which represents the current state of the motion operation. (read-only)
    private(set) public var motionState: MotionState
    
    /// A `MotionDirection` enum which represents the current direction of the motion operation. (read-only)
    private(set) public var motionDirection: MotionDirection

    /**
     *  A value between 0.0 and 1.0, which represents the current progress of a movement between two value destinations. (read-only)
     *
     *  - remark: Be aware that if this motion is `reversing` or `repeating`, this value will only represent one movement. For instance, if a Motion has been set to repeat once, this value will move from 0.0 to 1.0, then reset to 0.0 again as the new repeat cycle starts. Similarly, if a Motion is set to reverse, this progress will represent each movement; first in the forward direction, then again when reversing back to the starting values.
     */
    private(set) public var motionProgress: Double {
        
        get {
            return _motionProgress
        }
        
        set(newValue) {
            _motionProgress = newValue
            
            // sync cycleProgress with motionProgress so that cycleProgress always represents total cycle progress
            if (reversing && motionDirection == .Forward) {
                _cycleProgress = _motionProgress * 0.5
            } else if (reversing && motionDirection == .Reverse) {
                _cycleProgress = (_motionProgress * 0.5) + 0.5
            } else {
                _cycleProgress = _motionProgress
            }


        }

    }
    private var _motionProgress: Double = 0.0

    
    /**
     *  A value between 0.0 and 1.0, which represents the current progress of a motion cycle. (read-only)
     *
     *  - remark: A cycle represents the total length of a one motion operation. If `reversing` is set to `true`, a cycle comprises two separate movements (the forward movement, which at completion will have a value of 0.5, and the movement in reverse which at completion will have a value of 1.0); otherwise a cycle is the length of one movement. Note that if `repeating`, each repetition will be a new cycle and thus the progress will reset to 0.0 for each repeat.
     */
    private(set) public var cycleProgress: Double {
        get {
            return _cycleProgress
        }
        
        set(newValue) {
            _cycleProgress = newValue
            
            // sync motionProgress with cycleProgress, so we modify the ivar directly (otherwise we'd enter a recursive loop as each setter is called)
            if (reversing) {
                var new_progress = _cycleProgress * 2
                if (_cycleProgress >= 0.5) { new_progress -= 1 }
                _motionProgress = new_progress
            
            } else {
                _motionProgress = _cycleProgress
            }
            
        }
    }
    private var _cycleProgress: Double = 0.0

    
    /**
     *  The amount of completed motion cycles.  (read-only)
     *
     * - remark: A cycle represents the total length of a one motion operation. If `reversing` is set to `true`, a cycle comprises two separate movements (the forward movement and the movement in reverse); otherwise a cycle is the length of one movement. Note that if `repeating`, each repetition will be a new cycle.
     */
    private(set) public var cyclesCompletedCount: UInt = 0
    
    
    /**
     *  A value between 0.0 and 1.0, which represents the current overall progress of the Motion. This value should include all reversing and repeat motion cycles. (read-only)
     *
     *  - remark: If a Motion is not repeating, this value will be equivalent to the value of `cycleProgress`.
     *  - seealso: cycleProgress
     *
     */
    public var totalProgress: Double {
        get {
            // sync totalProgress with cycleProgress
            if (repeating && repeatCycles > 0 && cyclesCompletedCount < (repeatCycles+1)) {
                return (_cycleProgress + Double(cyclesCompletedCount)) / Double(repeatCycles+1)
            } else {
                return _cycleProgress
            }
        }

    }

    
    
    // MARK: Moveable protocol properties
    
    /// A Boolean which determines whether a motion operation, when it has moved to the ending value, should move from the ending value back to the starting value.
    public var reversing: Bool = false
    
    /// Provides a delegate for updates to a Moveable object's status, used by `Moveable` collections.
    public var updateDelegate: MotionUpdateDelegate?
    
    
    
    // MARK: TempoDriven protocol properties
    
    /**
     *  A concrete `Tempo` subclass that provides an update "beat" while a motion operation occurs.
     *
     *  - remark: By default, Motion will assign an instance of `CATempo` to this property, which uses `CADisplayLink` for interval updates.
     */
    public var tempo: Tempo? {
        
        get {
            return _tempo
        }
        
        set(newValue) {
            if _tempo != nil {
                _tempo?.delegate = nil
                _tempo = nil
            }
            
            _tempo = newValue
            _tempo?.delegate = self
            
        }
    }
    lazy private var _tempo: Tempo? = {
        return CATempo.init()
    }()
    
    
    
    // MARK: - Notification closures
    
    /**
     *  This closure is called when a motion operation starts.
     *
     *  - remark: This method can be chained when initializing the object.
     *
     *  - seealso: start
     */
    public func started(closure: MotionStarted) -> Self {
        _started = closure
        
        return self
    }
    private var _started: MotionStarted?
    
    /**
     *  This closure is called when a motion operation is stopped by calling the `stop` method.
     *
     *  - remark: This method can be chained when initializing the object.
     *
     *  - seealso: stop
     */
    public func stopped(closure: MotionStopped) -> Self {
        _stopped = closure
        
        return self
    }
    private var _stopped: MotionStopped?
    
    /**
     *  This closure is called when a motion operation update occurs and this instance's `motionState` is `.Moving`.
     *
     *  - remark: This method can be chained when initializing the object.
     *
     *  - seealso: update(withTimeInterval:)
     */
    public func updated(closure: MotionUpdated) -> Self {
        _updated = closure
        
        return self
    }
    private var _updated: MotionUpdated?
    
    /**
     *  This closure is called when a motion cycle has repeated.
     *
     *  - remark: This method can be chained when initializing the object.
     *
     *  - seealso: repeating, cyclesCompletedCount
     */
    public func cycleRepeated(closure: MotionRepeated) -> Self {
        _cycleRepeated = closure
        
        return self
    }
    private var _cycleRepeated: MotionRepeated?
    
    /**
     *  This closure is called when the `motionDirection` property changes to `.Reversing`.
     *
     *  - remark: This method can be chained when initializing the object.
     *
     *  - seealso: motionDirection, reversing
     */
    public func reversed(closure: MotionReversed) -> Self {
        _reversed = closure
        
        return self
    }
    private var _reversed: MotionReversed?
    
    /**
     *  This closure is called when calling the `pause` method on this instance causes a motion operation to pause.
     *
     *  - remark: This method can be chained when initializing the object.
     *
     *  - seealso: pause
     */
    public func paused(closure: MotionPaused) -> Self {
        _paused = closure
        
        return self
    }
    private var _paused: MotionPaused?
    
    /**
     *  This closure is called when calling the `resume` method on this instance causes a motion operation to resume.
     *
     *  - remark: This method can be chained when initializing the object.
     *
     *  - seealso: resume
     */
    public func resumed(closure: MotionResumed) -> Self {
        _resumed = closure
        
        return self
    }
    private var _resumed: MotionResumed?
    
    /**
     *  This closure is called when a motion operation has completed (or when all motion cycles have completed, if `repeating` is set to `true`).
     *
     *  - remark: This method can be chained when initializing the object.
     */
    public func completed(closure: MotionCompleted) -> Self {
        _completed = closure
        
        return self
    }
    private var _completed: MotionCompleted?
    


    // MARK: - Private Properties
    
    /// The starting time of the current motion operation. A value of 0.0 means that the motion is not in progress.
    private var startTime: NSTimeInterval = 0.0
    
    /// The most recent update timestamp sent to the `update` method.
    private var currentTime: NSTimeInterval = 0.0
    
    /// The ending time of the motion, which is determined by adding the motion's duration to the starting time.
    private var endTime: NSTimeInterval = 0.0
    
    /// Boolean value representing whether the object of the property should be reset when we repeat or restart the motion.
    private var resetObjectStateOnRepeat: Bool = false
    
    /**
     *  Tracks the number of completed motions. Not incremented when repeating.
     *
     *  - note: Currently this property only exists in order to avoid Motions not moving when a `MotionSequence` they're being controlled by, whose `reversingMode` is set to `.Sequential`, reverses direction. Without checking this property in the `assignStartingPropertyValue` method, `PropertyData` objects with `useExistingStartValue` set to `true` (which occurs whenever a `PropertyData` is created without an explicit `start` value) would end up with their `start` and `end` values being equal, and thus no movement would occur. (whew)
     */
    private var completedCount: UInt = 0
    
    /// Timestamp set the `pause` method is called; used to track the amount of time paused.
    private var pauseTimestamp: NSTimeInterval = 0.0
    
    
    
    // MARK: - Initialization

    /**
     *  Initializer.
     *
     *  - parameters:
     *      - target: The target object whose properties should be modified.
     *      - properties: An array of `PropertyData` objects that provide instructions for which properties to modify and how.
     *      - duration: The length of the motion, in seconds.
     *      - easing: An optional `EasingUpdateClosure` easing equation to use when moving the values of the given properties. `EasingLinear.easeNone()` is the default equation if none is provided.
     *      - options: An optional set of `MotionsOptions`.
     */
    public convenience init(target targetObject: NSObject, properties: [PropertyData], duration: NSTimeInterval, easing: EasingUpdateClosure?=EasingLinear.easeNone(), options: MotionOptions?=MotionOptions.None) {
        
        self.init(target: targetObject, properties: properties, finalStates: nil, duration: duration, easing: easing, options: options)
        
    }
    
    /**
     *  Initializer.
     *
     *  - parameters:
     *      - target: The target object whose properties should be modified.
     *      - duration: The length of the motion, in seconds.
     *      - easing: An optional `EasingUpdateClosure` easing equation to use when moving the values of the given properties. `EasingLinear.easeNone()` is the default equation if none is provided.
     *      - options: An optional set of `MotionsOptions`.
     */
    public convenience init(target targetObject: NSObject, duration: NSTimeInterval, easing: EasingUpdateClosure?=EasingLinear.easeNone(), options: MotionOptions?=MotionOptions.None) {
        
        self.init(target: targetObject, properties: [], finalStates: nil, duration: duration, easing: easing, options: options)
    }
    
    /**
     *  Initializer.
     *
     *  - parameters:
     *      - target: The target object whose properties should be modified.
     *      - finalState: A Dictionary of template objects, with keys representing property keypaths (relative to the target object), and values that represent their final states. These final states must be of the same object type as the property located at the keypath.
     *      - duration: The length of the motion, in seconds.
     *      - easing: An optional `EasingUpdateClosure` easing equation to use when moving the values of the given properties. `EasingLinear.easeNone()` is the default equation if none is provided.
     *      - options: An optional set of `MotionsOptions`.
     */
    public convenience init(target targetObject: NSObject, finalState templateObjects: [String:Any], duration: NSTimeInterval, easing: EasingUpdateClosure?=EasingLinear.easeNone(), options: MotionOptions?=MotionOptions.None) {
        
        self.init(target: targetObject, properties: nil, finalStates: templateObjects, duration: duration, easing: easing, options: options)
    }
    
    
    private init(target targetObject: NSObject, properties props: [PropertyData]?, finalStates: [String:Any]?, duration: NSTimeInterval, easing: EasingUpdateClosure?, options: MotionOptions?) {
        
        var properties = props ?? []
        
        self.targetObject = targetObject
        
        self.duration = (duration > 0.0) ? duration : 0.0 // if value passed is negative, clamp it to 0
        
        self.easing = easing!
        reverseEasing = self.easing
        
        #if os(iOS) || os(tvOS)
            if let assistant_group = valueAssistant as? ValueAssistantGroup {
                assistant_group.add(UIColorAssistant())
                assistant_group.add(CIColorAssistant())
                assistant_group.add(UIKitStructAssistant())
            }
        #endif
        
        // unpack options values
        repeating = options!.contains(.Repeat)
        reversing = options!.contains(.Reverse)
        resetObjectStateOnRepeat = options!.contains(.ResetStateOnRepeat)
        
        motionState = .Stopped
        motionDirection = .Forward
        
        _tempo?.delegate = self
        
        if let final_object_states = finalStates {
            for (path, final_state) in final_object_states {
                var tobj: AnyObject = targetObject
                if (path != "" && valueAssistant.acceptsKeypath(targetObject)) {
                    if let tvalue = targetObject.valueForKeyPath(path) {
                        tobj = tvalue
                    }
                }
                
                if let val = CGStructAssistant.valueForCGStruct(final_state) {
                    do {
                        let generated = try valueAssistant.generateProperties(fromObject: val, keyPath: path, targetObject: tobj)
                        properties.appendContentsOf(generated)

                    } catch ValueAssistantError.TypeRequirement(let valueType) {
                        ValueAssistantError.TypeRequirement(valueType).printError(fromFunction: #function)

                    } catch {
                        // any other errors
                    }
                    
                } else {
                    do {
                        let generated = try valueAssistant.generateProperties(fromObject: (final_state as! AnyObject), keyPath: path, targetObject: tobj)
                        properties.appendContentsOf(generated)
                        
                    } catch ValueAssistantError.TypeRequirement(let valueType) {
                        ValueAssistantError.TypeRequirement(valueType).printError(fromFunction: #function)
                        
                    } catch {
                        // any other errors
                    }
                    
                }

            }
            
        }
        
        for property in properties {
            var prop_to_setup = property
            setup(forProperty: &prop_to_setup)
            prop_to_setup.delegate = self
            if (resetObjectStateOnRepeat) {
                prop_to_setup.startingParentProperty = prop_to_setup.target
            }

            self.properties.append(prop_to_setup)
        }
        
    }
    
    
    deinit {
        tempo?.delegate = nil
        
        for index in 0 ..< properties.count {
            properties[index].delegate = nil
        }
    }
    
    
    
    // MARK: - Public methods
    
    /**
     *  Adds a `PropertyData` to control an object's property. The PropertyData's `path` must reflect a property keyPath of the Motion's target object.
     *
     *  - parameter property: A `PropertyData` instance.
     *  - remark: This method can be chained when initializing the object.
     *  - warning: This method should not be called after the Motion has started.
     *  - returns: A reference to this Motion instance, for the purpose of chaining multiple calls to this method.
     */
    public func add(property: PropertyData) -> Motion {
        
        var prop = property
        setup(forProperty: &prop)
        prop.delegate = self
        if (resetObjectStateOnRepeat) {
            prop.startingParentProperty = prop.target
        }
        properties.append(prop)
        
        return self
    }
    
    /**
     *  Adds a delay before the motion operation will begin.
     *
     *  - parameter amount: The number of seconds to wait.
     *  - returns: A reference to this Motion instance, for the purpose of chaining multiple calls to this method.
     */
    public func afterDelay(amount: NSTimeInterval) -> Motion {
        
        delay = amount
        
        return self
        
    }
    
    /**
     *  Specifies that a motion cycle should repeat and the number of times it should do so. When no value is provided, the motion will repeat infinitely.
     *
     *  - remark: When this method is used there is no need to specify `.Repeat` in the `options` parameter of the init method.
     *
     *  - parameter numberOfCycles: The number of motion cycles to repeat. The default value is `REPEAT_INFINITE`.
     *  - returns: A reference to this Motion instance, for the purpose of chaining multiple calls to this method.
     *  - seealso: repeatCycles, repeating
     */
    public func repeats(numberOfCycles: UInt = REPEAT_INFINITE) -> Motion {
        
        repeatCycles = numberOfCycles
        repeating = true
        
        return self
    }
    
    
    /**
     *  Specifies that a motion, when it has moved to the ending value, should move from the ending value back to the starting value.
     *
     *  - remark: When this method is used there is no need to specify `.Reverse` in the `options` parameter of the init method.
     *
     *  - parameter easing: The easing equation to be used while reversing. When no equation is provided, the normal `easing` closure will be used in both movement directions.
     *  - returns: A reference to this Motion instance, for the purpose of chaining multiple calls to this method.
     *  - seealso: reversing, reverseEasing
     */
    public func reverses(withEasing easing: EasingUpdateClosure? = nil) -> Motion {
        
        reversing = true
        reverseEasing = easing
        
        return self
    }
    
    
    // MARK: - Private methods
    
    /**
     *  Initializes property metadata in preparation for a motion operation.
     *
     *  - parameter property: The `PropertyData` instance to modify.
     */
    private func setup(inout forProperty property: PropertyData) {
        
        guard let unwrapped_object = targetObject else { return }
        
        if (unwrapped_object is NSValue) {
            property.target = unwrapped_object
            property.parentKeyPath = property.path
            
            // modify start value if we should use the existing value instead
            assignStartingPropertyValue(&property)
            
            return
        }

        if (valueAssistant.acceptsKeypath(unwrapped_object)) {
            property.targetObject = unwrapped_object
        }
        
        // determine if target property is a value we can update directly, or if it's an element of a struct we need to replace
        property.parentKeyPath = property.path
        var keys: [String] = property.path.componentsSeparatedByString(".")
        let key_count = keys.count
        
        if (key_count > 1) {
            // there's more than one element in the path, meaning we have a parent, so let's find the prop type
            
            // descend keypath tree until we find a key in the path that isn't a struct or integer
            var parent_value: AnyObject?
            
            for (index, key) in keys.enumerate() {
                let parent_keys = keys[0 ... index]
                
                if (parent_keys.count > 0) {
                    let parent_path = parent_keys.joinWithSeparator(".")

                    if let parent = unwrapped_object.valueForKeyPath(parent_path) {
                        parent_value = parent
                        
                        var is_value_supported = false

                        if ((parent is NSObject) && (valueAssistant.updateValue(inObject: (parent as! NSObject), newValues: [property.path : 1]) != nil)) {
                            is_value_supported = true
                        }
                        
                        if (is_value_supported) {
                            // we found a path element that isn't numeric, so we'll need to save the path element below this one
                            
                            property.replaceParentProperty = true
                            property.parentKeyPath = parent_path
                            
                            property.getter = MotionSupport.propertyGetter(forName: key)
                            property.setter = MotionSupport.propertySetter(forName: key)
                            
                            break

                        }
                        
                    }
                    
                }
            }
            
            if (property.replaceParentProperty) {
                if let value = parent_value {
                    property.target = value
                }
                
            } else {
                let last_prop = keys.last!
                property.getter = MotionSupport.propertyGetter(forName: last_prop)
                property.setter = MotionSupport.propertySetter(forName: last_prop)
            }
            
            // modify start value if we should use the existing value instead
            assignStartingPropertyValue(&property)
            
        } else if (key_count == 1) {
            // this is a top-level property, so let's see if this property is updatable
            var is_value_supported = false
            var prop_value: AnyObject?
            let keypath_accepted = valueAssistant.acceptsKeypath(unwrapped_object)
            if (keypath_accepted) {
                do {
                    prop_value = try valueAssistant.retrieveValue(inObject: unwrapped_object, keyPath: property.path)
                    
                } catch ValueAssistantError.TypeRequirement(let valueType) {
                    ValueAssistantError.TypeRequirement(valueType).printError(fromFunction: #function)
                    
                } catch {
                    // any other errors
                }
                
                if (prop_value == nil) {
                    if let retrieved = try? valueAssistant.retrieveValue(inObject: unwrapped_object, keyPath: property.path) {
                        prop_value = retrieved
                    }
                }
                
                if (prop_value is NSObject && valueAssistant.supports((prop_value as! NSObject))) {
                    is_value_supported = true
                }
            }
            if (is_value_supported) {
                if let value = prop_value {
                    property.target = value
                }
            
            } else if (unwrapped_object is NSNumber) {
                // target property's value could be nil if it's a NSNumber, so set it to the starting value
                let start_value = NSNumber.init(double: property.start)
                property.target = start_value
            } else {
                property.target = unwrapped_object
            }
            
            // modify start value if we should use the existing value instead
            assignStartingPropertyValue(&property)
        
        } else {
            // there is no path, so the top-level object should be the target
            property.target = unwrapped_object
        }
        
    }
    
    
    /**
     *  Assigns a start value for the property, useful when a motion is starting with the property's current value.
     *
     *  - parameter property: The `PropertyData` instance to modify.
     */
    private func assignStartingPropertyValue(inout property: PropertyData) {
        if (property.useExistingStartValue && completedCount == 0) {
            if let current_value = valueAssistant.retrieveCurrentObjectValue(forProperty: property) {
                property.start = current_value
            }
        }
    }
    
    
    /// Prepares the Motion's state for movement and starts
    private func startMotion() {
        
        if (additive) {
            if let unwrapped_object = targetObject {
                for index in 0 ..< properties.count {
                    // assign the ending value of the last motion for this obj/keyPath to each property's starting value
                    let property = properties[index]
                    
                    if let last_target_value = MotionSupport.targetValue(forObject: unwrapped_object, keyPath: property.path) {
                        properties[index].start = last_target_value
                    }
                }
            }
        }
        
        for index in 0 ..< properties.count {
            // modify start value if we should use the existing value instead
            if (!additive) { assignStartingPropertyValue(&properties[index]) }
            properties[index].current = properties[index].start
        }
        
        motionState = .Moving
        startTime = 0.0
        
        if (additive && targetObject != nil) {
            operationID = MotionSupport.register(additiveMotion: self)
        }
        
        // call start closure
        weak var weak_self = self
        _started?(motion: weak_self!)
        
        // send start status update
        sendStatusUpdate(.Started)
        
    }
    
    
    
    
    /**
     *  Dispatches a status update to the `MotionUpdateDelegate` delegate assigned to the object, if there is one.
     *
     *  - parameter status: The `MoveableStatus` enum value to send to the delegate.
     */
    private func sendStatusUpdate(status: MoveableStatus) {
        
        weak var weak_self = self
        updateDelegate?.motionStatusUpdated(forMotion: weak_self!, updateType: status)
    }
    
    
    
    
    // MARK: - Motion methods
    
    /**
     *  Updates the target property with a new delta value.
     *
     *  - parameter property: The property to update.
     */
    private func updatePropertyValue(inout forProperty property: PropertyData) {
        
        let new_value = (additive) ? property.delta : property.current
        if (property.targetObject == nil) {
            
            if let new_prop = valueAssistant.calculateValue(forProperty: property, newValue: new_value) {
                property.target = new_prop
            }
            
            return
        }
        
        if (property.targetObject != nil) {
            
            if let new_prop = valueAssistant.calculateValue(forProperty: property, newValue: new_value) {

                if (!property.replaceParentProperty) {
                    property.targetObject!.setValue(new_prop, forKey: property.path)
                    
                } else {
                    property.targetObject!.setValue(new_prop, forKeyPath: property.parentKeyPath)
                    
                }
            }
        }
    }
    

    /// Called when the motion has completed.
    private func motionCompleted() {
        
        motionState = .Stopped
        _motionProgress = 1.0
        _cycleProgress = 1.0
        if (!repeating) { cyclesCompletedCount += 1 }
        completedCount += 1
        
        for index in 0 ..< properties.count {
            if (reversing) {
                properties[index].current = properties[index].start
            } else {
                properties[index].current = properties[index].end
            }
            updatePropertyValue(forProperty: &properties[index])
        }

        
        if (additive && targetObject != nil) {
            operationID = 0
            MotionSupport.unregister(additiveMotion: self)
        }
        
        // call update closure
        weak var weak_self = self
        _updated?(motion: weak_self!)
        
        // call complete closure
        _completed?(motion: weak_self!)
        
        // send completion status update
        sendStatusUpdate(.Completed)
    }
    
    
    /// Starts the motion's next repeat cycle, if there is one.
    private func nextRepeatCycle() {
        cyclesCompletedCount += 1
        completedCount = 0
        
        if (repeatCycles == 0 || cyclesCompletedCount - 1 < repeatCycles) {
            
            // reset for next cycle
            for index in 0 ..< properties.count {
                properties[index].current = properties[index].start
            }
            _cycleProgress = 0.0
            _motionProgress = 0.0
            
            if (resetObjectStateOnRepeat) {
                if let unwrapped_object = targetObject {
                    for index in 0 ..< properties.count {
                        let property = properties[index]
                        if let unwrapped_starting = property.startingParentProperty {
                            unwrapped_object.setValue(unwrapped_starting, forKey: property.parentKeyPath)
                        }
                    }
                }
            }
            
            // setting startTime to 0.0 causes update method to re-init the motion
            startTime = 0.0
            
            if (reversing) {
                reverseMotionDirection()
            }
            
            // call cycle closure
            weak var weak_self = self
            _cycleRepeated?(motion: weak_self!)
            
            // send repeated status update
            sendStatusUpdate(.Repeated)
        
            motionState = .Moving
            
        } else {
            motionCompleted()
        }
        
    }
    
    
    /// Reverses the direction of the motion.
    private func reverseMotionDirection() {
        
        if (motionDirection == .Forward) {
            motionDirection = .Reverse
        } else if (motionDirection == .Reverse) {
            motionDirection = .Forward
        }
        
        // reset the times to get ready for the new reverse motion
        startTime = 0.0
        _motionProgress = 0.0
        
        // call reverse closure
        weak var weak_self = self
        _reversed?(motion: weak_self!)
        
        // send out 50% complete notification, used by MotionSequence in contiguous mode
        let half_complete = round(Double(repeatCycles) * 0.5)
        if (motionDirection == .Reverse && (Double(cyclesCompletedCount) ≈≈ half_complete)) {
            sendStatusUpdate(.HalfCompleted)
        
        } else {
            sendStatusUpdate(.Reversed)
        }
        
    }
    
    

    
    
    
    // MARK: - Moveable protocol methods
    
    public func update(withTimeInterval currentTime: NSTimeInterval) {
        
        if (motionState == .Moving) {
            
            if (pauseTimestamp > 0.0 && startTime > 0.0) {
                // we just resumed from a pause, so adjust the times to account for paused length
                let pause_delta = currentTime - pauseTimestamp
                startTime += pause_delta
                endTime += pause_delta
                pauseTimestamp = 0.0 // reset pause timestamp
            }
            
            if (startTime == 0.0) {
                // a start time of 0 means we need to initialize the motion times
                startTime = currentTime
                endTime = startTime + duration
                pauseTimestamp = 0.0
                
                // temporarily turn off additive mode for the first update so the starting position can be set
                let temp_additive = additive
                additive = false
                _additive = temp_additive
                for index in 0 ..< properties.count {
                    if (!_additive) { updatePropertyValue(forProperty: &properties[index]) }
                }
                valueAssistant.additive = _additive
            }
            
            self.currentTime = min(currentTime, endTime) // don't let currentTime go over endTime or it'll produce wrong easing values
            
            var progress: Double = 0.0
            let elapsed_time = self.currentTime - startTime
 
            for index in 0 ..< properties.count {
                var property = properties[index]
                
                var new_value: Double = 0.0
            
                let value_range = property.end - property.start
                if (value_range != 0.0) {
                    if (motionDirection == .Forward) {
                        new_value = easing(elapsedTime: elapsed_time, startValue: property.start, valueRange: value_range, duration: duration)
                        progress = fabs((property.current - property.start) / value_range)
                    
                    } else {
                        if let reverse_easing = reverseEasing {
                            new_value = reverse_easing(elapsedTime: elapsed_time, startValue: property.end, valueRange: -value_range, duration: duration)
                            
                        } else {
                            new_value = easing(elapsedTime: elapsed_time, startValue: property.end, valueRange: -value_range, duration: duration)
                        }

                        progress = fabs((property.end - property.current) / value_range)
                    }
                    properties[index].delta = new_value - property.current
                    properties[index].current = new_value
                }
            }
            motionProgress = min(progress, 1.0) // progress for all properties will be the same, so the last is used to avoid multiple property sets
            
            if (self.currentTime < self.endTime) {
                for index in 0 ..< properties.count {
                    updatePropertyValue(forProperty: &properties[index])
                }
                // call update closure
                weak var weak_self = self
                _updated?(motion: weak_self!)
                
            } else {
                
                // motion has completed
                if (reversing || repeating) {
                    if ((repeating && !reversing) || (reversing && repeating && motionDirection == .Reverse)) {
                        nextRepeatCycle()
                        
                    } else if (!repeating && reversing && motionDirection == .Reverse) {
                        motionCompleted()
                        
                    } else if (reversing && motionState == .Moving) {
                        reverseMotionDirection()
                    }
                    
                } else {
                    // not reversing or repeating
                    motionCompleted()
                }
            }
            
        } else if (motionState == .Delayed) {
            
            self.currentTime = currentTime
            
            if (startTime == 0.0) {
                // a start time of 0 means we need to initialize the motion times
                startTime = currentTime
                endTime = startTime + delay
            }
            
            if (currentTime >= endTime) {
                // delay is done, time to move
                
                startMotion()
            }
            
        }
        
        
        
    }
    
    
    public func start() -> Self {
        if (motionState == .Stopped) {
            reset()
            
            let no_delay_set: Bool = ((delay == 0.0) ? true : false)
            

            
            if (no_delay_set) {
                startMotion()
                
            } else {
                motionState = .Delayed
            }
            
        }
        
        return self
    }
    
    
    public func stop() {
        
        if (motionState == .Moving || motionState == .Paused || motionState == .Delayed) {
            motionState = .Stopped
            
            startTime = 0.0
            currentTime = 0.0
            motionProgress = 0.0
            
            if (additive && targetObject != nil) {
                operationID = 0
                MotionSupport.unregister(additiveMotion: self)
            }
            
            // call stop closure
            weak var weak_self = self
            _stopped?(motion: weak_self!)
            
            // send stopped status update
            sendStatusUpdate(.Stopped)
        }
    }
    
    public func pause() {
        
        if (motionState == .Moving) {
            motionState = .Paused
            
            // saves current time so we can determine length of pause time
            pauseTimestamp = currentTime
            
            // call pause closure
            weak var weak_self = self
            _paused?(motion: weak_self!)
            
            // send paused status update
            sendStatusUpdate(.Paused)
            
        }
    }
    
    public func resume() {
        if (motionState == .Paused) {
            motionState = .Moving

            // call resume closure
            weak var weak_self = self
            _resumed?(motion: weak_self!)
            
            // send resumed status update
            sendStatusUpdate(.Resumed)
        }
    }
    
    
    /// Resets the motion to its initial state.
    public func reset() {
        motionState = .Stopped
        motionDirection = .Forward
        
        for index in 0 ..< properties.count {
            let property = properties[index]
            properties[index].current = property.start
            if (resetObjectStateOnRepeat) {
                if let unwrapped_object = targetObject {
                    if let unwrapped_starting = property.startingParentProperty {
                        unwrapped_object.setValue(unwrapped_starting, forKey: property.parentKeyPath)
                    }
                }
            }
        }
        
        cyclesCompletedCount = 0
        _cycleProgress = 0.0
        _motionProgress = 0.0
        
        // setting startTime to 0.0 causes motionUpdate method to re-init the motion
        startTime = 0.0
    }
    
    

    // MARK: TempoDriven methods
    
    public func stopTempoUpdates() {
        
        tempo?.delegate = nil
        tempo = nil
        
    }
    
    
    
    // MARK: TempoDelegate methods
    
    public func tempoBeatUpdate(timestamp: NSTimeInterval) {

        update(withTimeInterval: timestamp)
        
    }
    
    // MARK: PropertyDataDelegate methods
    
    public func didUpdate(startValue: Double) {
        motionProgress = 0.0
        
        // setting startTime to 0 causes motionUpdate method to re-init the motion
        startTime = 0.0
    }
    

}