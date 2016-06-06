//
//  EasingSine.swift
//  MotionMachine
//
//  Created by Brett Walker on 5/3/16.
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

/**
 *  EasingSine provides sine easing equations.
 */
public struct EasingSine {
    
    public static func easeIn() -> EasingUpdateClosure {
        
        func easing (elapsedTime: NSTimeInterval, startValue: Double, valueRange: Double, duration: NSTimeInterval) -> Double {
            let easing_value = -valueRange * cos((elapsedTime / duration) * M_PI_2) + valueRange + startValue
            
            return easing_value
        }
        
        return easing
    }
    
    public static func easeOut() -> EasingUpdateClosure {
        
        func easing (elapsedTime: NSTimeInterval, startValue: Double, valueRange: Double, duration: NSTimeInterval) -> Double {
            let easing_value = valueRange * sin((elapsedTime / duration) * M_PI_2) + startValue
            
            return easing_value
        }
        
        return easing
    }
    
    public static func easeInOut() -> EasingUpdateClosure {
        
        func easing (elapsedTime: NSTimeInterval, startValue: Double, valueRange: Double, duration: NSTimeInterval) -> Double {
            let easing_value = (-valueRange * 0.5) * (cos(M_PI * (elapsedTime / duration)) - 1) + startValue
            
            return easing_value
        }
        
        return easing
    }
    
}