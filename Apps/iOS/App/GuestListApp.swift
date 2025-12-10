import SwiftUI

@main
struct GuestListApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)

                Text("GuestList")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("iOS App")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("Coming Soon")
                    .font(.caption)
                    .padding(.top)
            }
            .navigationTitle("GuestList")
        }
    }
}

#Preview {
    ContentView()
}
