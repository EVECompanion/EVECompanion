//
//  ECKAllianceResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 21.05.24.
//

import Foundation

class ECKAllianceResource: ECKWebResource<ECKOptionalResponse<ECKAlliance>> {
    
    init(allianceId: Int) {
        super.init(host: .esi,
                   endpoint: "/v4/alliances/\(allianceId.description)/",
                   requiredScope: nil,
                   requiredCorpRole: nil)
    }
    
}
