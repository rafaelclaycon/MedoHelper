import SwiftUI

struct MainView: View {

    @State private var testVersionDotColor: Color = .red

    var body: some View {
        TabView {
            TabSection("Sons") {
                Tab("Sons", systemImage: "speaker.wave.3") {
                    ServerSoundsCRUDView()
                }

                Tab("Autores", systemImage: "person.2") {
                    ServerAuthorsCRUDView()
                }

                Tab("Reações", systemImage: "rectangle.grid.2x2") {
                    ReactionsCRUDView()
                }
            }

            TabSection("Músicas") {
                Tab("Músicas", systemImage: "music.quarternote.3") {
                    ServerSongsCRUDView()
                }

                Tab("Gêneros Musicais", systemImage: "guitars") {
                    ServerMusicGenreCRUDView()
                }
            }

            TabSection("Manutenção") {
                Tab("Eventos de Atualização", systemImage: "clock.arrow.2.circlepath") {
                    UpdateEventListView()
                }

                Tab {
                    TestVersionView()
                } label: {
                    HStack {
                        Label("Versão de teste", systemImage: "hammer")
                        Spacer()
                        Circle()
                            .fill(testVersionDotColor)
                            .frame(width: 10, height: 10)
                    }
                }
            }

            TabSection("Análise") {
                Tab("Estatísticas", systemImage: "chart.line.uptrend.xyaxis") {
                    AnalyticsView()
                }
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
