import CloudKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let iCloudChannelName = "our_recipe/icloud_path"
  private let snapshotRecordType = "AppSnapshot"
  private let imageRecordType = "AppImage"
  private let snapshotRecordName = "shared_snapshot"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: iCloudChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(nil)
          return
        }

        switch call.method {
        case "getICloudStatus":
          self.resolveICloudStatus(result: result)
        case "uploadCloudKitSnapshot":
          guard
            let args = call.arguments as? [String: Any],
            let snapshotPath = args["snapshotPath"] as? String,
            let imagePaths = args["imagePaths"] as? [String]
          else {
            result(
              FlutterError(code: "invalid_args", message: "Missing upload args", details: nil)
            )
            return
          }
          self.uploadCloudKitSnapshot(
            snapshotPath: snapshotPath,
            imagePaths: imagePaths,
            result: result
          )
        case "downloadCloudKitSnapshot":
          guard
            let args = call.arguments as? [String: Any],
            let imagesDirPath = args["imagesDirPath"] as? String
          else {
            result(
              FlutterError(code: "invalid_args", message: "Missing download args", details: nil)
            )
            return
          }
          self.downloadCloudKitSnapshot(imagesDirPath: imagesDirPath, result: result)
        case "clearCloudKitData":
          self.clearCloudKitData(result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func resolveICloudStatus(result: @escaping FlutterResult) {
    let container = CKContainer.default()
    container.accountStatus { status, _ in
      let available = status == .available
      NSLog("[CloudKit] accountStatus=\(status.rawValue) available=\(available)")
      result([
        "tokenPresent": available,
        "containerAvailable": true,
      ])
    }
  }

  private func uploadCloudKitSnapshot(
    snapshotPath: String,
    imagePaths: [String],
    result: @escaping FlutterResult
  ) {
    NSLog("[CloudKit] upload start snapshotPath=\(snapshotPath) imageCount=\(imagePaths.count)")
    let database = CKContainer.default().privateCloudDatabase
    let snapshotID = CKRecord.ID(recordName: snapshotRecordName)
    database.fetch(withRecordID: snapshotID) { record, _ in
      let snapshotRecord = record ?? CKRecord(recordType: self.snapshotRecordType, recordID: snapshotID)
      snapshotRecord["updatedAt"] = Date() as CKRecordValue
      snapshotRecord["payload"] = CKAsset(fileURL: URL(fileURLWithPath: snapshotPath))

      database.save(snapshotRecord) { _, error in
        if let error {
          NSLog("[CloudKit] snapshot save failed: \(error.localizedDescription)")
          result(
            FlutterError(code: "cloudkit_upload_failed", message: error.localizedDescription, details: nil)
          )
          return
        }
        NSLog("[CloudKit] snapshot save success")
        self.syncImageRecords(database: database, imagePaths: imagePaths, result: result)
      }
    }
  }

  private func syncImageRecords(
    database: CKDatabase,
    imagePaths: [String],
    result: @escaping FlutterResult
  ) {
    let saveRecords = imagePaths.map { path -> CKRecord in
      let fileName = URL(fileURLWithPath: path).lastPathComponent
      let recordID = CKRecord.ID(recordName: fileName)
      let record = CKRecord(recordType: imageRecordType, recordID: recordID)
      record["fileName"] = fileName as CKRecordValue
      record["updatedAt"] = Date() as CKRecordValue
      record["asset"] = CKAsset(fileURL: URL(fileURLWithPath: path))
      return record
    }

    let modify = CKModifyRecordsOperation(recordsToSave: saveRecords, recordIDsToDelete: nil)
    modify.savePolicy = .changedKeys
    modify.modifyRecordsCompletionBlock = { _, _, error in
      if let error {
        NSLog("[CloudKit] image sync failed: \(error.localizedDescription)")
        result(
          FlutterError(
            code: "cloudkit_image_sync_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
      } else {
        NSLog("[CloudKit] image sync success saveCount=\(saveRecords.count)")
        result(nil)
      }
    }
    database.add(modify)
  }

  private func downloadCloudKitSnapshot(
    imagesDirPath: String,
    result: @escaping FlutterResult
  ) {
    NSLog("[CloudKit] download start imagesDirPath=\(imagesDirPath)")
    let database = CKContainer.default().privateCloudDatabase
    let snapshotID = CKRecord.ID(recordName: snapshotRecordName)
    database.fetch(withRecordID: snapshotID) { record, error in
      if let ckError = error as? CKError, ckError.code == .unknownItem {
        NSLog("[CloudKit] download snapshot not found")
        result(["found": false])
        return
      }
      if let error {
        NSLog("[CloudKit] download failed: \(error.localizedDescription)")
        result(
          FlutterError(code: "cloudkit_download_failed", message: error.localizedDescription, details: nil)
        )
        return
      }
      guard
        let record,
        let asset = record["payload"] as? CKAsset,
        let sourceURL = asset.fileURL
      else {
        result(["found": false])
        return
      }

      let tempDir = FileManager.default.temporaryDirectory
      let snapshotURL = tempDir.appendingPathComponent("cloudkit_snapshot_download.json")
      do {
        if FileManager.default.fileExists(atPath: snapshotURL.path) {
          try FileManager.default.removeItem(at: snapshotURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: snapshotURL)
      } catch {
        NSLog("[CloudKit] snapshot copy failed: \(error.localizedDescription)")
        result(
          FlutterError(code: "cloudkit_snapshot_copy_failed", message: error.localizedDescription, details: nil)
        )
        return
      }

      self.downloadImageRecords(
        database: database,
        imagesDirPath: imagesDirPath,
        snapshotPath: snapshotURL.path,
        result: result
      )
    }
  }

  private func downloadImageRecords(
    database: CKDatabase,
    imagesDirPath: String,
    snapshotPath: String,
    result: @escaping FlutterResult
  ) {
    let fileManager = FileManager.default
    let imagesDirURL = URL(fileURLWithPath: imagesDirPath, isDirectory: true)
    do {
      try fileManager.createDirectory(at: imagesDirURL, withIntermediateDirectories: true)
    } catch {
      NSLog("[CloudKit] image directory create failed: \(error.localizedDescription)")
      result(
        FlutterError(code: "cloudkit_image_dir_failed", message: error.localizedDescription, details: nil)
      )
      return
    }

    let imageNames = extractImageNames(snapshotPath: snapshotPath)
    if let existing = try? fileManager.contentsOfDirectory(
      at: imagesDirURL,
      includingPropertiesForKeys: nil
    ) {
      let remoteNames = Set(imageNames)
      for fileURL in existing where !remoteNames.contains(fileURL.lastPathComponent) {
        try? fileManager.removeItem(at: fileURL)
      }
    }

    if imageNames.isEmpty {
      NSLog("[CloudKit] image download success count=0")
      result([
        "found": true,
        "snapshotPath": snapshotPath,
      ])
      return
    }

    let recordIDs = imageNames.map { CKRecord.ID(recordName: $0) }
    let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
    var fetchedRecords: [CKRecord.ID: CKRecord] = [:]
    operation.perRecordCompletionBlock = { record, recordID, error in
      guard let recordID else { return }
      if let record {
        fetchedRecords[recordID] = record
      } else if let error {
        NSLog("[CloudKit] image fetch skipped recordName=\(recordID.recordName) error=\(error.localizedDescription)")
      }
    }
    operation.fetchRecordsCompletionBlock = { _, error in
      if let ckError = error as? CKError,
         ckError.code != .partialFailure {
        NSLog("[CloudKit] image fetch failed: \(ckError.localizedDescription)")
        result(
          FlutterError(code: "cloudkit_image_download_failed", message: ckError.localizedDescription, details: nil)
        )
        return
      } else if let error, (error as? CKError) == nil {
        NSLog("[CloudKit] image fetch failed: \(error.localizedDescription)")
        result(
          FlutterError(code: "cloudkit_image_download_failed", message: error.localizedDescription, details: nil)
        )
        return
      }

      for fileName in imageNames {
        guard
          let record = fetchedRecords[CKRecord.ID(recordName: fileName)],
          let asset = record["asset"] as? CKAsset,
          let sourceURL = asset.fileURL
        else { continue }
        let targetURL = imagesDirURL.appendingPathComponent(fileName)
        do {
          if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
          }
          try fileManager.copyItem(at: sourceURL, to: targetURL)
        } catch {
          continue
        }
      }

      NSLog("[CloudKit] image download success fetchedCount=\(fetchedRecords.count) requestedCount=\(imageNames.count)")
      result([
        "found": true,
        "snapshotPath": snapshotPath,
      ])
    }
    database.add(operation)
  }

  private func clearCloudKitData(result: @escaping FlutterResult) {
    NSLog("[CloudKit] clear start")
    let database = CKContainer.default().privateCloudDatabase
    let snapshotID = CKRecord.ID(recordName: snapshotRecordName)
    database.fetch(withRecordID: snapshotID) { record, error in
      if let ckError = error as? CKError, ckError.code == .unknownItem {
        NSLog("[CloudKit] clear success deleteCount=0")
        result(nil)
        return
      }
      if let error {
        NSLog("[CloudKit] clear fetch failed: \(error.localizedDescription)")
        result(
          FlutterError(code: "cloudkit_clear_failed", message: error.localizedDescription, details: nil)
        )
        return
      }

      var ids = [snapshotID]
      if
        let record,
        let asset = record["payload"] as? CKAsset,
        let sourceURL = asset.fileURL
      {
        ids.append(contentsOf: self.extractImageNames(snapshotURL: sourceURL).map { CKRecord.ID(recordName: $0) })
      }

      let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: ids)
      operation.modifyRecordsCompletionBlock = { _, _, error in
        if let error {
          NSLog("[CloudKit] clear failed: \(error.localizedDescription)")
          result(
            FlutterError(code: "cloudkit_clear_failed", message: error.localizedDescription, details: nil)
          )
        } else {
          NSLog("[CloudKit] clear success deleteCount=\(ids.count)")
          result(nil)
        }
      }
      database.add(operation)
    }
  }

  private func extractImageNames(snapshotPath: String) -> [String] {
    return extractImageNames(snapshotURL: URL(fileURLWithPath: snapshotPath))
  }

  private func extractImageNames(snapshotURL: URL) -> [String] {
    guard
      let data = try? Data(contentsOf: snapshotURL),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return []
    }

    var names = Set<String>()

    if let recipes = json["recipes"] as? [[String: Any]] {
      for recipe in recipes {
        if let cover = recipe["coverImagePath"] as? String, !cover.isEmpty {
          names.insert(cover)
        }
        if let steps = recipe["steps"] as? [[String: Any]] {
          for step in steps {
            if let image = step["imagePath"] as? String, !image.isEmpty {
              names.insert(image)
            }
          }
        }
      }
    }

    if let cookLogs = json["cookLogs"] as? [[String: Any]] {
      for log in cookLogs {
        if let image = log["resultImagePath"] as? String, !image.isEmpty {
          names.insert(image)
        }
      }
    }

    return Array(names)
  }
}
