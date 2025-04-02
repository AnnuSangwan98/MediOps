import SwiftUI

struct SplashScreenAlt: View {
    @State private var isActive = false
    @State private var logoScale = 0.7
    @State private var rotation = -10.0
    @State private var iconOpacity = 0.0
    @State private var textPosition = 100.0
    @State private var textOpacity = 0.0
    @State private var pulsate = false
    @State private var particleOpacity = 0.0
    @State private var heartbeatScale = 1.0
    @State private var showHeartbeat = false
    @State private var glowIntensity = 0.0
    
    // Colors
    let primaryTeal = Color(red: 43/255, green: 182/255, blue: 205/255)
    let darkTeal = Color(red: 23/255, green: 130/255, blue: 160/255)
    let accentOrange = Color(red: 255/255, green: 136/255, blue: 75/255)
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.white.opacity(0.95), Color(white: 0.97)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Particle effects
                ParticlesView(count: 25) // Use slightly more particles than the role selection screen
                    .opacity(particleOpacity)
                
                // Circular glow
                Circle()
                    .fill(primaryTeal.opacity(0.05 + (glowIntensity * 0.1)))
                    .frame(width: 350, height: 350)
                    .blur(radius: 50)
                
                VStack {
                    Spacer()
                    
                    // Main logo with 3D effect
                    ZStack {
                        // Shadow element
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 180, height: 180)
                            .offset(x: 8, y: 8)
                            .blur(radius: 8)
                            .opacity(iconOpacity)
                        
                        // Main icon background
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [primaryTeal, darkTeal]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 180, height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(Color.white, lineWidth: 1)
                                    .blur(radius: 1)
                                    .opacity(0.8)
                            )
                            .shadow(color: primaryTeal.opacity(0.3), radius: 10, x: 0, y: 10)
                            .opacity(iconOpacity)
                        
                        // "M" letter with 3D effect
                        Text("M")
                            .font(.system(size: 100, weight: .bold))
                            .foregroundColor(.white)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.white.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .mask(
                                    Text("M")
                                        .font(.system(size: 100, weight: .bold))
                                )
                            )
                            .shadow(color: darkTeal.opacity(0.5), radius: 1, x: 1, y: 2)
                            .opacity(iconOpacity)
                        
                        // Medical cross element
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [accentOrange, accentOrange.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                                .scaleEffect(pulsate ? 1.1 : 1.0)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .opacity(iconOpacity)
                        .offset(x: 70, y: 70)
                        
                    }
                    .scaleEffect(logoScale)
                    .rotationEffect(.degrees(rotation))
                    .padding(.bottom, 60)
                    
                    // App name with gradient
                    Text("MediOps")
                        .font(.system(size: 42, weight: .heavy))
                        .tracking(2)
                        .opacity(textOpacity)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [darkTeal, primaryTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 1, y: 2)
                        .offset(y: textPosition)
                    
                    // Tagline
                    Text("Seamless Care, Smarter Management")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(darkTeal.opacity(0.8))
                        .padding(.top, 5)
                        .opacity(textOpacity * 0.8)
                        .offset(y: textPosition)
                    
                    Spacer()
                    Spacer()
                    
                    // Animated heartbeat instead of dots
                    HeartbeatLineView(color: primaryTeal)
                        .frame(width: 120, height: 30)
                        .padding(.bottom, 40)
                        .padding(.horizontal, 50)
                        .opacity(textOpacity)
                        .scaleEffect(pulsate ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulsate)
                }
                .padding(.bottom, 50)
                .onAppear {
                    startAnimations()
                }
            }
        }
    }
    
    func startAnimations() {
        // Initial glow animation
        withAnimation(.easeIn(duration: 1.0)) {
            glowIntensity = 1.0
            particleOpacity = 1.0
        }
        
        // Logo entrance animation
        withAnimation(
            Animation.spring(response: 0.8, dampingFraction: 0.6)
                .delay(0.3)
        ) {
            logoScale = 1.0
            rotation = 0
            iconOpacity = 1.0
        }
        
        // Start pulse animation for medical cross
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulsate = true
            }
        }
        
        // Text animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                textPosition = 0
                textOpacity = 1.0
            }
        }
        
        // Show heartbeat animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showHeartbeat = true
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                heartbeatScale = 1.05
            }
        }
        
        // Transition to main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                self.isActive = true
            }
        }
    }
}

// Heartbeat line animation
struct HeartbeatLineView: View {
    var color: Color
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: 20, y: 10))
            path.addLine(to: CGPoint(x: 35, y: 0))
            path.addLine(to: CGPoint(x: 50, y: 20))
            path.addLine(to: CGPoint(x: 65, y: 10))
            path.addLine(to: CGPoint(x: 120, y: 10))
        }
        .trim(from: 0, to: animationProgress)
        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .onAppear {
            withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                animationProgress = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenAlt()
} 
