import Foundation

enum SyncStatus: Equatable {
    case idle
    case syncing
    case success(Date)
    case failure(String)

    var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }
}
