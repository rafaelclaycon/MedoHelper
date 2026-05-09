//
//  TranscriptStorage.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/04/26.
//

import Foundation

/// Central place for the local disk layout of transcript-related files.
///
/// Everything lives under `~/Library/Application Support/MedoHelper/`, which
/// keeps large binary assets out of the user's Documents folder and preserves
/// them across re-indexing (unlike `.cachesDirectory`, which macOS may purge).
enum TranscriptStorage {

    private static let appFolderName = "MedoHelper"
    private static let transcriptsFolderName = "Transcripts"
    private static let episodesFolderName = "Episodes"

    static func applicationSupportDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDir = base.appendingPathComponent(appFolderName, isDirectory: true)
        try ensureDirectory(appDir)
        return appDir
    }

    static func transcriptsDirectory() throws -> URL {
        let dir = try applicationSupportDirectory()
            .appendingPathComponent(transcriptsFolderName, isDirectory: true)
        try ensureDirectory(dir)
        return dir
    }

    static func episodesDirectory() throws -> URL {
        let dir = try applicationSupportDirectory()
            .appendingPathComponent(episodesFolderName, isDirectory: true)
        try ensureDirectory(dir)
        return dir
    }

    static func transcriptFileURL(for episodeId: String) throws -> URL {
        try transcriptsDirectory().appendingPathComponent("\(episodeId).srt")
    }

    static func episodeAudioURL(for episodeId: String, fileExtension: String = "mp3") throws -> URL {
        try episodesDirectory().appendingPathComponent("\(episodeId).\(fileExtension)")
    }

    static func removeAllTranscripts() throws {
        let dir = try transcriptsDirectory()
        try removeContents(of: dir)
    }

    // MARK: - Private

    private static func ensureDirectory(_ url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private static func removeContents(of url: URL) throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return }
        let items = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        for item in items {
            try fm.removeItem(at: item)
        }
    }
}
