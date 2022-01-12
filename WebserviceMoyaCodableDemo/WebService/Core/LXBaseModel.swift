//
//  LXBaseModel.swift
//  live
//
//  Created by sioeye on 2022/1/12.
//

import UIKit

public class LXBaseModel: NSObject, Codable {
    public override init() {
        super.init()
    }
    
    required public init(from decoder: Decoder) throws {
        
    }
    
    public func encode(to encoder: Encoder) throws {
        
    }
}
