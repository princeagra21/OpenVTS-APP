# Admin Module

Admin role screens and features for day‑to‑day fleet operations.

## Structure
```
lib/modules/admin/
  components/          # admin widgets and feature components
  screens/             # admin screens and flows
```

## Responsibilities
- Fleet management (vehicles, drivers, users)
- Operational settings
- Activity tracking
- Support workflows

## UI Notes
- Design system source of truth: `lib/design_system/theme` + `lib/design_system/components`
- Typography/tokens come from centralized `OpenVtsTheme` and `OpenVtsTypography`
- Shared design utilities: `AdaptiveUtils`, `AppUtils`
- Loading states: `AppShimmer`

