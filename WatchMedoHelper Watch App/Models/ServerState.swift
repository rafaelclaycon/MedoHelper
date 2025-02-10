//
//  ServerState.swift
//  WatchMedoHelper Watch App
//
//  Created by Rafael Schmitt on 10/02/25.
//

import Foundation

enum ServerState: Equatable {

    case loading, operational, hasIssues, couldNotReach
}
