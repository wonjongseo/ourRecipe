import CloudKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let iCloudChannelName = "our_recipe/icloud_path"
  private let snapshotRecordType = "AppSnapshot"
  private let imageRecordType = "AppImage"
  private let snapshotRecordName = "shared_snapshot"
  private let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "webp"]

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
        case "downloadCloudKitSnapshotPayload":
          self.downloadCloudKitSnapshotPayload(result: result)
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
    NSLog("[CloudKit] upload imageNames=\(imagePaths.map { URL(fileURLWithPath: $0).lastPathComponent })")
    let database = CKContainer.default().privateCloudDatabase
    let snapshotID = CKRecord.ID(recordName: snapshotRecordName)
    database.fetch(withRecordID: snapshotID) { record, _ in
      let snapshotRecord = record ?? CKRecord(recordType: self.snapshotRecordType, recordID: snapshotID)
      snapshotRecord["updatedAt"] = Date() as CKRecordValue
      snapshotRecord["payload"] = CKAsset(fileURL: URL(fileURLWithPath: snapshotPath))

      self.saveSnapshotRecord(
        database: database,
        snapshotRecord: snapshotRecord,
        imagePaths: imagePaths,
        result: result
      )
    }
  }

  private func saveSnapshotRecord(
    database: CKDatabase,
    snapshotRecord: CKRecord,
    imagePaths: [String],
    result: @escaping FlutterResult
  ) {
    let operation = CKModifyRecordsOperation(recordsToSave: [snapshotRecord], recordIDsToDelete: nil)
    operation.savePolicy = .allKeys
    operation.modifyRecordsCompletionBlock = { _, _, error in
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
    database.add(operation)
  }

  private func syncImageRecords(
    database: CKDatabase,
    imagePaths: [String],
    result: @escaping FlutterResult
  ) {
    if imagePaths.isEmpty {
      result(nil)
      return
    }
    let group = DispatchGroup()

    for path in imagePaths {
      let fileName = URL(fileURLWithPath: path).lastPathComponent
      let recordID = CKRecord.ID(recordName: fileName)
      group.enter()
      database.fetch(withRecordID: recordID) { record, _ in
        let imageRecord = record ?? CKRecord(recordType: self.imageRecordType, recordID: recordID)
        imageRecord["fileName"] = fileName as CKRecordValue
        imageRecord["updatedAt"] = Date() as CKRecordValue
        imageRecord["asset"] = CKAsset(fileURL: URL(fileURLWithPath: path))

        let modify = CKModifyRecordsOperation(recordsToSave: [imageRecord], recordIDsToDelete: nil)
        modify.savePolicy = .allKeys
        modify.modifyRecordsCompletionBlock = { _, _, error in
          if let error {
            NSLog("[CloudKit] image sync warning record=\(fileName) error=\(error.localizedDescription)")
          } else {
            NSLog("[CloudKit] image sync uploaded record=\(fileName)")
          }
          group.leave()
        }
        database.add(modify)
      }
    }

    group.notify(queue: .main) {
      NSLog("[CloudKit] image sync finished saveCount=\(imagePaths.count)")
      result(nil)
    }
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

      NSLog("[CloudKit] snapshot received path=\(snapshotURL.path)")
      self.downloadImageRecords(
        database: database,
        imagesDirPath: imagesDirPath,
        snapshotPath: snapshotURL.path,
        result: result
      )
    }
  }

  private func downloadCloudKitSnapshotPayload(result: @escaping FlutterResult) {
    let database = CKContainer.default().privateCloudDatabase
    let snapshotID = CKRecord.ID(recordName: snapshotRecordName)
    database.fetch(withRecordID: snapshotID) { record, error in
      if let ckError = error as? CKError, ckError.code == .unknownItem {
        result(["found": false])
        return
      }
      if let error {
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
      let snapshotURL = tempDir.appendingPathComponent("cloudkit_snapshot_payload.json")
      do {
        if FileManager.default.fileExists(atPath: snapshotURL.path) {
          try FileManager.default.removeItem(at: snapshotURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: snapshotURL)
      } catch {
        result(
          FlutterError(code: "cloudkit_snapshot_copy_failed", message: error.localizedDescription, details: nil)
        )
        return
      }

      result([
        "found": true,
        "snapshotPath": snapshotURL.path,
      ])
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
        FlutterError(code: "cloudkit_image_directory_failed", message: error.localizedDescription, details: nil)
      )
      return
    }

    let imageNames = extractImageNames(snapshotPath: snapshotPath)
    NSLog("[CloudKit] download imageNames=\(imageNames)")
    if let existing = try? fileManager.contentsOfDirectory(
      at: imagesDirURL,
      includingPropertiesForKeys: nil
    ) {
      let remoteNames = Set(imageNames)
      for fileURL in existing {
        guard self.isManagedImageFile(fileURL) else { continue }
        if remoteNames.contains(fileURL.lastPathComponent) { continue }
        try? fileManager.removeItem(at: fileURL)
      }
    }

    if imageNames.isEmpty {
      NSLog("[CloudKit] pull completed with image warnings: no images in snapshot")
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
        NSLog("[CloudKit] image sync failed: \(ckError.localizedDescription)")
        result(
          FlutterError(code: "cloudkit_image_download_failed", message: ckError.localizedDescription, details: nil)
        )
        return
      } else if let error, (error as? CKError) == nil {
        NSLog("[CloudKit] image sync failed: \(error.localizedDescription)")
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
          NSLog("[CloudKit] image copied fileName=\(fileName)")
        } catch {
          NSLog("[CloudKit] image copy skipped fileName=\(fileName) error=\(error.localizedDescription)")
          continue
        }
      }

      if fetchedRecords.count != imageNames.count {
        NSLog("[CloudKit] pull completed with image warnings fetchedCount=\(fetchedRecords.count) requestedCount=\(imageNames.count)")
      } else {
        NSLog("[CloudKit] image sync success fetchedCount=\(fetchedRecords.count)")
      }
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

  private func isManagedImageFile(_ url: URL) -> Bool {
    let ext = url.pathExtension.lowercased()
    return imageExtensions.contains(ext)
  }
}
