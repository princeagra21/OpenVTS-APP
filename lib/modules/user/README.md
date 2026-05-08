# User Module

End‑user experience module for fleet customers.

## Structure
```
lib/modules/user/
  components/          # user feature components
  screens/             # user screens and flows
```

## Responsibilities
- Personal profile & settings
- Vehicle access and usage
- Notifications and support

## UI Notes
- Design system source of truth: `lib/design_system/theme` + `lib/design_system/components`
- Typography/tokens come from centralized `OpenVtsTheme` and `OpenVtsTypography`
- Shared design utilities: `AdaptiveUtils`, `AppUtils`
- Loading states: `AppShimmer`

