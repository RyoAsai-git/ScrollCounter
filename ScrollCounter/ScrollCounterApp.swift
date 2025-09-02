import SwiftUI
import CoreData

@main
struct ScrollCounterApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isActive = false
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                SplashView(isActive: $isActive)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                isActive = true
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - CoreData管理クラス
class PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // プレビュー用のサンプルデータを作成
        let currentDate = Date()
        
        let sampleData = ScrollDataEntity(context: viewContext)
        sampleData.date = currentDate
        sampleData.totalDistance = 2500.0
        sampleData.appName = "Twitter"
        sampleData.distance = 1200.0
        sampleData.sessionDistance = 1200.0
        sampleData.timestamp = currentDate
        
        let sampleData2 = ScrollDataEntity(context: viewContext)
        sampleData2.date = currentDate
        sampleData2.totalDistance = 2500.0
        sampleData2.appName = "Instagram"
        sampleData2.distance = 800.0
        sampleData2.sessionDistance = 800.0
        sampleData2.timestamp = currentDate
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("プレビューデータの保存に失敗しました: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ScrollData")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("CoreDataの読み込みに失敗しました: \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
