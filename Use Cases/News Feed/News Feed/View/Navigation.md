# Navigation by Interactions (SwiftUI)

A composable, decoupled navigation pattern for SwiftUI apps that keeps **views ignorant of navigation** and **modules independently routable**. Views emit **semantic interactions**, the app root wires those interactions to **module routers**, and navigation state lives centrally.

---

## Table of Contents

1. [Motivation](#motivation)
2. [Core Concepts](#core-concepts)
3. [Architecture Overview](#architecture-overview)
4. [Quick Start](#quick-start)
5. [App Router (Interaction Bus)](#app-router-interaction-bus)
6. [Module Routers](#module-routers)
7. [Environment Injection & View Ergonomics](#environment-injection--view-ergonomics)
8. [Navigation Shell (Tabs + Stacks)](#navigation-shell-tabs--stacks)
9. [Deep Links](#deep-links)
10. [Middlewares](#middlewares)
11. [Testing](#testing)
12. [FAQ](#faq)
13. [Migration Guide](#migration-guide)
14. [Performance & Concurrency Notes](#performance--concurrency-notes)
15. [Appendix: Protocols & Types](#appendix-protocols--types)

---

## Motivation

Typical SwiftUI navigation often couples views to destinations (e.g., `NavigationLink` targeting concrete screens). As apps grow, cross-module flows, feature flags, and deep links create brittle dependencies.

**This pattern:**
- Uses **semantic events** (interactions) emitted by views.
- Centralizes routing in an **AppRouter** that coordinates **Module Routers**.
- Supports **cross-cutting middlewares** (analytics, auth, feature flags) without polluting views.
- Keeps **module boundaries clean**: modules own their interactions, routes, and destinations.

---

## Core Concepts

- **ViewInteraction**: A closed union of semantic events emitted by views (e.g., `.tool(.select(tool))`, `.story(.open(id))`).
- **ViewInteractable**: Protocol the views talk to. Usually the `AppRouter` implements this.
- **ModuleRouter**: Per-module adapter that converts module-specific interactions → routes and routes → destinations.
- **AppRouter**: Interaction bus + navigation state. Resolves interactions across modules, pushes routes into stacks, and renders destinations.
- **Middlewares**: Optional hooks executed before and after routing (analytics, feature flags, auth).

---

## Architecture Overview

```
[View] --(ViewInteraction)--> [AppRouter / Interaction Bus]
                               |  |  
                               |  └--> [Middleware(s)]
                               └----> [ModuleRouterBox]*  (Toolbox, Story, ...)
                                         |       |
                                         |       └--> destination(for: Route) -> AnyView
                                         └--> route(for: Interaction) -> Route?

Navigation State:
- selectedTab: AppTab
- navigationStacks: [AppTab : [AnyHashable]]  // route stacks per tab
```

**Key property:** Views do not import other modules. They only emit `ViewInteraction`.

---

## Quick Start

1. **Define your interactions** in a shared module (or app target):
```swift
enum ViewInteraction: Equatable {
  case tool(ToolInteraction)
  case story(StoryInteraction)
}

protocol ViewInteractable { func send(_ interaction: ViewInteraction) }
```

2. **Implement Module Routers** in each module (Toolbox, Story):
```swift
enum ToolboxRoute: Hashable { case home, toolDetail(ToolboxItem) }
enum ToolInteraction: Equatable { case select(ToolboxItem) }

struct ToolboxRouter {
  func handleInteraction(_ i: ToolInteraction) -> ToolboxRoute? {
    switch i { case .select(let item): return .toolDetail(item) }
  }
  func destination(for route: ToolboxRoute) -> AnyView? {
    switch route {
    case .home: return AnyView(ToolboxHome())
    case .toolDetail(let item): return AnyView(ToolDetailView(item: item))
    }
  }
  func route(from url: URL) -> ToolboxRoute? { /* optional deep link */ nil }
}
```

3. **Wrap routers with type-erased boxes** and create the `AppRouter`:
```swift
let appRouter = AppRouter(
  modules: [
    ToolboxModuleBox(service: toolboxService),
    StoryModuleBox(service: storyService)
  ],
  middlewares: [AnalyticsMiddleware()]
)
```

4. **Inject into the environment at the root** and wire navigation stacks:
```swift
RootView(router: appRouter)
  .viewInteraction(appRouter)
```

5. **Emit interactions from views**:
```swift
ToolRow(tool: tool)
  .onTapSend(.tool(.select(tool)))
```

---

## App Router (Interaction Bus)

Responsibilities:
- Receive `ViewInteraction` from views.
- Optionally run middlewares `beforeSend` / `afterResolve`.
- Ask each module for a route; first non-nil wins.
- Push routes into the appropriate tab stack.
- Resolve destinations for `NavigationStack`.
- Coordinate deep links (ask each module to parse).

Characteristics:
- `@MainActor` and `@Observable` (for SwiftUI updates).
- Stores `selectedTab` and `navigationStacks` per tab.
- Returns a fallback view for unknown routes.

---

## Module Routers

A module owns:
- Its **Route** type (`Hashable`).
- Its **Interaction** type (`Equatable`).
- Mapping from **Interaction → Route** (`handleInteraction`).
- Mapping from **Route → Destination View** (`destination`).
- Optional **Deep Link parser** (`route(from:)`).
- Which **tab** a route belongs to.

... (continue with the rest of README content including Environment, Shell, Deep Links, Middlewares, Testing, FAQ, Migration Guide, Performance, Appendix) ...


---

## Environment Injection & View Ergonomics

Provide the bus to all views via `EnvironmentValues`:

```swift
protocol ViewInteractable { @MainActor func send(_ interaction: ViewInteraction) }

private struct ViewInteractionEnvironmentKey: EnvironmentKey {
  static let defaultValue: ViewInteractable? = nil
}

extension EnvironmentValues {
  var viewInteraction: ViewInteractable? {
    get { self[ViewInteractionEnvironmentKey.self] }
    set { self[ViewInteractionEnvironmentKey.self] = newValue }
  }
}

extension View {
  func viewInteraction(_ i: ViewInteractable?) -> some View { environment(\.viewInteraction, i) }
}
```

Sugar for common gestures:

```swift
extension View {
  func onTapSend(_ interaction: @autoclosure @escaping () -> ViewInteraction) -> some View {
    modifier(SendOnTapModifier(makeInteraction: interaction))
  }
}

private struct SendOnTapModifier: ViewModifier {
  @Environment(\.viewInteraction) private var bus
  let makeInteraction: () -> ViewInteraction
  func body(content: Content) -> some View {
    Button(action: { if let bus { bus.send(makeInteraction()) } }) {
      content.contentShape(Rectangle())
    }.buttonStyle(.plain)
  }
}
```

---

## Navigation Shell (Tabs + Stacks)

Use one `NavigationStack` per tab; store a stack of `AnyHashable` routes.

```swift
struct RootView: View {
  @State private var router: AppRouter
  init(router: AppRouter) { _router = State(initialValue: router) }

  var body: some View {
    TabView(selection: $router.selectedTab) {
      NavigationStack(path: binding(.toolbox)) {
        ToolboxHome()
          .navigationDestination(for: AnyHashable.self) { route in
            router.resolveDestination(for: route)
          }
      }
      .tag(AppTab.toolbox)
      .tabItem { Label("Tools", systemImage: "wrench") }

      NavigationStack(path: binding(.stories)) {
        StoryHome()
          .navigationDestination(for: AnyHashable.self) { route in
            router.resolveDestination(for: route)
          }
      }
      .tag(AppTab.stories)
      .tabItem { Label("Stories", systemImage: "book") }
    }
    .viewInteraction(router)
  }

  private func binding(_ tab: AppTab) -> Binding<[AnyHashable]> {
    Binding(
      get: { router.navigationStacks[tab] ?? [] },
      set: { router.navigationStacks[tab] = $0 }
    )
  }
}
```

---

## Deep Links

Each module can parse URLs into its own `Route`. The `AppRouter` asks modules in order until one returns a route.

```swift
extension ToolboxRouter {
  func route(from url: URL) -> ToolboxRoute? {
    guard url.path == "/tool",
          let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let id = comps.queryItems?.first(where: { $0.name == "id" })?.value.flatMap(UUID.init)
    else { return nil }
    let tool = ToolboxItem(id: id, title: "Deep Link Tool", type: .quiz, featureFlagKey: "", resourceURL: nil, tags: [])
    return .toolDetail(tool)
  }
}
```

---

## Middlewares

Middlewares enable cross-cutting behavior without touching views or module routers.

```swift
@MainActor
protocol InteractionMiddleware {
  func beforeSend(_ interaction: ViewInteraction)
  func afterResolve(_ route: AnyHashable?, for interaction: ViewInteraction)
}

struct AnalyticsMiddleware: InteractionMiddleware {
  func beforeSend(_ interaction: ViewInteraction) {
    // Analytics.logInteraction("\(interaction)")
  }
  func afterResolve(_ route: AnyHashable?, for interaction: ViewInteraction) {
    // if let route { Analytics.screen("\(type(of: route))") }
  }
}
```

---

## Testing

**AppRouter tests:**
- Inject a `FakeBox` that records the last interaction and returns a canned route.
- Assert `selectedTab` changes and `navigationStacks` mutation when calling `send(_:)`.

```swift
final class FakeBox: ModuleRouterBox {
  var lastInteraction: ViewInteraction?
  var nextRoute: AnyHashable?
  func route(for i: ViewInteraction) -> AnyHashable? { lastInteraction = i; return nextRoute }
  func canHandle(route: AnyHashable) -> Bool { true }
  func destination(for route: AnyHashable) -> AnyView? { AnyView(EmptyView()) }
  func route(from url: URL) -> AnyHashable? { nil }
  func tab(for route: AnyHashable) -> AppTab? { .toolbox }
}
```

---

## FAQ

**Q: How do views pop or reset?**  
Emit a semantic interaction like `.tool(.closeDetail)` and let the module router call `AppRouter.pop(...)`.

**Q: Can I present sheets/modals?**  
Yes, add modal routes to your module's `Route` type and handle in `destination(for:)`.

**Q: How do I handle feature flags?**  
Use a middleware to intercept resolved routes.

**Q: Is `AnyView` a performance concern?**  
Minimal; safe at routing boundaries.

**Q: How do I serialize/restore stacks?**  
Switch to `NavigationPath` and make routes Codable.

---

## Migration Guide

1. Replace cross-module `NavigationLink` with `.onTapSend(...)`.
2. Keep intra-module navigation as-is if desired.
3. Introduce routers gradually.
4. Move analytics into middleware.
5. Move deep-link parsing into modules.

---

## Performance & Concurrency Notes

- Mark `AppRouter` and middlewares `@MainActor`.
- Avoid heavy work in routers.
- `AnyView` cost is negligible here.
- For deep stacks, prefer small route payloads.

---

## Appendix: Protocols & Types

See the main README above for `AppTab`, `ViewInteraction`, `ViewInteractable`, `ModuleRouterBox`, `AppRouter` skeleton, and environment helpers.

---

**License:** MIT
