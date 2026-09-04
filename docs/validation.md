# Validation — version 1.0.0

Validated on 4 September 2026 with R 4.4.3 on Windows 11 (x86-64).

- Source package built and installed successfully.
- Windows binary package built successfully.
- `R CMD check --no-manual --no-vignettes`: **0 errors, 0 warnings, 1 note**.
- The note concerns the installed package size (83.9 MB), due to bundled GIS data.
- Installed-package tests passed, including data access, input validation and
  rendering a custom area spanning Veneto and Lombardy.
- Four complete example maps were rendered from the installed package and
  visually reviewed: Veneto, Tuscany, Piedmont and Sicily.

The GitHub Actions workflow runs the package check separately on Linux.
