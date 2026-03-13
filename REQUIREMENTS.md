# Credit Card Tracker — iOS App Requirements

## Objetivo

App iOS para visualizar o dashboard de gastos do cartão de crédito, consumindo uma API REST. Exibe gráfico donut do total gasto vs orçamento, gráfico de barras por categoria e lista paginada de despesas, com navegação por mês.

---

## Stack

- **SwiftUI** + **iOS 26+**
- **Swift Charts** nativo (sem dependências externas)
- **Swift Package Manager** — `Package.swift` como ponto de entrada (abrir no Xcode 16+)
- `@Observable` (Observation framework) para ViewModel
- `URLSession` async/await para networking
- Ícone: `Sources/CreditCardTracker/Resources/Assets.xcassets/AppIcon.appiconset/card-tracker.png` (1024×1024, universal)

### Package.swift

```swift
// swift-tools-version: 5.9
platforms: [.iOS("26.0")]
targets: [
    .executableTarget(
        name: "CreditCardTracker",
        path: "Sources/CreditCardTracker",
        resources: [.process("Resources")]
    )
]
```

---

## API

**Endpoint:** `GET https://cartao-danilo.vercel.app/api/dashboard`

**Auth:** `Authorization: Bearer 63e30757fbcc466867e7caf3bded14ab07d333edfd30a43a9492a0f6ec01682c`

**Query params:** `month=YYYY-MM`, `page=1`, `pageSize=15`

### Resposta JSON

```json
{
  "month": "2026-03",
  "invoiceClosed": false,
  "totalSpentCents": 150000,
  "categories": [
    {
      "id": "uuid",
      "name": "Alimentação",
      "color": "#FF6B6B",
      "symbol": "fork-knife",
      "limitCents": 50000,
      "spentCents": 32000
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 15,
    "totalExpenses": 42,
    "totalPages": 3
  },
  "expenses": [
    {
      "id": "uuid",
      "merchant": { "name": "Supermercado X", "nickname": "Mercado" },
      "amountCents": 4990,
      "installmentCurrent": 2,
      "installmentTotal": 12,
      "category": { "id": "uuid", "name": "Alimentação", "color": "#FF6B6B", "symbol": "fork-knife" },
      "date": "2026-03-10T00:00:00.000Z"
    }
  ]
}
```

**Observações:**
- `limitCents` é nullable (categoria sem orçamento definido)
- `amountCents` pode ser negativo (estorno)
- `installmentCurrent` / `installmentTotal` são nullable (compra à vista)
- `merchant.nickname` tem precedência sobre `merchant.name` para exibição

---

## Estrutura de arquivos

```
credit-card-tracker-ios/
├── Package.swift
└── Sources/CreditCardTracker/
    ├── App/
    │   ├── CreditCardTrackerApp.swift
    │   └── ContentView.swift
    ├── Models/
    │   ├── DashboardResponse.swift
    │   ├── Category.swift
    │   ├── Expense.swift
    │   └── Pagination.swift
    ├── Networking/
    │   ├── APIClient.swift
    │   └── APIError.swift
    ├── ViewModels/
    │   └── DashboardViewModel.swift
    ├── Views/
    │   ├── DashboardView.swift
    │   ├── MonthSelectorView.swift
    │   ├── DonutChartView.swift
    │   ├── CategoryBarChartView.swift
    │   └── ExpensesListView.swift
    ├── Utilities/
    │   ├── CurrencyFormatter.swift
    │   ├── Color+Hex.swift
    │   └── PhosphorToSFSymbol.swift
    └── Resources/
        └── Assets.xcassets/
            └── AppIcon.appiconset/
                ├── Contents.json
                └── card-tracker.png
```

---

## Models

### DashboardResponse
```swift
struct DashboardResponse: Codable {
    let month: String
    let invoiceClosed: Bool
    let totalSpentCents: Int
    let categories: [CategoryData]
    let pagination: PaginationData
    let expenses: [ExpenseData]
}
```

