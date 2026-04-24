# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

iOS app (SwiftUI) that displays a credit card expense dashboard, consuming a REST API. Built with Xcode 16+ targeting iOS 26+.

## How to build and run

Open `CreditCardTracker.xcodeproj` in Xcode 16+. No package dependencies — only native frameworks (SwiftUI, Swift Charts, Observation). Select an iOS 26+ simulator and press `Cmd+R`.

There is no CLI build or test setup. All development happens in Xcode.

## Architecture

**Data flow:** `APIClient` (actor) → `DashboardViewModel` (@Observable) → Views via `.environment(viewModel)`

**ViewModel injection pattern:** `ContentView` owns `@State private var viewModel = DashboardViewModel()`, passes it via `.environment(viewModel)`, and child views read it with `@Environment(DashboardViewModel.self)`.

**Pagination:** `loadDashboard()` always resets `currentPage = 1` and `expenses = []`. `loadNextPage()` appends to `expenses`; `categories` is always replaced by the latest response. Month navigation resets full state.

## API

- Endpoint: `GET https://cartao-danilo.vercel.app/cartao/api/dashboard`
- Auth: `Authorization: Bearer <token>` (token hardcoded in `APIClient.swift`)
- Query params: `month=YYYY-MM`, `page`, `pageSize`
- `amountCents` can be negative (refund). `limitCents` is nullable. `installmentCurrent/Total` are nullable (one-time purchase).
- Display name: `merchant.nickname ?? merchant.name`

## Key implementation notes

- All UI strings are in Portuguese (pt_BR). New UI text should follow the same language.
- `Color(.systemGray5)` / `Color(.systemGroupedBackground)` are UIKit-backed — use `Color.secondary.opacity(...)` instead.
- `CategoryBarChartView` requires an explicit `.frame(height:)` when inside a `ScrollView` — use `max(200, categories.count * 44)`.
- `PhosphorToSFSymbol.map(_:)` converts Phosphor icon names (e.g. `"fork-knife"`) to SF Symbols (e.g. `"fork.knife"`), with `"tag"` as fallback.
- `CurrencyFormatter.formatShort(value:)` produces axis labels like `"1,2k"` using pt_BR locale.
- `Color(hex:)` extension (in `Color+Hex.swift`) initializes a `Color` from a `"#RRGGBB"` string — used for API-supplied category/expense colors.
- `ExpenseData.date` maps to the JSON key `expenseDate` via `CodingKeys`.
