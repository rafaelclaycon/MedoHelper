//
//  FileHelper.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 07/02/23.
//

import AVFoundation
#if canImport(AppKit)
import AppKit
#endif

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

    static public func renameFile(
        from fileURL: URL,
        with filename: String,
        saveTo destinationURL: URL
    ) throws {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destinationURL.appending(path: filename).path(percentEncoded: false)) {
            try fileManager.removeItem(at: destinationURL)
        }

        if !fileManager.fileExists(atPath: destinationURL.path) {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        }

        try FileHelper.copyAndRenameFile(from: fileURL, to: destinationURL, with: filename)
    }

    static private func copyAndRenameFile(from sourceURL: URL, to destinationURL: URL, with newName: String) throws {
        let fileManager = FileManager.default
        let destinationFileURL = destinationURL.appendingPathComponent(newName)
        guard fileManager.fileExists(atPath: sourceURL.path(percentEncoded: false)) else { throw FileError.sourceFileDoesNotExist }
        guard fileManager.isReadableFile(atPath: sourceURL.path(percentEncoded: false)) else { throw FileError.noPermissionToRead }
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: destinationURL.path, isDirectory: &isDirectory) else { throw FileError.destinationDirDoesNotExist(destinationURL.path()) }
        print(isDirectory)
        
        guard fileManager.fileExists(atPath: destinationURL.path) else { throw FileError.destinationDirDoesNotExist(destinationURL.path()) }
        guard fileManager.isWritableFile(atPath: destinationURL.path) else { throw FileError.destinationIsNotWritable }
        
        print("Source: \(sourceURL.path(percentEncoded: false))")
        print("Destination: \(destinationFileURL.path(percentEncoded: false))")
        
        try fileManager.copyItem(atPath: sourceURL.path(percentEncoded: false), toPath: destinationFileURL.path(percentEncoded: false))
    }
    
    static func openFolderInFinder(_ folderURL: URL) {
        #if canImport(AppKit)
        let workspace = NSWorkspace.shared
        workspace.selectFile(nil, inFileViewerRootedAtPath: folderURL.path)
        #endif
    }
}

enum FileError: Error {
    
    case sourceFileDoesNotExist
    case noPermissionToRead
    case destinationDirDoesNotExist(String)
    case destinationIsNotWritable
}

extension FileError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .sourceFileDoesNotExist:
            return NSLocalizedString("O arquivo de origem não existe.", comment: "")
        case .noPermissionToRead:
            return NSLocalizedString("Sem permissão para ler o arquivo de origem.", comment: "")
        case .destinationDirDoesNotExist(let dirUrl):
            return NSLocalizedString("A URL de destino '\(dirUrl)' não existe.", comment: "")
        case .destinationIsNotWritable:
            return NSLocalizedString("Sem permissão para escrever no destino.", comment: "")
        }
    }
}
