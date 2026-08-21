import SwiftUI

struct MainView: View {

    enum AppTab: Int {

        case analytics, content, authors, reactions, musicGenres, soundRequests, donors, folderResearch
    }

    @State private var tabSelection: AppTab = .analytics

    var body: some View {
        TabView(selection: $tabSelection) {
            Tab("Estatísticas", systemImage: "chart.line.uptrend.xyaxis", value: .analytics) {
                AnalyticsView()
            }

            Tab("Conteúdo", systemImage: "speaker.wave.3", value: .content) {
                ServerContentCRUDView()
            }

            Tab("Autores", systemImage: "person.2", value: .authors) {
                ServerAuthorsCRUDView()
            }

            Tab("Reações", systemImage: "rectangle.grid.2x2", value: .reactions) {
                ReactionsCRUDView()
            }

            Tab("Gêneros Musicais", systemImage: "guitars", value: .musicGenres) {
                ServerMusicGenreCRUDView()
            }

            Tab("Pedidos", systemImage: "tray.and.arrow.down", value: .soundRequests) {
                SoundRequestsView()
            }

            Tab("Doadores", systemImage: "heart", value: .donors) {
                DonorsView()
            }

            Tab("Pesquisa de Pastas", systemImage: "folder.badge.questionmark", value: .folderResearch) {
                FolderResearchView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
