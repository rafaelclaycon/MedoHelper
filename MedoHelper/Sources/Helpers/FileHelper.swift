//
//  FileHelper.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 07/02/23.
//

import AVFoundation

class FileHelper {
    
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
    
    static func getDuration(of file: URL) async -> Double? {
        let asset = AVURLAsset(url: file)
        do {
            let rawDuration = try await asset.load(.duration).seconds
            let normalized = Double(round(100 * rawDuration) / 100)
            return normalized
        } catch {
            return nil
        }
    }
    
    static func copyAndRenameFile(from sourceURL: URL, to destinationURL: URL, with newName: String) -> Bool {
        let fileManager = FileManager.default
        let destinationFileURL = destinationURL.appendingPathComponent(newName)
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationFileURL)
            return true
        } catch {
            print("Error copying file: \(error)")
            return false
        }
    }
}
