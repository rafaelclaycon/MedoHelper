import SwiftUI

struct MainView: View {

    enum AppTab: Int {

        case analytics, featureAnalytics, content, authors, reactions, musicGenres, soundRequests, donors, folderResearch, notifications, dynamicBanner
    }

    @State private var tabSelection: AppTab = .analytics

    var body: some View {
        // Sections need the values spelled out as `AppTab.x` to infer the selection type.
        TabView(selection: $tabSelection) {
            TabSection("Estatísticas") {
                Tab("Visão Geral", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.analytics) {
                    AnalyticsView()
                }

                Tab("Por Funcionalidade", systemImage: "chart.bar.doc.horizontal", value: AppTab.featureAnalytics) {
                    FeatureAnalyticsView()
                }

                Tab("Pesquisa de Pastas", systemImage: "folder.badge.questionmark", value: AppTab.folderResearch) {
                    FolderResearchView()
                }
            }

            TabSection("Conteúdo") {
                Tab("Sons e Músicas", systemImage: "speaker.wave.3", value: AppTab.content) {
                    ServerContentCRUDView()
                }

                Tab("Autores", systemImage: "person.2", value: AppTab.authors) {
                    ServerAuthorsCRUDView()
                }

                Tab("Gêneros Musicais", systemImage: "guitars", value: AppTab.musicGenres) {
                    ServerMusicGenreCRUDView()
                }

                Tab("Reações", systemImage: "rectangle.grid.2x2", value: AppTab.reactions) {
                    ReactionsCRUDView()
                }

                Tab("Pedidos", systemImage: "tray.and.arrow.down", value: AppTab.soundRequests) {
                    SoundRequestsView()
                }
            }

            TabSection("Comunicação") {
                Tab("Notificações", systemImage: "bell.badge", value: AppTab.notifications) {
                    NotificationsView()
                }

                Tab("Banner Dinâmico", systemImage: "rectangle.portrait.on.rectangle.portrait", value: AppTab.dynamicBanner) {
                    DynamicBannerView()
                }

                Tab("Doadores", systemImage: "heart", value: AppTab.donors) {
                    DonorsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