### CategoryData
```swift
struct CategoryData: Codable, Identifiable {
    let id: String
    let name: String
    let color: String   // hex "#RRGGBB"
    let symbol: String  // nome Phosphor, ex: "fork-knife"
    let limitCents: Int?
    let spentCents: Int
}
```

### ExpenseData
```swift
struct MerchantData: Codable {
    let name: String
    let nickname: String?
}

struct ExpenseCategoryData: Codable {
    let id: String; let name: String; let color: String; let symbol: String
}

struct ExpenseData: Codable, Identifiable {
    let id: String
    let merchant: MerchantData
    let amountCents: Int
    let installmentCurrent: Int?
    let installmentTotal: Int?
    let category: ExpenseCategoryData?
    let date: String

    var displayName: String { merchant.nickname ?? merchant.name }
    var isRefund: Bool { amountCents < 0 }
}
```

### PaginationData
```swift
struct PaginationData: Codable {
    let page: Int; let pageSize: Int
    let totalExpenses: Int; let totalPages: Int
    var hasMorePages: Bool { page < totalPages }
}
```

---

## Networking

### APIClient (actor)
- `actor APIClient` com `static let shared`
- `func fetchDashboard(month:page:pageSize:) async throws -> DashboardResponse`
- Monta URL com `URLComponents` + `queryItems`
- Header `Authorization: Bearer <token>`
- Trata erro de rede (`URLSession`), HTTP não-2xx e falha de decode

### APIError
```swift
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlying: Error)
    case networkError(underlying: Error)
}
```

---

## ViewModel

```swift
@Observable class DashboardViewModel {
    var month: String          // "YYYY-MM", inicia no mês atual
    var invoiceClosed: Bool
    var totalSpentCents: Int
    var categories: [CategoryData]
    var expenses: [ExpenseData]
    var pagination: PaginationData?
    var isLoadingDashboard: Bool   // skeleton full-screen
    var isLoadingMore: Bool        // spinner inline
    var errorMessage: String?
    private var currentPage: Int

    // Computed
    var sortedCategories: [CategoryData]  // spentCents > 0, ordem decrescente
    var totalBudgetCents: Int             // soma dos limitCents não-nulos
    var hasMorePages: Bool

    // Funções
    func loadDashboard() async          // reseta page=1, expenses=[], recarrega
    func loadNextPage() async           // append ao array, não substitui
    func navigateToPreviousMonth()      // reseta e recarrega
    func navigateToNextMonth()          // reseta e recarrega
}
```

**Regras importantes:**
- `loadDashboard` reseta `currentPage = 1` e `expenses = []` antes de buscar
- `loadNextPage` faz append em `expenses`; `categories` é sempre substituído pela resposta mais recente
- Navegação de mês reseta estado completo antes de recarregar

---

## Views

### Injection pattern (iOS 17+)
```swift
// ContentView.swift
@State private var viewModel = DashboardViewModel()
NavigationStack { DashboardView() }
    .environment(viewModel)
    .task { await viewModel.loadDashboard() }

// Qualquer view filha
@Environment(DashboardViewModel.self) private var viewModel
```

### DashboardView
- Estados: `isLoadingDashboard` → `SkeletonView`; `errorMessage` → `ErrorView` com botão retry; senão conteúdo
- `ScrollView` com `pull-to-refresh` (`.refreshable`)
- Conteúdo em ordem: badge de status da fatura → `DonutChartView` centralizado → seção "Por categoria" com `CategoryBarChartView` → seção "Despesas" com `ExpensesListView`
- Badge de fatura: "Fatura fechada" (laranja, cadeado fechado) / "Fatura aberta" (verde, cadeado aberto)
- `SkeletonView`: blocos animados com `.easeInOut(duration: 0.9).repeatForever()`

