//
//  DurationHelper.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 07/02/23.
//

import AVFoundation

class DurationHelper {
    
    static func getDuration(of filename: String) async -> Double? {
        guard let path = Bundle.main.path(forResource: filename, ofType: nil) else {
            print("Filename desse aqui deu ruim em: \(filename)")
            return 0.0
        }
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration).seconds
            return duration
        } catch {
            return nil
        }
        
    }
    
}
