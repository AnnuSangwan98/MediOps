import SwiftUI

// Particle effect system
struct ParticlesView: View {
    let particleCount: Int
    
    init(count: Int = 20) {
        self.particleCount = count
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                ParticleView(index: index)
            }
        }
    }
}

struct ParticleView: View {
    let index: Int
    
    @State private var position = CGPoint.zero
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                Color(
                    red: Double.random(in: 0.3...0.6),
                    green: Double.random(in: 0.7...0.9),
                    blue: Double.random(in: 0.8...1.0)
                ).opacity(0.5)
            )
            .frame(width: randomSize, height: randomSize)
            .position(position)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // Random initial delay
                let delay = Double.random(in: 0...1.5)
                
                // Random position
                position = randomPosition
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // Animate particles
                    withAnimation(Animation.easeInOut(duration: Double.random(in: 2...5)).repeatForever(autoreverses: true)) {
                        position = randomPosition
                        scale = CGFloat.random(in: 0.7...1.3)
                        opacity = Double.random(in: 0.3...0.6)
                    }
                }
                
                // Initial animation
                withAnimation(.easeIn(duration: 1.0).delay(delay)) {
                    scale = CGFloat.random(in: 0.5...1.0)
                    opacity = Double.random(in: 0.3...0.6)
                }
            }
    }
    
    var randomSize: CGFloat {
        CGFloat.random(in: 3...8)
    }
    
    var randomPosition: CGPoint {
        CGPoint(
            x: CGFloat.random(in: 50...350),
            y: CGFloat.random(in: 50...750)
        )
    }
} 