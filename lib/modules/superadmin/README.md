# Superadmin Module

The Superadmin module powers platform‑level management: onboarding, dashboards, system settings, payments, support, vehicle management, and server status.

## Structure
```
lib/modules/superadmin/
  components/
    admin/                 # admin management tabs & detail screens
    appbars/               # shared app bars
    card/                  # dashboard cards & summaries
    transactions/          # payments + manual payments
    vehicle/               # vehicle screens & widgets
    support/               # support inbox & ticket details
  screens/
    admin/                 # admin list & admin detail screen
    dashboard/             # main dashboard
    home/                  # entry/home shortcuts
    setting/               # superadmin settings shell
```

## Key Screens
- Dashboard: system overview, recent metrics, activity summaries
- Admins: list, detail tabs (Profile, Credit History, Payments, Vehicles, Settings, Activity)
- Vehicles: list, details, telemetry, documents
- Payments: transactions list + manual payment flow
- Support: inbox + ticket details
- Server Status: system health & services

## Data Flow
- Repositories: `lib/core/repositories/superadmin_repository.dart`
- API client: `lib/core/network/api_client.dart`
- Models: `lib/core/models/*`

## UI Notes
- Design system source of truth: `lib/design_system/theme` + `lib/design_system/components`
- Typography/tokens come from centralized `OpenVtsTheme` and `OpenVtsTypography`
- Layout sizes: `AdaptiveUtils`, `AppUtils`
- Loading states: `AppShimmer`

