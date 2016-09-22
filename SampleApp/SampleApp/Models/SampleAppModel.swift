//
//  SampleAppModel.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import Foundation
import RocketData

/**
 Here, we're going to define a custom protocol for all the models in this app to adhere to.
 It's going to extend from Model, so we can use it with Rocket Data.
 */
protocol SampleAppModel: Model {
    init?(data: [AnyHashable: Any])
    func data() -> [AnyHashable: Any]
}
