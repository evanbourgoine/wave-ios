//
//  MiniPlayerView.swift
//  Wave
//
//  Mini player bar that appears at bottom when music is playing
//

import SwiftUI
import Combine

struct MiniPlayerView: View {
    @StateObject private var musicService = MusicKitService.shared
    
    var body: some View {
        if let song = musicService.currentSong {
            HStack(spacing: 12) {
                // Album artwork
                if let artworkURL = song.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                        default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                
                // Song info
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play/Pause button
                Button(action: {
                    if musicService.isPlaying {
                        musicService.pausePlayback()
                    } else {
                        Task {
                            await musicService.resumePlayback()
                        }
                    }
                }) {
                    Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                
                // Skip button
                Button(action: {
                    Task {
                        await musicService.skipToNext()
                    }
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Color(.secondarySystemGroupedBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            )
        }
    }
}

// MARK: - Keyboard Height Publisher (for MainTabView to use)

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

#Preview {
    VStack {
        Spacer()
        MiniPlayerView()
    }
}
