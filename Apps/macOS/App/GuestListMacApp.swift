import SwiftUI

@main
struct GuestListMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text("GuestList")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("macOS App")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Coming Soon")
                .font(.caption)
                .padding(.top)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