### MonthSelectorView
- Chevron esquerdo → `navigateToPreviousMonth()`
- Chevron direito → `navigateToNextMonth()`
- Label central: "Mar 2026" (locale `pt_BR`, capitalizado), `minWidth: 120`
- Exibido no `.principal` do toolbar da NavigationStack

### DonutChartView
- `SectorMark(angle:, innerRadius: .ratio(0.62), angularInset: 2)`
- **Sem orçamento** (`totalBudgetCents <= 0`): anel azul completo
- **Dentro do orçamento**: setor azul (gasto) + setor cinza (restante)
- **Acima do orçamento**: anel vermelho completo
- Centro: valor gasto em destaque + "de R$ X" se houver orçamento

### CategoryBarChartView
- `BarMark(x: spentCents/100, y: categoryLabel)` → barras horizontais automáticas
- Cor da barra: `Color(hex: category.color)`
- `RuleMark(x: limitCents/100)` tracejado laranja para limite por categoria
- Eixo X: formato curto (`1,2k`)
- Eixo Y: emoji/símbolo SF + nome da categoria (`PhosphorToSFSymbol.map(symbol) + " " + name`)
- Altura obrigatória: `max(200, categories.count * 44)` pts (necessário dentro de ScrollView)

### ExpensesListView
- `LazyVStack` (não `List`) para compatibilidade com `ScrollView` pai
- `Divider` com `.padding(.leading, 56)` entre itens
- Linha de despesa:
  - Ícone circular 36pt com cor da categoria (opacidade 0.15 no fundo)
  - Nome do merchant (nickname ?? name), limitado a 1 linha
  - Valor: verde se estorno (`amountCents < 0`), primário caso contrário
  - Data: "dd MMM" em `pt_BR`
  - Badge de parcela "2/12" se `installmentCurrent != nil`
- Rodapé: `ProgressView` se `isLoadingMore`; botão "Carregar mais" se `hasMorePages`

---

## Utilities

### CurrencyFormatter
```swift
// Formato completo: "R$ 1.234,56"
static func format(cents: Int) -> String

// Formato curto para eixo de gráfico: "1,2k" ou "850"
static func formatShort(value: Double) -> String
```
- `NumberFormatter` com `locale: Locale(identifier: "pt_BR")`, `currencyCode: "BRL"`

### Color(hex:)
```swift
extension Color {
    init?(hex: String)  // aceita "#RRGGBB" ou "RRGGBB"
}
```

### PhosphorToSFSymbol
```swift
enum PhosphorToSFSymbol {
    static func map(_ phosphorSymbol: String) -> String
    // Remove prefixo "phosphor:" se presente
    // Fallback: "tag"
}
```
Mapeamento estático de ~75 ícones Phosphor para SF Symbols. Exemplos:
`"fork-knife"→"fork.knife"`, `"car"→"car"`, `"shopping-cart"→"cart"`, `"heart"→"heart"`, `"credit-card"→"creditcard"`

---

## Correções conhecidas aplicadas

- `Self.currentMonthString()` não é válido como valor padrão de propriedade stored em classe — usar closure `= { ... }()`
- `Color(.systemGray5)` / `Color(.systemGroupedBackground)` são UIKit-backed e falham fora de iOS — substituir por `Color.secondary.opacity(...)` e `Color.primary.opacity(...)`
- `.navigationBarTitleDisplayMode(.inline)` é iOS-only — pode ser omitido sem perda funcional quando o título está no toolbar principal
- Altura explícita no `CategoryBarChartView` é obrigatória ao usar Swift Charts dentro de `ScrollView`
- `@Observable` + `.environment(viewModel)` (não `@EnvironmentObject` / `.environmentObject`)

---

## Como abrir e rodar

1. Abrir `Package.swift` no Xcode 16+
2. Signing & Capabilities → Automatically manage signing → selecionar Team
3. Selecionar simulador ou dispositivo iOS 26+
4. Cmd+R
