import SwiftUI

struct MainView: View {
    
    @State private var currentTab = 0
    @State private var testVersionDotColor: Color = .red
    
    var body: some View {
        NavigationView {
            List(selection: $currentTab) {
                Section("SONS") {
                    NavigationLink {
                        ServerSoundsCRUDView()
                    } label: {
                        Label("Sons", systemImage: "speaker.wave.3")
                    }
                    .tag(0)
                    
                    NavigationLink {
                        ServerAuthorsCRUDView()
                    } label: {
                        Label("Autores", systemImage: "person.2")
                    }
                    .tag(1)
                    
                    NavigationLink {
                        ReactionsCRUDView()
                    } label: {
                        Label("Reações", systemImage: "rectangle.grid.2x2")
                    }
                    .tag(2)
                }

                Section("MÚSICAS") {
                    NavigationLink {
                        ServerSongsCRUDView()
                    } label: {
                        Label("Músicas", systemImage: "music.quarternote.3")
                    }
                    .tag(3)

                    NavigationLink {
                        ServerMusicGenreCRUDView()
                    } label: {
                        Label("Gêneros Musicais", systemImage: "guitars")
                    }
                    .tag(4)
                }

                Section("MANUTENÇÃO") {
                    NavigationLink {
                        UpdateEventListView()
                    } label: {
                        Label("Eventos de Atualização", systemImage: "clock.arrow.2.circlepath")
                    }
                    .tag(5)

                    NavigationLink {
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
                    .tag(6)
                }

//                Section("FERRAMENTAS LOCAIS") {
//                    NavigationLink {
//                        CreateAuthorAndSoundView()
//                    } label: {
//                        Label("Criar Autor e Som", systemImage: "plus.circle")
//                    }
//                    .tag(7)
//
//                    NavigationLink {
//                        ParseSoundRankingCSVView()
//                    } label: {
//                        Label("Parsear CSV", systemImage: "text.justify.leading")
//                    }
//                    .tag(8)
//                }
                
                Section("ANÁLISE") {
                    NavigationLink {
                        AnalyticsView()
                    } label: {
                        Label("Estatísticas", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(9)
                }
            }
            .listStyle(.sidebar)
        }
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

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        MainView()
    }
}
