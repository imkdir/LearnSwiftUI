import SwiftUI

struct ScalableButton: View {
    let iconName: String
    let text: String
    let isCompact: Bool
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
            
            if !isCompact {
                Text(text)
                    .fixedSize()
            }
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(isCompact ? .red : .blue)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ScalablePlayground: View {
    
    @State private var spacing: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 30) {
            
            HStack {
                Spacer()
                    .frame(width: spacing)
                
                ViewThatFits(in: .horizontal) {
                    buttonGroup(isCompact: false)
                    buttonGroup(isCompact: true)
                }
            }
            .frame(maxWidth: .infinity)
            
            Text("Adjust Spacing to Trigger Layout")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Slider(value: $spacing, in: 0...200)
                .padding(.horizontal, 40)
        }
        .padding()
    }
    
    private func buttonGroup(isCompact: Bool) -> some View {
        HStack {
            ScalableButton(iconName: "play.fill", text: "Play", isCompact: isCompact)
            ScalableButton(iconName: "pause.fill", text: "Pause", isCompact: isCompact)
            ScalableButton(iconName: "stop.fill", text: "Stop", isCompact: isCompact)
        }
    }
}

#Preview {
    ScalablePlayground()
}
