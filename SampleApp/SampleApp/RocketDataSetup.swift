//
//  RocketDataSetup.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import Foundation
import RocketData

extension DataModelManager {
    /**
     Singleton accessor for DataModelManager. See https://linkedin.github.io/RocketData/pages/040_setup.html
     */
    static let sharedInstance = DataModelManager(cacheDelegate: RocketDataCacheDelegate())
}

extension DataProvider {
    convenience init() {
        self.init(dataModelManager: DataModelManager.sharedInstance)
    }
}

extension CollectionDataProvider {
    convenience init(cacheKey: String?) {
        self.init(dataModelManager: DataModelManager.sharedInstance)
    }
}
