import GuestListShared
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)

                Text("GuestList")
                    .font(.headline)

                Text("Quick Check-In")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("GuestList")
        }
    }
}

#Preview {
    ContentView()
}
