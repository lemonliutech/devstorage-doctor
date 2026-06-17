import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(AppState.self) private var state

    private let mainItems: [SidebarItem] = [
        .overview, .xcodeIOS, .android, .flutter,
        .cocoapods, .node, .harmonyos, .manual
    ]
    private let bottomItems: [SidebarItem] = [.exceptions, .reports, .settings]

    private var exceptionCount: Int {
        state.results.filter { $0.exception != nil }.count
    }

    var body: some View {
        List(selection: $selection) {
            Section("Storage") {
                ForEach(mainItems) { item in
                    Label(item.rawValue, systemImage: item.systemImage)
                        .tag(item)
                }
            }
            Section {
                ForEach(bottomItems) { item in
                    HStack {
                        Label(item.rawValue, systemImage: item.systemImage)
                        if item == .exceptions && exceptionCount > 0 {
                            Spacer()
                            Text("\(exceptionCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange, in: Capsule())
                        }
                    }
                    .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200)
    }
}
