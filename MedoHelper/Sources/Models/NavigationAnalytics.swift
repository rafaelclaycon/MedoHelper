//
//  NavigationAnalytics.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/12/25.
//

import Foundation

// MARK: - Navigation Analytics Response

struct NavigationAnalyticsResponse: Codable, Equatable {
    let topScreens: [ScreenViewStat]
    let totalViews: Int
    
    enum CodingKeys: String, CodingKey {
        case topScreens = "top_screens"
        case totalViews = "total_views"
    }
}

// MARK: - Screen View Stat

struct ScreenViewStat: Codable, Identifiable, Equatable {
    let id: String // screen name
    let screenName: String
    let viewCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case screenName = "screen_name"
        case viewCount = "view_count"
    }
    
    var displayName: String {
        var name = screenName
        
        // Special cases
        if name == "didViewSpecificReaction" {
            return "Reactions (Categorias)"
        }
        
        // Remove prefixes
        if name.hasPrefix("didView") {
            name = String(name.dropFirst(7))
        } else if name.hasPrefix("did") {
            name = String(name.dropFirst(3))
        }
        
        // Handle action events
        if name.hasPrefix("Tap") {
            name = "Tapped" + String(name.dropFirst(3))
        } else if name.hasPrefix("Play") {
            name = "Play " + String(name.dropFirst(4))
        } else if name.hasPrefix("See") {
            name = "Saw " + String(name.dropFirst(3))
        } else if name.hasPrefix("Add") {
            name = "Added " + String(name.dropFirst(3))
        } else if name.hasPrefix("Dismiss") {
            name = "Dismissed " + String(name.dropFirst(7))
        } else if name.hasPrefix("Copy") {
            name = "Copied " + String(name.dropFirst(4))
        } else if name.hasPrefix("Pick") {
            name = "Picked " + String(name.dropFirst(4))
        }
        
        // Handle issue/error events
        if name.hasPrefix("hadIssue") || name.hasPrefix("issue") {
            name = name.replacingOccurrences(of: "hadIssue", with: "Issue: ")
            name = name.replacingOccurrences(of: "issue", with: "Issue: ")
            name = name.replacingOccurrences(of: "Issue:Syncing", with: "Issue: Syncing")
            name = name.replacingOccurrences(of: "Issue:With", with: "Issue: With")
            name = name.replacingOccurrences(of: "Issue:Loading", with: "Issue: Loading")
        }
        
        // Handle pinned/unpinned
        if name.hasPrefix("pinned") {
            name = "Pinned " + String(name.dropFirst(6))
        } else if name.hasPrefix("unpinned") {
            name = "Unpinned " + String(name.dropFirst(8))
        }
        
        // Handle tapped events
        if name.contains("tapped") {
            name = name.replacingOccurrences(of: "tapped", with: "Tapped")
        }
        
        // Add spaces before capital letters (camelCase to words)
        name = name.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
        
        // Add spaces before Tab, View, Screen
        name = name.replacingOccurrences(of: "Tab", with: " Tab")
        name = name.replacingOccurrences(of: "View", with: " View")
        name = name.replacingOccurrences(of: "Screen", with: " Screen")
        
        // Clean up extra spaces
        name = name.replacingOccurrences(of: "  ", with: " ")
        name = name.trimmingCharacters(in: .whitespaces)
        
        // Capitalize first letter
        if !name.isEmpty {
            name = name.prefix(1).uppercased() + String(name.dropFirst())
        }
        
        return name
    }
    
    var iconName: String {
        let name = screenName.lowercased()
        
        if name.contains("tab") {
            return "square.grid.2x2"
        } else if name.contains("reaction") {
            return "face.smiling"
        } else if name.contains("song") {
            return "music.note"
        } else if name.contains("author") {
            return "person.2"
        } else if name.contains("favorite") {
            return "heart"
        } else if name.contains("folder") {
            return "folder"
        } else if name.contains("trend") {
            return "chart.line.uptrend.xyaxis"
        } else if name.contains("alternateicon") {
            return "app.badge"
        } else if name.contains("about") || name.contains("sync") || name.contains("faq") {
            return "info.circle"
        } else if name.contains("play") || name.contains("tap") || name.contains("pick") {
            return "hand.tap"
        } else if name.contains("issue") || name.contains("error") {
            return "exclamationmark.triangle"
        } else if name.contains("banner") {
            return "rectangle.badge"
        } else if name.contains("pinned") || name.contains("unpinned") {
            return "pin"
        } else if name.contains("copy") {
            return "doc.on.doc"
        } else if name.contains("social") || name.contains("github") || name.contains("blog") {
            return "link"
        } else {
            return "rectangle"
        }
    }
}

