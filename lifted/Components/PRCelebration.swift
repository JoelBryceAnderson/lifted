import SwiftUI

struct PRCelebration: View {
    let exerciseName: String
    let weight: Double
    let reps: Int
    let onDismiss: () -> Void

    @State private var scale = 0.5
    @State private var opacity = 0.0
    @State private var trophyRotation = 0.0
    @State private var confettiOffset: CGFloat = -200
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Confetti
            if showConfetti {
                ConfettiView()
            }

            // Content
            VStack(spacing: 24) {
                // Trophy icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 0)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(trophyRotation))
                }
                .scaleEffect(scale)

                // Text
                VStack(spacing: 12) {
                    Text("NEW PR!")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text(exerciseName)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))

                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("\(weight.weightString)")
                                .font(.title.bold())
                                .foregroundColor(.yellow)
                            Text("lbs")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Text("×")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.5))

                        VStack(spacing: 4) {
                            Text("\(reps)")
                                .font(.title.bold())
                                .foregroundColor(.yellow)
                            Text("reps")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.top, 8)
                }
                .opacity(opacity)

                // Dismiss button
                Button {
                    dismissWithAnimation()
                } label: {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(width: 200)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(16)
                }
                .opacity(opacity)
                .padding(.top, 16)
            }
        }
        .onAppear {
            Haptics.success()
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            opacity = 1.0
        }

        withAnimation(.easeInOut(duration: 0.8).repeatCount(2)) {
            trophyRotation = 10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showConfetti = true
            }
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
    }

    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.yellow, .orange, .red, .green, .blue, .purple, .pink]

        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: i,
                color: colors.randomElement()!,
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -50
                ),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.0),
                delay: Double.random(in: 0...0.5)
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let position: CGPoint
    let rotation: Double
    let scale: CGFloat
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece

    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: 8 * piece.scale, height: 12 * piece.scale)
            .rotationEffect(.degrees(currentRotation))
            .offset(x: piece.position.x + xOffset, y: piece.position.y + yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeIn(duration: 2.5)
                    .delay(piece.delay)
                ) {
                    yOffset = 800
                    xOffset = CGFloat.random(in: -100...100)
                    currentRotation = piece.rotation + Double.random(in: 180...720)
                }

                withAnimation(
                    .easeIn(duration: 0.5)
                    .delay(piece.delay + 2)
                ) {
                    opacity = 0
                }
            }
    }
}

struct PRCelebrationModifier: ViewModifier {
    @Binding var prInfo: PRCelebrationInfo?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let info = prInfo {
                PRCelebration(
                    exerciseName: info.exerciseName,
                    weight: info.weight,
                    reps: info.reps
                ) {
                    prInfo = nil
                }
                .transition(.opacity)
            }
        }
    }
}

struct PRCelebrationInfo: Identifiable, Equatable {
    let id = UUID()
    let exerciseName: String
    let weight: Double
    let reps: Int
}

extension View {
    func prCelebration(info: Binding<PRCelebrationInfo?>) -> some View {
        modifier(PRCelebrationModifier(prInfo: info))
    }
}

#Preview {
    PRCelebration(
        exerciseName: "Bench Press",
        weight: 225,
        reps: 5
    ) {}
}
