import SwiftUI

struct ActionsBarView: View {
    @Binding var aiModel: String
    var formattedQuery: String
    @Binding var showActionsList: Bool
    var submitPrompt: () -> Void

    @EnvironmentObject private var customActionsStorage: CustomActionsStorage


    var body: some View {
    HStack(spacing: 10) {   
      // Action icon
      Image(systemName: customActionsStorage.selectedAction?.icon ?? "questionmark.circle")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.white)
        .frame(width: 20)

      // Dynamic action text with keyboard shortcut
      HStack(spacing: 4) {
        Text("\(customActionsStorage.selectedAction?.name ?? "Ask") \"\(formattedQuery)\"")
          .font(.system(size: 13))
          .foregroundColor(.white)

        if let shortcutKey = customActionsStorage.selectedAction?.shortcutKey {
          HStack(spacing: 2) {
            Text("⌘+\(shortcutKey.uppercased())")
              .font(.system(size: 12))
              .foregroundColor(.white.opacity(0.7))
              .padding(.horizontal, 4)
              .padding(.vertical, 1)
              .background(Color.white.opacity(0.2))
              .cornerRadius(3)
          }
        }
      }

      Spacer()

      // Show the model name
      Text(aiModel)
        .font(.system(size: 12))
        .foregroundColor(.white)

      // Actions selector button (dropdown indicator)
      Button(action: {
        // showActionsList.toggle()
        // if showActionsList {
        //     if let selectedId = customActionsStorage.selectedActionId {
        //     hoveredActionIndex = customActionsStorage.actions.firstIndex(where: { $0.id.uuidString == selectedId })
        //   }
        // }
      }) {
        Image(systemName: "chevron.down")
          .font(.system(size: 12))
          .foregroundColor(.white)
          .padding(6)
          .background(Color.white.opacity(0.15))
          .cornerRadius(4)
      }
      .buttonStyle(PlainButtonStyle())

      // Run button
      Button(action: {
        submitPrompt()
      }) {
        HStack(spacing: 6) {
          Text("Run")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)

          Image(systemName: "arrow.clockwise")
            .font(.system(size: 12))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.15))
        .cornerRadius(4)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color.blue)
    .cornerRadius(8)
    }
}
