import SwiftUI

struct MainView: View {

    enum AppTab: Int {

        case sounds, authors, reactions, songs, musicGenres, updateEvents, testVersion, analytics
    }

    @State private var tabSelection: AppTab = .sounds
    @State private var testVersionDotColor: Color = .red

    var body: some View {
        TabView(selection: $tabSelection) {
            Tab("Sons", systemImage: "speaker.wave.3", value: .sounds) {
                ServerSoundsCRUDView()
            }
            
            Tab("Autores", systemImage: "person.2", value: .authors) {
                ServerAuthorsCRUDView()
            }
            
            Tab("Reações", systemImage: "rectangle.grid.2x2", value: .reactions) {
                ReactionsCRUDView()
            }
            
            Tab("Músicas", systemImage: "music.quarternote.3", value: .songs) {
                ServerSongsCRUDView()
            }
            
            Tab("Gêneros Musicais", systemImage: "guitars", value: .musicGenres) {
                ServerMusicGenreCRUDView()
            }
            
            Tab("Eventos de Atualização", systemImage: "clock.arrow.2.circlepath", value: .updateEvents) {
                UpdateEventListView()
            }
            
            Tab("Versão de teste", systemImage: "hammer", value: .testVersion) {
                TestVersionView()
            }
            /*label: {
                HStack {
                    Label("Versão de teste", systemImage: "hammer")
                    Spacer()
                    Circle()
                        .fill(testVersionDotColor)
                        .frame(width: 10, height: 10)
                }
            }*/
            
            Tab("Estatísticas", systemImage: "chart.line.uptrend.xyaxis", value: .analytics) {
                AnalyticsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onAppear {
            checkTestVersion()
        }
    }
    
    private func checkTestVersion() {
        Task {
            do {
                let url = URL(string: "http://170.187.145.233:8080/api/v2/current-test-version/")!
                
                let statusCode: Int = try await APIClient().getStatusCode(from: url)
                
                if (200...299).contains(statusCode) {
                    self.testVersionDotColor = .green
                } else {
                    self.testVersionDotColor = .red
                }
            } catch {
                print(error)
                self.testVersionDotColor = .red
            }
        }
    }
}
