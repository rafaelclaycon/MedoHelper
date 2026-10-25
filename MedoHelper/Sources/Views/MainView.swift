import SwiftUI

struct MainView: View {

    enum AppTab: Int, CaseIterable, Identifiable {

        case analytics, featureAnalytics, content, authors, reactions, musicGenres, soundRequests, donors, folderResearch, notifications, dynamicBanner

        var id: Self { self }

        var title: String {
            switch self {
            case .analytics: return "Visão Geral"
            case .featureAnalytics: return "Por Funcionalidade"
            case .folderResearch: return "Pesquisa de Pastas"
            case .content: return "Sons e Músicas"
            case .authors: return "Autores"
            case .musicGenres: return "Gêneros Musicais"
            case .reactions: return "Reações"
            case .soundRequests: return "Pedidos"
            case .notifications: return "Notificações"
            case .dynamicBanner: return "Banner Dinâmico"
            case .donors: return "Doadores"
            }
        }

        var systemImage: String {
            switch self {
            case .analytics: return "chart.line.uptrend.xyaxis"
            case .featureAnalytics: return "chart.bar.doc.horizontal"
            case .folderResearch: return "folder.badge.questionmark"
            case .content: return "speaker.wave.3"
            case .authors: return "person.2"
            case .musicGenres: return "guitars"
            case .reactions: return "rectangle.grid.2x2"
            case .soundRequests: return "tray.and.arrow.down"
            case .notifications: return "bell.badge"
            case .dynamicBanner: return "rectangle.portrait.on.rectangle.portrait"
            case .donors: return "heart"
            }
        }
    }

    /// The sidebar headings on Mac and iPad, and the tabs themselves on iPhone.
    enum AppSection: CaseIterable, Identifiable {

        case analytics, content, communication

        var id: Self { self }

        var title: String {
            switch self {
            case .analytics: return "Estatísticas"
            case .content: return "Conteúdo"
            case .communication: return "Comunicação"
            }
        }

        var systemImage: String {
            switch self {
            case .analytics: return "chart.bar.xaxis"
            case .content: return "music.note.list"
            case .communication: return "megaphone"
            }
        }

        /// In display order.
        var tabs: [AppTab] {
            switch self {
            case .analytics: return [.analytics, .featureAnalytics, .folderResearch]
            case .content: return [.content, .authors, .musicGenres, .reactions, .soundRequests]
            case .communication: return [.notifications, .dynamicBanner, .donors]
            }
        }
    }

    @State private var tabSelection: AppTab = .analytics
    @State private var phoneSection: AppSection = .analytics

    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            phoneTabs
        } else {
            sidebarTabs
        }
        #else
        sidebarTabs
        #endif
    }

    /// Every screen is a tab, grouped under the section headings.
    private var sidebarTabs: some View {
        TabView(selection: $tabSelection) {
            ForEach(AppSection.allCases) { section in
                TabSection(section.title) {
                    ForEach(section.tabs) { tab in
                        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                            screen(for: tab)
                        }
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    /// Eleven screens don't fit a tab bar, so on iPhone each section is a tab with a
    /// list of its screens.
    private var phoneTabs: some View {
        TabView(selection: $phoneSection) {
            ForEach(AppSection.allCases) { section in
                Tab(section.title, systemImage: section.systemImage, value: section) {
                    NavigationStack {
                        List(section.tabs) { tab in
                            NavigationLink {
                                screen(for: tab)
                            } label: {
                                Label(tab.title, systemImage: tab.systemImage)
                            }
                        }
                        .navigationTitle(section.title)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .analytics: AnalyticsView()
        case .featureAnalytics: FeatureAnalyticsView()
        case .folderResearch: FolderResearchView()
        case .content: ServerContentCRUDView()
        case .authors: ServerAuthorsCRUDView()
        case .musicGenres: ServerMusicGenreCRUDView()
        case .reactions: ReactionsCRUDView()
        case .soundRequests: SoundRequestsView()
        case .notifications: NotificationsView()
        case .dynamicBanner: DynamicBannerView()
        case .donors: DonorsView()
        }
    }
}
